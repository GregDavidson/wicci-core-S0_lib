-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('pgxml.sql', '$Id');

--	Wicci Project
--	Utility Functions based on pgxml contrib package

-- ** Copyright

--	Copyright (c) 2005, 2006, J. Greg Davidson.
--	You may use this file under the terms of the
--	GNU AFFERO GENERAL PUBLIC LICENSE 3.0
--	as specified in the file LICENSE.md included with this distribution.
--	All other use requires my permission in writing.

--Dependencies: array.sql 

-- ** Provides

-- ** Requires

-- * xml verification and pacification functions

-- ~~ is_xml_space(text) -> BOOLEAN
CREATE OR REPLACE
FUNCTION is_xml_space(text) RETURNS BOOLEAN AS $$
	SELECT $1 ~ '^[[:space:]]*$'
$$ LANGUAGE SQL;

-- ~~ is_xml_name(text) -> BOOLEAN
CREATE OR REPLACE
FUNCTION is_xml_name(text) RETURNS BOOLEAN AS $$
	SELECT $1 ~ '^[A-Za-z_:][a-zA-Z0-9_.:-]*$'
$$ LANGUAGE SQL;

-- ~~ xml_name(text) -> text
CREATE OR REPLACE
FUNCTION xml_name(text) RETURNS text AS $$
	SELECT CASE WHEN is_xml_name($1) THEN $1 ELSE NULL END
-- strip leading and trailing whitespace ?
$$ LANGUAGE SQL;

-- ~~ is_xml_whitespace(text) -> BOOLEAN
CREATE OR REPLACE
FUNCTION is_xml_whitespace(text) RETURNS BOOLEAN AS $$
	SELECT $1 ~ E'^\\s*$';		--add xml &; whitespace elements later???
$$ LANGUAGE SQL;

-- ~~ xml_whitespace(text) -> text | NULL
CREATE OR REPLACE
FUNCTION xml_whitespace(text) RETURNS text AS $$
	SELECT CASE WHEN is_xml_whitespace($1) THEN $1 ELSE NULL END
		--add xml &; whitespace elements later???
$$ LANGUAGE SQL;

-- tags to allow in xml_text:
-- em, quote, span, tt
-- but only with attributes we approve of!

-- tags to translate/normalize in xml_text:
--	tag  	replacement
--	b	em class="bold"
--	i	em class="italic"
--	nbsp	space
--	big	<span class="big">
--	small	<span class="small">

-- All other tags should be turned into character
-- attributes.

-- Probably the best way to do all of this is with XSLT

CREATE OR REPLACE
FUNCTION is_xml_tagged(text) RETURNS boolean AS $$
	 SELECT $1 ~ E'^<\w+.*>.*</\w+>\s*$'
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION is_xml_text(text) RETURNS boolean AS $$
	SELECT xml_is_well_formed('<span>' || $1 || '</span>')
--	SELECT xml_valid($1)		-- pre-PostgreSQL 8.2
-- check for non-textflow characters and tags !!!
$$ LANGUAGE sql;

-- ~~ xml_text(text) -> text | NULL
CREATE OR REPLACE
FUNCTION xml_text(text) RETURNS text AS $$
	SELECT CASE WHEN is_xml_text($1) THEN $1 ELSE NULL END
-- translate non-textflow characters and tags to &; elements !!!
$$ LANGUAGE SQL;

-- ~~ xml_value(text) -> text | NULL
-- character  	replacement
--	& 	&amp;
--	< 	&lt;
--	> 	&gt;
--	" 	&#34;
--	] 	&#93;
-- and to make my life with PostgreSQL easier:
--	' 	&apos;

-- To make it idempotent, I'm NOT translating & characters;
-- sometime in the future we can try to find &s which are not
-- character entities and replace only them.

-- ~~ is_xml_value(text) -> BOOLEAN
CREATE OR REPLACE
FUNCTION is_xml_value(text) RETURNS BOOLEAN AS $$
	SELECT $1 ~ '^[^]<>"'']*$'  -- is this complete?
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION xml_to_value(text) RETURNS text AS $$
	SELECT CASE WHEN is_xml_value($1) THEN $1 ELSE NULL END
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION xml_value(text) RETURNS text AS $$
	SELECT xml_to_value(
		regexp_replace(
			regexp_replace(
				regexp_replace(
					regexp_replace(
						regexp_replace($1, '<', '&lt;', 'g'),
						'>', '&gt;', 'g'),
					'"', '&#34;', 'g'),
				']', '&#93;', 'g'),
			'''', '&apos;', 'g')
	)
$$ LANGUAGE SQL;


-- * xml parsing functions

CREATE OR REPLACE
FUNCTION xml_get_head_tag(text) RETURNS text AS $$
	SELECT xpath_string($1, 'name(/*)')
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION xml_get_body(text) RETURNS text AS $$
	SELECT xpath_string($1, '/*')
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION xml_get_attr_count(text) RETURNS integer AS $$
	SELECT xpath_number($1, 'count(/*/@*)')::integer
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION xml_nodeset_array_trim(text[]) RETURNS text[] AS $$
	SELECT $1[2:(array_length($1)-1)]
$$ LANGUAGE sql;

-- xml_nodeset_array(xml text, path text) -> text[]
-- Kludge: xml tag x must not occur in xml text!!!
CREATE OR REPLACE
FUNCTION xml_nodeset_array(text, text) RETURNS text[] AS $$
	SELECT xml_nodeset_array_trim(string_to_array('</x>' || xpath_nodeset($1, $2, 'x') || '<x>', '</x><x>'))
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION xml_get_child_array(text) RETURNS text[] AS $$
	SELECT xml_nodeset_array($1, '/*/*')
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION xml_get_attr_array(text) RETURNS text[] AS $$
	SELECT xml_nodeset_array($1, '/*/@*')
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION xml_attr_get_name(text) RETURNS text AS $$
	SELECT regexp_replace($1, E'^\\s*(\\w*)="[^"]*"\\s*$', E'\\1')
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION xml_attr_get_value(text) RETURNS text AS $$
	SELECT regexp_replace($1, E'^\\s*\\w*="([^"]*)"\\s*$', E'\\1')
$$ LANGUAGE sql;

CREATE TYPE xml_attr_val_pairs AS (attr TEXT, val TEXT);

CREATE TYPE xml_chiln_or_body AS (parent boolean, chiln text[], body text);

CREATE OR REPLACE
FUNCTION xml_attr_array_to_set(text[])
RETURNS SETOF xml_attr_val_pairs AS $$
	SELECT xml_attr_get_name(attr_val), xml_attr_get_value(attr_val)
	FROM unnest($1) attr_val
$$ LANGUAGE sql;

-- xml_help_get_chiln_or_body(xml, is_parent, maybe_chiln) -> xml_chiln_or_body
-- Given: xml text string, is_parent boolean flag, array of children if is_parent is true
-- Return: xml_chiln_or_body record
CREATE OR REPLACE
FUNCTION xml_help_get_chiln_or_body(text, is_parent boolean, maybe_chiln text[])
RETURNS xml_chiln_or_body AS $$
	SELECT $2, CASE WHEN $2 THEN $3 ELSE NULL END,
	CASE WHEN $2 THEN NULL ELSE xml_get_body($1) END
$$ LANGUAGE sql;

-- xml_get_chiln_or_body(xml, maybe_chiln) -> xml_chiln_or_body
-- Given: xml text string, array of children if xml string has any children
-- Return: xml_chiln_or_body record
CREATE OR REPLACE
FUNCTION xml_get_chiln_or_body(text, maybe_chiln text[])
RETURNS xml_chiln_or_body AS $$
	SELECT xml_help_get_chiln_or_body($1, NOT array_is_empty($2), $2)
$$ LANGUAGE sql;

CREATE TYPE xml_parse_t AS (tag text, attrs text[], parent boolean, chiln text[], body text);

CREATE OR REPLACE
FUNCTION xml_get_head_tag(text) RETURNS text AS $$
	SELECT xpath_string($1, 'name(/*)')
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION xml_parse(text) RETURNS xml_parse_t AS $$
	SELECT xml_get_head_tag($1),
	xml_get_attr_array($1),
	c_or_b.parent, c_or_b.chiln, c_or_b.body
	FROM xml_get_chiln_or_body($1, xml_get_child_array($1)) c_or_b;
$$ LANGUAGE sql;
