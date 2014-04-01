-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('html.sql', '$Id');

--    (setq outline-regexp "^--[ \t]+[*+-~=]+ ")
--    (outline-minor-mode)

--	Wicci Project Utilities HTML Text Generation
--	especially widget rendering code

-- ** Copyright

--	Copyright (c) 2005, 2006, J. Greg Davidson.
--	You may use this file under the terms of the
--	GNU AFFERO GENERAL PUBLIC LICENSE 3.0
--	as specified in the file LICENSE.md included with this distribution.
--	All other use requires my permission in writing.

--Dependencies: array.sql 

-- ** Requires (from utilities-schema.sql):

-- ** Provides


-- + html_element(nl, tag, class, id, more_attrs, body)
CREATE OR REPLACE
FUNCTION html_element(TEXT, TEXT, TEXT, TEXT, TEXT[], ANYELEMENT)
RETURNS text AS $$
	SELECT xml_tag_attrs_body(
		$2,
		ARRAY['class', COALESCE($3, ''), 'id', COALESCE($4, '') ] || $5,
		$6::TEXT, $1
	)
$$ LANGUAGE SQL;
SELECT provide_procedure(
'html_element(TEXT, TEXT, TEXT, TEXT, TEXT[], ANYELEMENT)');

-- + html_elements(nl, tag, class, list)
CREATE OR REPLACE
FUNCTION html_elements(TEXT, TEXT, TEXT, ANYARRAY)
RETURNS text AS $$
	SELECT array_to_string( array_or_empty( ARRAY (
		SELECT html_element($1, $2, $3, NULL, NULL, body)
		FROM unnest($4) body
	) ), '' )
$$ LANGUAGE SQL;
SELECT provide_procedure(
'html_elements(TEXT, TEXT, TEXT, ANYARRAY)');

-- + html_button(nl, class, id, href, title, body)
CREATE OR REPLACE
FUNCTION html_button(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) RETURNS text AS $$
	SELECT html_element(
	 $1, 'a', $2, $3,
	 '{}'::TEXT[]
		 || xml_unsafe_attr('href', $4)
		 || xml_unsafe_attr('title', $5),
	 $6
	) FROM
	debug_enter(
		'html_button(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT)',
		$1, $2, $3, $4, $5, $6
	) this
$$ LANGUAGE sql;
SELECT provide_procedure(
'html_button(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT)');

-- + html_img_button(nl, class, id, href, title, src, alt)
CREATE OR REPLACE
FUNCTION html_img_button(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT)
RETURNS text AS $$
	SELECT html_button(
		$1, $2, $3, $4, $5,
		xml_tag_attrs(
			'img',
			xml_unsafe_attr('src', $6) || xml_unsafe_attr('alt', $7),
			$1
		)
	)
$$ LANGUAGE sql;

-- + html_ol(nl, class, id, more_attrs, items)
-- could check that items are appropriate children for an ol
CREATE OR REPLACE
FUNCTION html_ol(TEXT, TEXT, TEXT, TEXT[], TEXT[]) RETURNS text AS $$
	SELECT html_element( $1, 'ol', $2, $3, $4, array_to_string($5, '') )
$$ LANGUAGE sql;

-- + html_ol(nl, class, id, more_attrs, body)
-- could check that body consists of appropriate elements
CREATE OR REPLACE
FUNCTION html_ol(TEXT, TEXT, TEXT, TEXT[], TEXT) RETURNS text AS $$
	SELECT html_element( $1, 'ol', $2, $3, $4, $5 )
$$ LANGUAGE sql;

-- + html_ol_li(nl, class, id, more_attrs, item_class, items)
CREATE OR REPLACE
FUNCTION html_ol_li(TEXT, TEXT, TEXT, TEXT[], TEXT, TEXT[])
RETURNS text AS $$
	SELECT html_ol( $1, $2, $3, $4, html_elements($1, 'li', $5, $6) )
$$ LANGUAGE sql;
