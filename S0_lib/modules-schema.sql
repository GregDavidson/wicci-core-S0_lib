-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('modules-schema.sql', '$Id');

-- modules-schema.sql
-- track which modules are loaded

-- * Simple Module Schema

CREATE DOMAIN module_ids AS integer NOT NULL;
CREATE DOMAIN maybe_module_ids AS integer;
CREATE DOMAIN module_names AS text NOT NULL;
CREATE DOMAIN maybe_module_names AS text;

CREATE SEQUENCE modules_id_seq;

CREATE OR REPLACE
FUNCTION next_module_id() RETURNS module_ids AS $$
	SELECT nextval('modules_id_seq')::module_ids
$$ LANGUAGE sql;

CREATE TYPE maybe_modules AS (
	id maybe_module_ids,
	schema_id maybe_schema_ids,
	module_name maybe_module_names,
	file_name TEXT,
	rev TEXT
);
COMMENT ON TYPE maybe_modules IS
'Needed to retrieve result rows from table modules.';

CREATE TABLE IF NOT EXISTS modules (
	id module_ids PRIMARY KEY DEFAULT next_module_id(),
	schema_id schema_ids REFERENCES our_namespaces ON DELETE CASCADE,
	module_name module_names,
	UNIQUE(schema_id, module_name),
	file_name TEXT,
	rev TEXT
);
COMMENT ON TABLE modules IS
'Represents a coherent group of database entities
within a single database schema,
typically managed in a single source text file.';

ALTER SEQUENCE modules_id_seq OWNED BY modules.id;

CREATE TABLE IF NOT EXISTS current_module (
	id maybe_module_ids REFERENCES modules ON DELETE SET NULL
--  CHECK( count(*) = 1 )
);
COMMENT ON TABLE current_module IS '
	A singleton table whose one row, when NOT NULL,
	represents the module currently being loaded.
';

INSERT INTO current_module(id) VALUES(NULL);
