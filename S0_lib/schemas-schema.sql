-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('schemas-schema.sql', '$Id');

-- schemas-schema.sql
-- shadow system schemas with a referenceable table

-- * Simple Module Schema

DROP DOMAIN IF EXISTS schema_ids CASCADE;
DROP DOMAIN IF EXISTS maybe_schema_ids CASCADE;
DROP DOMAIN IF EXISTS schema_id_arrays CASCADE;

DROP DOMAIN IF EXISTS schema_names CASCADE;
DROP DOMAIN IF EXISTS maybe_schema_names CASCADE;
-- DROP DOMAIN IF EXISTS schema_name_arrays CASCADE;

CREATE DOMAIN schema_ids AS integer NOT NULL;
CREATE DOMAIN maybe_schema_ids AS integer;
CREATE DOMAIN schema_id_arrays AS integer[];

CREATE OR REPLACE
FUNCTION from_schema_id(schema_ids) RETURNS integer AS $$
	SELECT $1::integer
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION from_schema_id_array(schema_id_arrays)
RETURNS integer[] AS $$
	SELECT $1::integer[]
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION to_schema_id_array(integer[])
RETURNS schema_id_arrays AS $$
	SELECT $1::schema_id_arrays
$$ LANGUAGE sql;

CREATE DOMAIN schema_names AS text NOT NULL;
CREATE DOMAIN maybe_schema_names AS text;
-- CREATE DOMAIN schema_name_arrays AS text[];

DROP SEQUENCE IF EXISTS schema_id_seq CASCADE;

CREATE SEQUENCE schema_id_seq;

CREATE OR REPLACE
FUNCTION next_module_schema_id() RETURNS schema_ids AS $$
	SELECT nextval('schema_id_seq')::schema_ids
$$ LANGUAGE sql;

CREATE TABLE IF NOT EXISTS our_schema_names (
	id schema_ids PRIMARY KEY DEFAULT next_module_schema_id(),
	schema_name schema_names UNIQUE NOT NULL
);
COMMENT ON TABLE our_schema_names IS
'Represents the names of the schemas we have designed to hold
the components of our system.  During development the
corresponding schemas may not always exist.  The intent is
that the entities of the higher numbered schemas may depend
on those of the lower numbered schemas, but not vice versa.';
COMMENT ON COLUMN our_schema_names.schema_name IS
'UNIQUE prevents pg_namespace(oid) change disaster!!';

ALTER SEQUENCE schema_id_seq OWNED BY our_schema_names.id;

CREATE TABLE IF NOT EXISTS our_namespaces (
	id schema_ids PRIMARY KEY DEFAULT 0
	REFERENCES our_schema_names ON DELETE CASCADE,
	schema_oid oid UNIQUE NOT NULL DEFAULT 0
	-- REFERENCES pg_namespace(nspname) ON DELETE CASCADE
);
COMMENT ON TABLE our_namespaces IS
'Shadows pg_namespace as a workaround for the current (pgsql 8.4)
prohibition of referencing system catalogs.  Our modules, functions
and types reference this table.  When we drop a schema we drop the row
here, which ensure that we have no references to modules, functions
and types which no longer exist.  Ideally we should be able to simply
drop a row in this table and have the CASCADE remove all of our
modules, functions and types even without dropping the schema???';
COMMENT ON COLUMN our_namespaces.id IS
'When 0 the insert trigger will try to fill it in from our_schema_names;
UNIQUE prevents pg_namespace(oid) change disaster!!';
COMMENT ON COLUMN our_namespaces.schema_oid IS
'When 0 the insert trigger will try to fill it in from pg_namespace;
REFERENCES pg_namespace(nspname) but not supported in pgsql!!';

CREATE OR REPLACE
FUNCTION schema_id_to_name(schema_ids) RETURNS schema_names AS $$
	SELECT schema_name FROM our_schema_names WHERE id = $1
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION namespace_oid_to_name(oid) RETURNS text AS $$
	SELECT nspname::text FROM pg_namespace WHERE oid = $1
$$ LANGUAGE sql;

/*
CREATE OR REPLACE
FUNCTION get_schema_name_id(schema_names) RETURNS schema_ids AS $$
	DECLARE
		osn_id INTEGER;
	BEGIN
		LOOP
			SELECT id INTO osn_id FROM our_schema_names osn
				WHERE osn.schema_name = $1 FOR UPDATE;
			IF FOUND THEN RETURN osn_id; END IF;
			BEGIN
				INSERT INTO our_schema_names(schema_name)
					VALUES ($1) RETURNING id INTO osn_id;
				RAISE NOTICE 'get_schema_name_id(%) ->  % NEW!', $1, osn_id;
				RETURN osn_id;
			EXCEPTION
				WHEN unique_violation THEN
					-- evidence of another thread
			END;
		END LOOP;
	END
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION get_schema_name_id(schema_names) IS '
	Given the name of a schema, return the associated id in our_schema_names,
	creating such a pair if none was found.  Not proof against misspellings!
';
*/

CREATE OR REPLACE
FUNCTION try_schema_name_id(schema_names)
RETURNS schema_ids AS $$
	SELECT id FROM our_schema_names WHERE schema_name = $1
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE
FUNCTION find_schema_name_id(schema_names)
RETURNS schema_ids AS $$
	SELECT non_null(
		try_schema_name_id($1), 'find_schema_name_id(schema_names)'
	)
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION new_schema_name_id(schema_names)
RETURNS schema_ids AS $$
	DECLARE
		osn_id INTEGER;
		this regprocedure := 'new_schema_name_id(schema_names)';
	BEGIN
		INSERT INTO our_schema_names(schema_name)
			VALUES ($1) RETURNING id INTO osn_id;
		RAISE NOTICE '% % ->  % NEW!', this, $1, osn_id;
		RETURN osn_id;
	EXCEPTION
		WHEN unique_violation THEN	-- another thread?
			RAISE NOTICE '% % raised %!', this, $1, 'unique_violation';
			RETURN NULL;
	END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE
FUNCTION get_schema_name_id(schema_names)
RETURNS schema_ids AS $$
	SELECT COALESCE(
		try_schema_name_id($1),
		new_schema_name_id($1),
		find_schema_name_id($1)
	)
$$ LANGUAGE sql;
COMMENT ON FUNCTION get_schema_name_id(schema_names) IS
'Given the name of a schema, return the associated id in
our_schema_names, creating such a pair if none was found.
Not proof against misspellings!  There are too many functions
involved in "creating" schemas!!';

CREATE OR REPLACE
FUNCTION our_namespace_insert() RETURNS trigger AS $$
	DECLARE
		osn_id INTEGER;
		osn_name maybe_schema_names := schema_id_to_name(NEW.id);
		pgns_oid oid;
		pgns_name text := namespace_oid_to_name(NEW.schema_oid);
	BEGIN
		IF NEW.schema_oid = 0 AND NEW.id = 0 THEN
			RAISE EXCEPTION 'Table % % with no data', TG_TABLE_NAME, TG_OP;
		END IF;
		IF NEW.schema_oid != 0 AND pgns_name IS NULL THEN
			RAISE EXCEPTION 'Table % % error: % not in pg_namespace',
				TG_TABLE_NAME, TG_OP, NEW.schema_oid;
		END IF;
		IF NEW.id != 0 AND osn_name IS NULL THEN
			RAISE EXCEPTION 'Table % % error: % not in our_schema_names',
				TG_TABLE_NAME, TG_OP, NEW.id;
		END IF;
		IF NEW.schema_oid = 0 THEN
			SELECT oid INTO pgns_oid FROM pg_namespace pgns
			WHERE pgns.nspname = osn_name;
			IF NOT FOUND THEN
				RAISE EXCEPTION 'Table % % error: % not in pg_namespace',
				TG_TABLE_NAME, TG_OP, osn_name;
			END IF;
			NEW.schema_oid := pgns_oid;
			RETURN NEW;
		END IF;
		IF NEW.id = 0 THEN
			NEW.id := get_schema_name_id(pgns_name);
			RETURN NEW;
		END IF;
		IF osn_name != pgns_name THEN
			RAISE EXCEPTION 'Table % % error: schema_name % != nspname %',
				TG_TABLE_NAME, TG_OP, osn_name, pgns_name;
		END IF;
		RETURN NEW;
	END
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION our_namespace_insert() IS '
	Ensure that any new row in our_namespaces corresponds to a valid row
	in our_schema_names AND to a valid row in pg_namespace.  If the
	namespace oid is missing try to fill it in from pg_namespace.
	Otherwise, if the id is missing, try to fill it in from, or create
	one in our_schema_names.  If the new data is inconsistent with
	existing data, report an error.
';

-- ** Compare homonyms in schemas-code.sql

CREATE OR REPLACE
FUNCTION try_schema_id(maybe_schema_oid oid)
RETURNS schema_ids AS $$
	SELECT id FROM our_namespaces WHERE schema_oid = $1
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE
FUNCTION find_schema_id(maybe_schema_oid oid)
RETURNS schema_ids AS $$
	SELECT non_null(
		try_schema_id($1), 'find_schema_id(oid)'
	)
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION new_schema_id(maybe_schema_oid oid)
RETURNS schema_ids AS $$
	DECLARE
		osn_id INTEGER;
		this regprocedure := 'new_schema_id(oid)';
	BEGIN
		INSERT INTO our_namespaces(schema_oid)
			VALUES ($1) RETURNING id INTO osn_id;
		RETURN osn_id;
	EXCEPTION
		WHEN unique_violation THEN	-- another thread?
			RAISE NOTICE '% % raised %!', this, $1, 'unique_violation';
			RETURN NULL;
	END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE
FUNCTION declare_schema(maybe_schema_oid oid)
RETURNS schema_ids AS $$
	SELECT COALESCE(
		try_schema_id($1),
		new_schema_id($1),
		find_schema_id($1)
	) WHERE system_schema_exists($1)
$$ LANGUAGE sql;
COMMENT ON FUNCTION declare_schema(oid) IS '
	Given an oid from pg_namespace, returns a consistent id from
	our_schema_names, inserting data into our_schema_names and
	our_namespaces as necessary.  Generates an error if no such oid
	exists in pg_namespace.
';

DROP TRIGGER IF EXISTS our_namespace_insert ON our_namespaces CASCADE;
DROP TRIGGER IF EXISTS our_namespace_update ON our_namespaces CASCADE;

CREATE TRIGGER our_namespace_insert
	BEFORE INSERT ON our_namespaces
	FOR EACH ROW EXECUTE PROCEDURE our_namespace_insert();

SELECT declare_monotonic('our_namespaces');

SELECT get_schema_name_id('foo');

INSERT INTO our_namespaces(schema_oid)
	SELECT oid FROM pg_namespace WHERE nspname = 'pg_catalog';
