-- * Header  -*-Mode: sql;-*-
-- \ir settings.sql
-- SELECT set_file('xml-op-class.sql', '$Id');

--    (setq outline-regexp "^--[ \t]+[*+-~=]+ ")
--    (outline-minor-mode)

--	Wicci Project Utilities XML Code

-- ** Copyright

--	Copyright (c) 2013, J. Greg Davidson, all rights reserved.
--	Although it is my intention to make this code available
--	under a Free Software license when it is ready, this code
--	is currently not to be copied nor shown to anyone without
--	my permission in writing.

-- * Naive Comparison Functions and Operators for XML

-- While it is not possible to provide proper comparison
-- operators for XML, since in PostgreSQL XML is just
-- text in disguise we can do a naive version!

CREATE FUNCTION naive_xml_cmp(xml, xml) RETURNS int4 AS $$
	SELECT CASE
		WHEN text_lt($1::text, $2::text) THEN -1
		WHEN text_gt($1::text, $2::text) THEN 1
		ELSE 0
	END
$$ LANGUAGE SQL IMMUTABLE;

CREATE FUNCTION naive_xml_lt(xml, xml) RETURNS bool
AS $$ SELECT text_lt($1::text, $2::text) $$
LANGUAGE SQL IMMUTABLE;

CREATE FUNCTION naive_xml_le(xml, xml) RETURNS bool
AS $$ SELECT text_le($1::text, $2::text) $$
LANGUAGE SQL IMMUTABLE;

CREATE FUNCTION naive_xml_eq(xml, xml) RETURNS bool
AS $$ SELECT texteq($1::text, $2::text) $$
LANGUAGE SQL IMMUTABLE;

CREATE FUNCTION naive_xml_neq(xml, xml) RETURNS bool
AS $$ SELECT textne($1::text, $2::text) $$
LANGUAGE SQL IMMUTABLE;

CREATE FUNCTION naive_xml_ge(xml, xml) RETURNS bool
AS $$ SELECT text_ge($1::text, $2::text) $$
LANGUAGE SQL IMMUTABLE;

CREATE FUNCTION naive_xml_gt(xml, xml) RETURNS bool
AS $$ SELECT text_gt($1::text, $2::text) $$
LANGUAGE SQL IMMUTABLE;

CREATE OPERATOR < (
	 leftarg = xml, rightarg = xml, procedure = naive_xml_lt,
	 commutator = > , negator = >= ,
	 restrict = scalarltsel, join = scalarltjoinsel
);
CREATE OPERATOR <= (
	 leftarg = xml, rightarg = xml, procedure = naive_xml_le,
	 commutator = >= , negator = > ,
	 restrict = scalarltsel, join = scalarltjoinsel
);
CREATE OPERATOR = (
	 leftarg = xml, rightarg = xml, procedure = naive_xml_eq,
	 commutator = = ,
	 negator = <> ,
	 restrict = eqsel, join = eqjoinsel
);
CREATE OPERATOR <> (
	 leftarg = xml, rightarg = xml, procedure = naive_xml_neq,
	 commutator = <> ,
	 negator = = ,
	 restrict = neqsel, join = neqjoinsel
);
CREATE OPERATOR >= (
	 leftarg = xml, rightarg = xml, procedure = naive_xml_ge,
	 commutator = <= , negator = < ,
	 restrict = scalargtsel, join = scalargtjoinsel
);
CREATE OPERATOR > (
	 leftarg = xml, rightarg = xml, procedure = naive_xml_gt,
	 commutator = < , negator = <= ,
	 restrict = scalargtsel, join = scalargtjoinsel
);

-- now we can make the operator class
CREATE OPERATOR CLASS naive_xml_cmp_ops
		DEFAULT FOR TYPE xml USING btree AS
				OPERATOR        1       < ,
				OPERATOR        2       <= ,
				OPERATOR        3       = ,
				OPERATOR        4       >= ,
				OPERATOR        5       > ,
				FUNCTION        1       naive_xml_cmp(xml, xml);
