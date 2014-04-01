-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('modules-code.sql', '$Id');

-- modules-code.sql
-- track which modules are loaded

CREATE OR REPLACE
VIEW modules_schemas AS
	SELECT m.id AS module_id, schema_id, module_name, schema_name, file_name, rev
	FROM modules m, our_schema_names osn WHERE schema_id = osn.id;

CREATE OR REPLACE
FUNCTION this_module() RETURNS module_ids AS $$
	SELECT id::module_ids FROM current_module WHERE id IS NOT NULL
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION this_module(module_ids) RETURNS void AS $$
	UPDATE current_module SET id = $1;
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION module_schema_name(module_ids) RETURNS schema_names AS $$
	SELECT schema_name FROM modules_schemas where module_id = $1
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION module_id(schema_names, module_names) RETURNS module_ids AS $$
	SELECT module_id FROM modules_schemas
	WHERE schema_name = $1 AND module_name = $2
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION module_id(module_names) RETURNS module_ids AS $$
	SELECT CASE array_upper(module_name, 1)
		WHEN 1 THEN module_id(module_schema_name(this_module()), module_name[1])
		WHEN 2 THEN module_id(module_name[1], module_name[2])
	END::module_ids
	FROM string_to_array($1, '.') module_name
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION module_basename(module_ids) RETURNS module_names AS $$
	SELECT module_name FROM modules WHERE id = $1
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION module_fullname(module_ids) RETURNS text AS $$
	SELECT module_schema_name($1) || '.' || module_basename($1)
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION is_good_rev(text) RETURNS boolean AS $$
	SELECT CASE
		WHEN $1 IS NULL THEN false
		WHEN $1 = '' THEN false
		WHEN $1 = ('$I' || 'd$') THEN false
		ELSE true
	END
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION nice_rev(text) RETURNS text AS $$
	SELECT $1
$$ LANGUAGE sql;
COMMENT ON FUNCTION nice_rev(text) IS
'hook for reformatting revision string nicely';

CREATE OR REPLACE
FUNCTION module_nice_text(module_ids) RETURNS text AS $$
	SELECT
		'module' ||
		' id: ' || module_id::text ||
		' schema: ' || schema_name ||
		' name: ' || module_name ||
		COALESCE( ' filename: ' || file_name, '' ) ||
		CASE is_good_rev(rev)
			WHEN false THEN ''
			WHEN true THEN ' rev: ' || nice_rev(rev)
		END
	FROM modules_schemas WHERE module_id = $1
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION schema_name_file_rev(
	s_name schema_names, n module_names, f TEXT, r TEXT
) RETURNS module_ids AS $$
	DECLARE
		s_id schema_ids := declare_schema(s_name);
		m maybe_modules;
		kilroy_was_here boolean := false;
		this regprocedure := 'schema_name_file_rev(
			schema_names, module_names, TEXT, TEXT
		)';
	BEGIN
		LOOP
			SELECT * INTO m FROM modules
			WHERE schema_id = s_id AND module_name = n
			FOR UPDATE;
			IF FOUND THEN
				IF NOT COALESCE(m.file_name = f, true)
				OR NOT COALESCE(m.rev = r, true) THEN
					RAISE EXCEPTION '% %,%,%,% !=! %',
		 					this, s_name, n, f, r, m;
				END IF;
				PERFORM this_module(m.id::module_ids);
				IF f IS NOT NULL AND f IS DISTINCT FROM m.file_name THEN
					UPDATE modules SET file_name = f WHERE id = m.id;
				END IF;
				IF is_good_rev(r) AND r IS DISTINCT FROM m.rev THEN
					UPDATE modules SET rev = r WHERE id = m.id;
				END IF;
				RETURN m.id;
			END IF;			-- END IF FOUND
			IF kilroy_was_here THEN
				RAISE EXCEPTION '% looping with %,%,%,%',
		 				this, s_name, n, f, r;
			END IF;
			kilroy_was_here := true;
			BEGIN
				INSERT INTO modules(schema_id, module_name)
				VALUES(s_id, n);
			EXCEPTION
				WHEN unique_violation THEN -- another thread ??
					RAISE NOTICE '% raised % with %,%,%,%',
		 				this, 'unique_violation', s_name, n, f, r;
			END;
		END LOOP;
	END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION schema_name_file_rev(
	schema_names, module_names, TEXT, TEXT
) IS 'find or insert and maybe update a description of a module';

CREATE OR REPLACE
FUNCTION file_basename(filename TEXT) RETURNS text AS $$
	SELECT 
		regexp_replace($1, '^(.*/)?([^.]*).*', E'\\2')
$$ LANGUAGE sql IMMUTABLE;
COMMENT ON FUNCTION file_basename(TEXT) IS
'return the base part of a filename, i.e. the
part without any directory or extensions.';

SELECT test_func(
	'file_basename(TEXT)',
	file_basename('this/foo.bar'),
	'foo'
);

CREATE OR REPLACE
FUNCTION infer_module_name(schema_names, TEXT) RETURNS module_names AS $$
	SELECT file_basename($2)::module_names
$$ LANGUAGE sql IMMUTABLE;
COMMENT ON FUNCTION infer_module_name(schema_names, TEXT) IS
'Same as the basename.  The schema_name is ignored.';

SELECT test_func(
	'infer_module_name(schema_names, text)',
	infer_module_name('schema', 'this/schema_foo.bar'),
	'schema_foo'
);

CREATE OR REPLACE
FUNCTION set_file(TEXT, TEXT DEFAULT '') RETURNS TEXT AS $$
	SELECT (
		SELECT
			'schema ' || $1 || ', module ' || module_::text ||
			CASE
	WHEN NOT is_good_rev($2) THEN ''
	ELSE ', revision ' || $2
			END ||
			', id ' || schema_name_file_rev(schema_, module_, $1, $2)::text
			FROM infer_module_name(schema_, $1) module_
	) FROM current_schema() schema_
$$ LANGUAGE sql;
COMMENT ON FUNCTION set_file(TEXT, TEXT)
IS 'declare the current module conveniently';

CREATE OR REPLACE
FUNCTION record_early_modules() RETURNS void AS $$
DECLARE
	_module RECORD;
	_name text;
BEGIN
	FOR _module IN SELECT * FROM early_modules ORDER BY id LOOP
		_name := infer_module_name(_module.schema_name, _module.file_name);
		RAISE NOTICE 'record_early_modules: recording %.%',
			_module.schema_name, _name;
		PERFORM schema_name_file_rev(
			_module.schema_name, _name, _module.file_name, _module.revision
		);
	END LOOP;
	DROP TABLE early_modules;
END
$$ LANGUAGE plpgsql;

SELECT record_early_modules();
DROP FUNCTION record_early_modules();

SELECT test_func(
	'module_schema_name(module_ids)',
	module_schema_name(this_module()),
	current_schema()::schema_names
);

SELECT test_func(
	'module_id(schema_names, module_names)',
	module_id(current_schema(), infer_module_name(current_schema(), 'modules-code.sql')),
	this_module()
);
