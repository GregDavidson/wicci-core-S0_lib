-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('xml-code.sql', '$Id');

--    (setq outline-regexp "^--[ \t]+[*+-~=]+ ")
--    (outline-minor-mode)

--	Wicci Project Utilities XML Code

-- ** Copyright

--	Copyright (c) 2005, 2006, J. Greg Davidson.
--	You may use this file under the terms of the
--	GNU AFFERO GENERAL PUBLIC LICENSE 3.0
--	as specified in the file LICENSE.md included with this distribution.
--	All other use requires my permission in writing.

--Dependencies: array.sql 

-- ** Requires (from utilities-schema.sql):

-- ** Provides

-- ** Notes

-- This API can be improved with some use of STRICT and VARIADIC!!

-- * XML text construction functions

CREATE OR REPLACE
FUNCTION try_xml_indent(integer)  RETURNS text AS $$
	SELECT repeat(E'\t', $1) WHERE $1 >= 0
$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE
FUNCTION xml_indent(integer) RETURNS text AS $$
	SELECT non_null( try_xml_indent($1), 'xml_indent(integer)' )
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION xml_indent(integer) IS
'returns XML whitespace indentation for given level';

CREATE OR REPLACE
FUNCTION xml_nl(integer = 0) RETURNS text AS $$
	SELECT xml_indent($1) || E'\n'
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION xml_nl(integer) IS
'returns XML newline and indent to given level';

CREATE OR REPLACE
FUNCTION xml_nl(text) RETURNS text AS $$
	SELECT debug_assert('xml_nl(text)', is_xml_space($1), $1);
	SELECT COALESCE($1, xml_nl())
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION xml_nl(text) IS
'ensures and returns specified text is suitable for padding XML code;
DEPRECATED!!';

CREATE OR REPLACE
FUNCTION xml_literal_text(text, text) RETURNS text AS $$
	SELECT $1 || xml_nl($2)
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION xml_literal_text(text, text) IS
'returns given xml text padded with given padding;
DEPRECATED!!';

CREATE OR REPLACE
FUNCTION xml_literal_text(text[], text) RETURNS text AS $$
	SELECT array_to_string($1, nl) || nl FROM xml_nl($2) nl
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION xml_literal_text(text[], text) IS
'returns given xml text joined with and padded with given padding;
DEPRECATED!!';

CREATE OR REPLACE
FUNCTION xml_literal_text(text, integer = 0) RETURNS text AS $$
	SELECT $1 || xml_nl($2)
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION xml_literal_text(text, text) IS
'returns given xml text padded with newline and indent to given level;';

CREATE OR REPLACE
FUNCTION xml_literal_text(text[], integer = 0) RETURNS text AS $$
	SELECT array_to_string($1, nl) || nl FROM xml_nl($2) nl
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION xml_literal_text(text[], integer) IS
'returns given xml text joined & padded with newline & indent to given level;';

CREATE OR REPLACE
FUNCTION xml_pure_text(text, text) RETURNS text AS $$
	SELECT xml_literal_text(xml_encode_special_chars($1), $2)
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION xml_pure_text(text, text) IS
'returns given text converted to xml text and padded with
newline & indent to given level;
DEPRECATED!!';

-- ** xml_pure_text(text[], nl text) -> xml text
CREATE OR REPLACE
FUNCTION xml_pure_text(text[], text) RETURNS text AS $$
	SELECT xml_encode_special_chars(xml_literal_text($1, $2))
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION xml_pure_text(text[], text) IS
'returns given text converted to xml text and joined & padded with
newline & indent to given level;
DEPRECATED!!';

CREATE OR REPLACE
FUNCTION xml_pure_text(text, integer=0) RETURNS text AS $$
	SELECT xml_literal_text(xml_encode_special_chars($1), $2)
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION xml_pure_text(text, integer) IS
'returns given text converted to xml text and padded with
newline & indent to given level;';

-- ** xml_pure_text(text[], nl text) -> xml text
CREATE OR REPLACE
FUNCTION xml_pure_text(text[], integer = 0) RETURNS text AS $$
	SELECT xml_encode_special_chars(xml_literal_text($1, $2))
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION xml_pure_text(text[], text) IS
'returns given text converted to xml text and joined & padded with
newline & indent to given level;';

-- ++ xml_query_pair(text, text) -> var=val
CREATE OR REPLACE
FUNCTION xml_query_pair(text, text) RETURNS text AS $$
-- assert valid values ???
	SELECT $1 || '=' || $2
$$ LANGUAGE SQL;

-- ++ xml_queries_text(text[]) -> ?var=val&var=val&...
CREATE OR REPLACE
FUNCTION xml_query_text(text[]) RETURNS text AS $$
	SELECT COALESCE( '?' || array_to_string(
		ARRAY(
			SELECT xml_query_pair($1[i], $1[i+1])
			FROM array_indices($1, 2) i
		),
		'&'
	), '' )
	WHERE debug_assert(
		'xml_query_text(text[])', array_length($1) % 2 = 0, true
	)
$$ LANGUAGE SQL;

-- ++ xml_query_text(text, text) -> ?var=val
CREATE OR REPLACE
FUNCTION xml_query_text(text, text) RETURNS text AS $$
	SELECT xml_query_text( ARRAY[$1, $2] )
$$ LANGUAGE SQL;

-- ++ xml_unsafe_attr(text, text) ->  attr= text
CREATE OR REPLACE
FUNCTION xml_unsafe_qname(_tag text, _name text) RETURNS text AS $$
	SELECT COALESCE( NULLIF($1, '') || ':', '' ) || $2
$$ LANGUAGE SQL;

COMMENT ON FUNCTION xml_unsafe_qname(text, text)
IS 'CAVEATS:
	Does not check that $1 is a valid tag name!!
	Does not check that $2 is a valid xml name!!
';

-- ++ xml_unsafe_attr(text, text) ->  attr= text
CREATE OR REPLACE
FUNCTION xml_unsafe_attr(text, text) RETURNS text AS $$
	SELECT debug_return(this, ' ' || CASE
		WHEN $2 IS NULL THEN $1
		WHEN $1 IS NULL THEN $2
		WHEN $1 = '' THEN $2
		ELSE $1 || '="' || replace($2, '"', '&quot;') || '"'
	END ) FROM debug_enter(
		'xml_unsafe_attr(text, text)', $1, $2
	) this;
$$ LANGUAGE SQL;

COMMENT ON FUNCTION xml_unsafe_attr(text, text)
IS 'CAVEATS:
	Does not check that $1 is a valid attribute name!!
	Does not check that $2 is a valid attribute value!!
	Does not check special cases give valid attributes!!
';

-- ++ is_likely_xml_attr(text) ->  boolean
CREATE OR REPLACE
FUNCTION is_likely_xml_attr(text) RETURNS boolean AS $$
	SELECT $1 ~ '^ [[:alnum:]:]*=".*"$'
$$ LANGUAGE SQL;

-- ++ xml_safe_attr(text, text) ->  attr= text
CREATE OR REPLACE
FUNCTION xml_safe_attr(text, text) RETURNS text AS $$
	SELECT xml_unsafe_attr( $1, xml_encode_special_chars($2) )
$$ LANGUAGE SQL;

-- ** xml_unsafe_attr_list(attrs text[]) -> attr_list text
CREATE OR REPLACE
FUNCTION xml_unsafe_attr_list(text[]) RETURNS text AS $$
DECLARE
	i INTEGER := array_lower($1, 1);
	i_max INTEGER := array_upper($1, 1);
	attr_list text := '';
BEGIN
	IF i IS NULL
		THEN RETURN '';
	END IF;
	LOOP
		IF i = i_max + 1 THEN
			RETURN attr_list;
		ELSEIF i <= i_max AND is_likely_xml_attr($1[i]) THEN
			attr_list := attr_list || $1[i];
			i = i + 1;
		ELSEIF i < i_max AND is_xml_name($1[i]) THEN
			attr_list := attr_list || xml_unsafe_attr($1[i], $1[i+1]);
			i = i + 2;
		ELSE
			RAISE EXCEPTION 'xml_unsafe_attr_list(%) impossible element %!', $1, i;
		END IF;
	END LOOP;
END
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION xml_unsafe_attr_list(text[]) IS '
Ancient crufty code - revisit uses and implementation!!';

-- ** xml_open(tag text) -> text
CREATE OR REPLACE
FUNCTION xml_open(text) RETURNS text AS $$
	SELECT '<' || $1
	WHERE debug_assert('xml_open(text)', is_xml_name($1), true, $1)
$$ LANGUAGE SQL IMMUTABLE;

-- ** xml_close(tag text,  nl text) -> text
CREATE OR REPLACE
FUNCTION xml_close(text, text, no_close boolean = false)
RETURNS text AS $$
--  SELECT debug_assert('xml_close(text, text)'::regprocedure, is_xml_name($1), $1);
	SELECT CASE WHEN $3 THEN '' ELSE '</' || $1 || '>'
	END || xml_nl($2)
$$ LANGUAGE SQL IMMUTABLE;

-- ** xml_close(nl text) -> text
CREATE OR REPLACE
FUNCTION xml_close(text, no_close boolean = false)
RETURNS text AS $$
	SELECT CASE WHEN $2 THEN '>' ELSE ' />'
	END || xml_nl($1)
$$ LANGUAGE SQL IMMUTABLE;

-- ** xml_tag_attrs(tag text, attrs text, nl text) -> element text
CREATE OR REPLACE FUNCTION xml_tag_attrs(
	text, text, text, no_close boolean = false
) RETURNS text AS $$
	SELECT xml_open($1) || COALESCE($2,'') || xml_close($3,$4)
$$ LANGUAGE SQL IMMUTABLE;

-- ** xml_tag_attrs(tag text, attrs text[], nl text) -> element text
CREATE OR REPLACE FUNCTION xml_tag_attrs(
	text, text[], text, no_close boolean = false
) RETURNS text AS $$
	SELECT xml_tag_attrs($1, xml_unsafe_attr_list($2), $3, $4)
$$ LANGUAGE SQL IMMUTABLE;

-- ** xml_tag_attrs_body(tag text, attrs text, body text, nl text) -> element text
CREATE OR REPLACE FUNCTION xml_tag_attrs_body(
	text, text, text, text, no_close boolean = false
) RETURNS text AS $$
	SELECT xml_open($1) || COALESCE($2, '') || '>' || xml_nl($4)
		|| COALESCE($3, '') || xml_close($1, $4, $5)
$$ LANGUAGE SQL IMMUTABLE;

-- ** xml_tag_attrs_body(tag text, attrs text[], body text, nl text) -> element text
CREATE OR REPLACE FUNCTION xml_tag_attrs_body(
	text, text[], text, text, no_close boolean = false
) RETURNS text AS $$
	SELECT xml_tag_attrs_body($1, xml_unsafe_attr_list($2), $3, $4, $5)
$$ LANGUAGE SQL IMMUTABLE;

-- ** xml_tag_attrs_body(tag text, attrs text, body text[], nl text) -> element text
CREATE OR REPLACE FUNCTION xml_tag_attrs_body(
	text, text, text[], text, no_close boolean = false
) RETURNS text AS $$
	SELECT xml_tag_attrs_body(
		$1, $2, array_to_string($3, ''), $4, $5
	)
$$ LANGUAGE SQL IMMUTABLE;

-- ** xml_tag_attrs_body(tag text, attrs text[], body text[], nl text) -> element text
CREATE OR REPLACE FUNCTION xml_tag_attrs_body(
	text, text[], text[], text, no_close boolean = false
) RETURNS text AS $$
	SELECT xml_tag_attrs_body(
		$1, xml_unsafe_attr_list($2), array_to_string($3, ''), $4, $5
	)
$$ LANGUAGE SQL IMMUTABLE;

-- ** xml_tag_body(tag text, body text, nl text) -> element text
CREATE OR REPLACE FUNCTION xml_tag_body(
	text, text, text, no_close boolean = false
) RETURNS text AS $$
	SELECT xml_tag_attrs_body($1, NULL::text, $2, $3, $4)
$$ LANGUAGE SQL IMMUTABLE;

-- ** xml_tag_body(tag text, body text[], nl text) -> element text
CREATE OR REPLACE FUNCTION xml_tag_body(
	text, text[], text, no_close boolean = false
) RETURNS text AS $$
	SELECT xml_tag_attrs_body($1, NULL::text, $2, $3, $4)
$$ LANGUAGE SQL IMMUTABLE;

-- ** xml_tag_body(tag text, body text) -> element text
CREATE OR REPLACE FUNCTION xml_tag_body(
	text, text, no_close boolean = false
) RETURNS text AS $$
	SELECT xml_tag_body($1, $2, NULL::text, $3)
$$ LANGUAGE SQL IMMUTABLE;

-- ** xml_tag_body(tag text, body text[]) -> element text
CREATE OR REPLACE FUNCTION xml_tag_body(
	text, text[], no_close boolean = false
) RETURNS text AS $$
	SELECT xml_tag_body($1, $2, NULL::text, $3)
$$ LANGUAGE SQL IMMUTABLE;
