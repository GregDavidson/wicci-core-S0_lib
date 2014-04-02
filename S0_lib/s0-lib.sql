-- * HEADER  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('s0-lib.sql', '$Id');

CREATE OR REPLACE
FUNCTION sql_wicci_ready() RETURNS void AS $$
DECLARE
	schema_name TEXT[] :=
		string_to_array('S7_wicci,S6_http,S5_xml,S4_doc,S3_more,S2_core,S1_refs,S0_lib,public,pg_catalog', ',');
		i integer;
BEGIN
-- Check sufficient elements of the Sql
-- dependency tree that we can be assured that
-- all of the modules we need have been loaded.
--	PERFORM require_module('s0_lib.html');
	FOR i IN REVERSE
		array_upper(schema_name,1)..array_lower(schema_name,1)
	LOOP
		PERFORM get_schema_name_id(schema_name[i]);
	END LOOP;
END
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION sql_wicci_ready() IS '
	Ensure that all modules of the sql schema
	needed for the Wicci/Wichi system  are present.
';

CREATE OR REPLACE
FUNCTION ensure_schema_ready() RETURNS regprocedure AS $$
	SELECT sql_wicci_ready();
	SELECT 'sql_wicci_ready()'::regprocedure
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION list_strict_non_try_funcs(_schema name)
RETURNS SETOF regprocedure AS $$
	SELECT pg_proc.oid::regprocedure
	FROM pg_proc, pg_namespace
	WHERE proisstrict AND NOT (proname LIKE 'try_%')
	AND pronamespace = pg_namespace.oid AND nspname = $1
$$ LANGUAGE sql;

SELECT list_strict_non_try_funcs('s0_lib');
