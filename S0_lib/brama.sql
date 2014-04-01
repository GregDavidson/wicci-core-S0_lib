-- * Header  -*-Mode: sql;-*-
-- fix when \ir is fixed!!
\cd
\cd .Wicci/Core/S0_lib
\i ../settings.sql

-- brama.sql
-- Get things started

-- ** Copyright (c) 2005-2012 J. Greg Davidson.
-- You may use this file under the terms of the
-- GNU AFFERO GENERAL PUBLIC LICENSE 3.0
-- as specified in the file LICENSE.md included with this distribution.
-- All other use requires my permission in writing.

-- * Extensions we really like

CREATE EXTENSION IF NOT EXISTS citext;

CREATE EXTENSION IF NOT EXISTS intarray;

CREATE EXTENSION IF NOT EXISTS xml2;

-- * Misc debugging-related functions needed early

-- CREATE OR REPLACE FUNCTION debug_fail_(
-- 	regprocedure, ANYELEMENT, VARIADIC text[]
-- ) RETURNS ANYELEMENT AS $$
-- BEGIN
-- 	RAISE EXCEPTION 'ERROR: %: %%!', $1, $2,
-- 		COALESCE(' ' || array_to_string($3, ' '), '');
-- END
-- $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION debug_fail(
	regprocedure, ANYELEMENT, VARIADIC text[] = '{}'
) RETURNS ANYELEMENT AS $$
BEGIN
	RAISE EXCEPTION 'ERROR: %!',
		array_to_string(
			ARRAY[$1::text, COALESCE($2::text, 'NULL')] || $3, ' '
		);
END
$$ LANGUAGE plpgsql;

COMMENT ON
FUNCTION debug_fail(regprocedure, ANYELEMENT, text[])
IS 'Raise exception;
report failure of given function with entity and any messages.';

CREATE OR REPLACE FUNCTION non_null(
	ANYELEMENT, regprocedure, VARIADIC text[] = NULL
) RETURNS ANYELEMENT AS $$
	SELECT COALESCE($1, debug_fail($2, $1, VARIADIC $3))
$$ LANGUAGE sql;
COMMENT ON FUNCTION non_null(ANYELEMENT, regprocedure, text[])
IS 'Returns first argument when non-null; reports error otherwise';

-- * early_modules

CREATE TABLE IF NOT EXISTS early_modules (
	id SERIAL PRIMARY KEY,
	schema_name text NOT NULL,
	file_name text NOT NULL,
	UNIQUE(schema_name, file_name),
	revision text
);
COMMENT ON TABLE early_modules IS '
	Holds metadata on first few modules until
	the module registration system is in place,
	after which these rows will be reprocessed
	and this table will be dropped!
';

CREATE OR REPLACE
FUNCTION try_schema_trim(text) RETURNS text AS $$
 SELECT lower(regexp_replace($1, '[^_[:alnum:]]', '', 'g'))
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE
FUNCTION schema_trim(text) RETURNS text AS $$
 SELECT non_null(
 	try_schema_trim($1), 'schema_trim(text)'
	)
$$ LANGUAGE sql;
COMMENT ON FUNCTION schema_trim(text) IS
'Normalize a schema name';

CREATE OR REPLACE
FUNCTION schema_path_trim(text[]) RETURNS text[] AS $$
	SELECT ARRAY(
 		SELECT schema_trim($1[i])
		FROM generate_series(1, array_upper($1, 1)) i
	)
$$ LANGUAGE sql;
COMMENT ON FUNCTION schema_path_trim(text[]) IS
'Normalize a schema path';

CREATE OR REPLACE
FUNCTION try_system_schema_oid(text) RETURNS oid AS $$
	SELECT oid FROM pg_namespace
	WHERE nspname = schema_trim($1)
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE
FUNCTION system_schema_oid(text) RETURNS oid AS $$
	SELECT non_null(
		try_system_schema_oid($1), 'system_schema_oid(text)'
	)
$$ LANGUAGE sql;
COMMENT ON FUNCTION system_schema_oid(text) IS
'Returns the system Object ID associated with the given schema';

CREATE OR REPLACE
FUNCTION try_system_schema_name(oid) RETURNS text AS $$
	SELECT nspname::text FROM pg_namespace WHERE oid = $1
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE
FUNCTION system_schema_name(oid) RETURNS text AS $$
	SELECT non_null(
		try_system_schema_name($1), 'system_schema_name(oid)'
	)
$$ LANGUAGE sql;
COMMENT ON FUNCTION system_schema_oid(text) IS
'Returns the name of the schema associated with the given Object ID';

CREATE OR REPLACE
FUNCTION try_system_schema_exists(text) RETURNS boolean AS $$
	SELECT try_system_schema_oid($1) IS NOT NULL
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE
FUNCTION system_schema_exists(text) RETURNS boolean AS $$
	SELECT non_null(
		try_system_schema_exists($1),
		'system_schema_exists(text)'
	)
$$ LANGUAGE sql;
COMMENT ON FUNCTION system_schema_exists(text) IS
'Null argument raises exception; otherwise, returns whether the
argument is the name of an existing system schema.';

CREATE OR REPLACE
FUNCTION try_system_schema_exists(oid) RETURNS boolean AS $$
	SELECT try_system_schema_name($1) IS NOT NULL
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE
FUNCTION system_schema_exists(oid) RETURNS boolean AS $$
	SELECT non_null(
		try_system_schema_exists($1),
		'system_schema_exists(oid)'
	)
$$ LANGUAGE sql;
COMMENT ON FUNCTION system_schema_exists(oid) IS
'Null argument raises exception; otherwise, returns whether the
argument is the Object ID of an existing system schema.';

CREATE OR REPLACE
FUNCTION require_system_schema(text) RETURNS oid AS $$
	SELECT system_schema_oid($1)
$$ LANGUAGE sql;
COMMENT ON FUNCTION require_system_schema(text) IS
'Raises exception if argument does not name a system schema.';

CREATE OR REPLACE
FUNCTION require_system_schema(oid) RETURNS text AS $$
	SELECT system_schema_name($1)
$$ LANGUAGE sql;
COMMENT ON FUNCTION require_system_schema(oid) IS
'Raises exception if argument not Object ID of a system schema.';

CREATE OR REPLACE
FUNCTION try_meta_execute(regprocedure, VARIADIC text[])
RETURNS boolean AS $$
DECLARE
	sql_command text := array_to_string($2, ' ');
BEGIN
	RAISE NOTICE E'\n---> META %\n%\n<--- META', $1, sql_command;
  EXECUTE sql_command;
	RETURN true;
END
$$ LANGUAGE plpgsql STRICT;

CREATE OR REPLACE
FUNCTION meta_execute(regprocedure, VARIADIC text[])
RETURNS boolean AS $$
	SELECT non_null(
		try_meta_execute($1, VARIADIC $2),
		'meta_execute(regprocedure,text[])'
	)
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION declare_system_schema(text) RETURNS oid AS $$
DECLARE
	_name text := schema_trim($1);
	ss_oid oid := try_system_schema_oid(_name);
	this regprocedure := 'declare_system_schema(text)';
BEGIN
	IF ss_oid IS NOT NULL THEN RETURN ss_oid; END IF;
	PERFORM meta_execute(this, 'CREATE SCHEMA ' || $1);
	RETURN system_schema_oid(_name);
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION declare_system_schema(text) IS '
	Ensure that the specified system schema exists,
	creating it and raising a notice if it did not
';

-- system_schema_path() obsoleted by current_schemas(false)
-- CREATE OR REPLACE
-- FUNCTION system_schema_path() RETURNS text[] AS $$
-- 	SELECT string_to_array( lower( regexp_replace(
-- 		current_setting('search_path'), '[[:space:]]', '', 'g'
-- 	) ), ',' )
-- $$ LANGUAGE sql;
-- COMMENT ON FUNCTION system_schema_path() IS
-- 'Returns the current schema search path,
-- normalized and comma separated.';

-- system_schema_top obsoleted by current_schema()
-- CREATE OR REPLACE
-- FUNCTION system_schema_top() RETURNS text AS $$
--  SELECT (system_schema_path())[1]
-- $$ LANGUAGE sql;
-- COMMENT ON FUNCTION system_schema_top() IS
-- 'Returns name of first schema on the current schema search path,
-- normalized.';

CREATE OR REPLACE
FUNCTION set_schema_path(VARIADIC text[] = '{}')
RETURNS text[] AS $$
DECLARE
	this regprocedure := 'set_schema_path(text[])';
	schema_names text[] := schema_path_trim($1);
BEGIN
	IF array_upper(schema_names, 1) < 1 THEN
		RAISE EXCEPTION '%: Two few schemas in %!', this, schema_names;
	END IF;
	FOR i IN 2 .. array_upper(schema_names, 1) LOOP
		IF NOT system_schema_exists(schema_names[i]) THEN
			RAISE EXCEPTION '%: No schema %!', this, schema_names[i];
		END IF;
	END LOOP;
	PERFORM declare_system_schema(schema_names[1]);
	PERFORM set_config(
		'search_path', array_to_string(schema_names, ','), false
	);
	RETURN current_schemas(false);
END
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION set_schema_path(text[]) IS
'Sets the current schema search path to the given path
which must have at least one element on it.
Requires all but the first schema to already exist.
Ensures that the first schema exists.';

CREATE OR REPLACE
FUNCTION set_file(text, text DEFAULT '') RETURNS text AS $$
DECLARE
	this regprocedure := 'set_file(text, text)';
	ret text[];
BEGIN
	BEGIN
		INSERT INTO early_modules(schema_name, file_name, revision)
		VALUES ( current_schema(), $1, $2 )
		RETURNING ARRAY[schema_name::text, file_name]
			||	CASE
						WHEN revision IS NULL THEN '{}'::text[]
						ELSE ARRAY[revision]
					END
		INTO ret;
	EXCEPTION WHEN unique_violation THEN
		RAISE NOTICE '% % % raised %!', this, $1, $2, 'unique_violation';
	END;
	RETURN array_to_string(ret, ' ');
END;
$$ LANGUAGE plpgsql STRICT;
COMMENT ON FUNCTION set_file(text, text) IS
'Records the current schema, filename and (optionally) revision.';

CREATE OR REPLACE
FUNCTION ensure_schema_ready() RETURNS regprocedure AS $$
	SELECT 'ensure_schema_ready()'::regprocedure;
$$ LANGUAGE sql;

-- SELECT set_schema_path('s0_lib','public');
SELECT set_file('brama.sql', '$Id$');
