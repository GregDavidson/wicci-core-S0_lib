-- * Header  -*-Mode: sql;-*-
--	PSQL Settings
--	Include at top of all other .sql files.
-- NOTE: Some essential settings come from my ~/.psqlrc file!!

-- Set an initial schema search_path beginning with a library
-- schema which we can fill with our fundamental utility functions,
-- including those which manage schemas and modules nicely.

\set VERBOSITY verbose
\set ON_ERROR_STOP
DO $$
DECLARE
	schema_name text;
	schema_names text[] := ARRAY['s0_lib', 'public']; -- desired search path
	schema_oid oid;
BEGIN
	 FOREACH schema_name IN ARRAY schema_names LOOP
	 	EXECUTE 'CREATE SCHEMA IF NOT EXISTS ' || schema_name;
  END LOOP;
	EXECUTE 'SET search_path TO ' || array_to_string(schema_names, ',');
END
$$;
