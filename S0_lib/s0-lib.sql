-- * HEADER  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('s0-lib.sql', '$Id');

CREATE OR REPLACE
FUNCTION sql_wicci_ready() RETURNS regprocedure AS $$
DECLARE
	schema_name TEXT[] :=	schema_path_trim( ARRAY[
		'S7_wicci','S6_http','S5_xml','S4_doc','S3_more',
		'S2_core','S1_refs','S0_lib','public','pg_catalog'] );
		i integer;
		this regprocedure := 'sql_wicci_ready()';
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
	RETURN this;
END
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION sql_wicci_ready() IS '
	Ensure that all modules of the sql schema
	needed for the Wicci system  are present.
';

CREATE OR REPLACE
FUNCTION ensure_schema_ready() RETURNS text AS $$
	SELECT sql_wicci_ready()::text;
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

-- jgd debug!!
-- functions to get rid of as soon as s1_refs.ensure_schema_ready
-- works better!  They are called in S1_refs/settings.sql
-- in S1_refs
CREATE OR REPLACE
FUNCTION spx_debug_on() RETURNS integer AS $$
		SELECT 0
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION spx_collate_locale() RETURNS text AS $$
		SELECT 'not yet ready for you!';
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION unsafe_spx_load_schemas() RETURNS integer AS $$
		SELECT 0;
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION unsafe_spx_load_schema_path() RETURNS integer AS $$
		SELECT 0;
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION unsafe_spx_load_types() RETURNS integer AS $$
		SELECT 0;
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION unsafe_spx_load_procs() RETURNS integer AS $$
		SELECT 0;
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION unsafe_spx_initialize() RETURNS text AS $$
		SELECT 'not yet ready for you!';
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION spx_test_select(text, integer) RETURNS int8 AS $$
		SELECT 42::int8;
$$ LANGUAGE sql;

