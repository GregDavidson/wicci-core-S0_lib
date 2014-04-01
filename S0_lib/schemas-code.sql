-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('schemas-code.sql', '$Id');

-- schemas-code.sql
-- manage system and shadow schemas


CREATE OR REPLACE
FUNCTION aligned_length(text, integer DEFAULT 8)
RETURNS integer AS $$
	SELECT (len + $2 - 1) / $2 * $2
	FROM (SELECT octet_length($1) + 1) AS foo(len)
$$ LANGUAGE sql IMMUTABLE;
COMMENT ON FUNCTION aligned_length(text, integer) IS
'compute the number of bytes to allow for the text,
plus 1 for a NUL byte, plus padding to bring us to a
word boundary, assuming we began on a word boundary';

-- should we put in a check that the schema exists???
CREATE OR REPLACE VIEW schema_view_ AS
	SELECT id, schema_name, schema_oid,
		aligned_length(schema_name) AS name_size_
	FROM our_schema_names
	LEFT OUTER JOIN our_namespaces
	USING(id);

CREATE OR REPLACE VIEW schema_view AS
	SELECT
		os.id::integer AS id_,
		os.schema_name::text AS name_,
		os.schema_oid AS oid_,
		name_size_, min_id_, max_id_, sum_text_
	FROM schema_view_ os,  (
			SELECT MIN(id), MAX(id), SUM(name_size_)::bigint
			FROM schema_view_ WHERE schema_oid IS NOT NULL
	) AS foo(min_id_, max_id_, sum_text_)
	WHERE schema_oid IS NOT NULL;
COMMENT ON VIEW schema_view IS
'Used by spx_load_schemas in spx.so';

CREATE OR REPLACE
FUNCTION schema_clean() RETURNS void AS $$
	DELETE FROM our_namespaces
	WHERE NOT EXISTS (
		SELECT p.oid FROM pg_namespace p
		WHERE p.oid = schema_oid
	);
$$ LANGUAGE SQL;
COMMENT ON FUNCTION schema_clean() IS
'Get rid of any garbage in our_namespaces.';

-- ** Compare homonyms in schemas-schema.sql

CREATE OR REPLACE
FUNCTION try_schema_id(schema_names)
RETURNS schema_ids AS $$
	SELECT try_schema_id(try_system_schema_oid($1))
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE
FUNCTION find_schema_id(schema_names)
RETURNS schema_ids AS $$
	SELECT non_null(
		try_schema_id($1),
		'find_schema_id(schema_names)',
		$1::text
	)
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION try_new_schema_id(schema_names)
RETURNS schema_ids AS $$
	SELECT new_schema_id(system_schema_oid($1))
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE
FUNCTION new_schema_id(schema_names)
RETURNS schema_ids AS $$
	SELECT new_schema_id(declare_system_schema($1))
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION declare_schema(schema_names)
RETURNS schema_ids AS $$
	SELECT COALESCE(
		try_schema_id($1),
		new_schema_id($1),
		find_schema_id($1)
	)
$$ LANGUAGE sql;
COMMENT ON FUNCTION declare_schema(schema_names) IS '
	return the id of a shadow schema representing a
	system schema, creating both if necessary
	- careful with typos!!';

SELECT test_func(
	'declare_schema(schema_names)',
	declare_schema('public') > 0
);

SELECT test_func(
	'declare_schema(schema_names)',
	declare_schema('s0_lib') > 0
);

CREATE OR REPLACE
FUNCTION this_schema() RETURNS schema_ids AS $$
	SELECT find_schema_id(current_schema())
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION schema_name(schema_ids)
RETURNS schema_names AS $$
	SELECT schema_name FROM our_schema_names
	WHERE id = $1
$$ LANGUAGE sql;

SELECT test_func(
	'schema_name(schema_ids)',
	schema_name(find_schema_id('public')),
	'public'
);

SELECT test_func(
	'declare_schema(schema_names)',
	schema_name(declare_schema('foo')),
	'foo'
);

CREATE OR REPLACE FUNCTION schema_path_array(
	VARIADIC text[] = current_schemas(false)
) RETURNS schema_id_arrays AS $$
	SELECT ARRAY(
		SELECT find_schema_id(x)::integer
		FROM unnest($1) x
	)::schema_id_arrays
$$ LANGUAGE sql;

SELECT test_func(
	'schema_path_array(text[])',
	from_schema_id_array(schema_path_array('public','foo')),
	ARRAY[
		from_schema_id(find_schema_id('public')),
		from_schema_id(find_schema_id('foo'))
	]
);

CREATE OR REPLACE
FUNCTION schema_path(schema_id_arrays)
RETURNS text AS $$
	SELECT array_to_string( ARRAY(
		SELECT schema_name( ($1)[i] )::text
		FROM generate_series(
			array_lower(from_schema_id_array($1), 1),
			array_upper(from_schema_id_array($1), 1)
		) i
	), ', ' )
$$ LANGUAGE sql;

SELECT test_func(
	'schema_path(schema_id_arrays)',
	schema_path(ARRAY[
		find_schema_id('public')::integer,
		find_schema_id('foo')::integer
	]::schema_id_arrays),
	'public, foo'
);

CREATE OR REPLACE
FUNCTION schema_path_set(schema_id_arrays)
RETURNS text AS $$
	SELECT set_config('search_path', schema_path($1), false);
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION schema_path_push(schema_names)
RETURNS text[] AS $$
	DECLARE
		old_path schema_id_arrays := schema_path_array();
		new_id schema_ids := declare_schema($1);
		new_path schema_id_arrays := array_prepend(
			new_id::integer,
			array_remove(old_path::integer[], new_id::integer)
		)::schema_id_arrays;
	BEGIN
		IF from_schema_id_array(old_path)
			<> from_schema_id_array(new_path)
		THEN PERFORM schema_path_set(new_path);
		END IF;
		RETURN current_schemas(false);
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE
FUNCTION schema_path_drop(schema_names)
RETURNS text[] AS $$
DECLARE
	old_path schema_id_arrays := schema_path_array();
	new_id schema_ids := find_schema_id($1);
	new_path schema_id_arrays
		:= array_remove(old_path::integer[], new_id::integer);
BEGIN
	IF from_schema_id_array(old_path)
		<> from_schema_id_array(new_path)
	THEN PERFORM schema_path_set(new_path);
	END IF;
	RETURN current_schemas(false);
END
$$ LANGUAGE plpgsql;

SELECT test_func(
	'schema_path_push(schema_names)',
	schema_path_trim(schema_path_push('foo')),
	schema_trim('foo') || old_path::text[]
) FROM current_schemas(false) old_path;

SELECT test_func(
	'schema_path_drop(schema_names)',
	schema_trim('foo') || schema_path_drop('foo'),
	old_path::text[]
) FROM current_schemas(false) old_path;

CREATE OR REPLACE
FUNCTION drop_schema(schema_names) RETURNS text AS $$
	DECLARE
		the_result text := $1;
		this regprocedure := 'drop_schema(schema_names)';
	BEGIN
		PERFORM schema_path_drop($1);
		DELETE FROM our_namespaces
		WHERE id = find_schema_id($1);
		IF FOUND THEN
			the_result := the_result || ' module schema dropped';
		ELSE
			RAISE NOTICE
				'drop_schema(%): No such module schema!', $1;
			the_result := the_result || ' no module schema dropped';
		END IF;
		IF system_schema_exists($1) THEN
			PERFORM meta_execute(this, 'DROP SCHEMA ' || $1
				|| ' CASCADE');
			the_result := the_result || ' system schema dropped';
		ELSE
			RAISE NOTICE
				'drop_schema(%): No such system schema!', $1;
			the_result := the_result || ' no system schema dropped';
		END IF;
		RETURN the_result;
	END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION drop_schema(schema_names) IS '
	Drop the module and system schemas of a given name,
	both of which should exist.
';

SELECT test_func(
	'drop_schema(schema_names)',
	drop_schema('foo'),
	'foo module schema dropped system schema dropped'
);

SELECT test_func(
	'drop_schema(schema_names)',
	NOT system_schema_exists('foo')
);

CREATE OR REPLACE
FUNCTION drop_schemas(schema_names)
RETURNS text[] AS $$
DECLARE
	_name text;
	names text[] = '{}';
	_from integer;
	_to integer;
BEGIN
	SELECT INTO _from MAX(id) FROM our_schema_names;
	SELECT INTo _to id FROM our_schema_names
	WHERE schema_name = $1;
	FOR i IN REVERSE _from .. _to LOOP
			SELECT INTO _name drop_schema(schema_name(i))
			WHERE try_system_schema_oid(schema_name(i)) IS NOT NULL;
			IF FOUND THEN
				names := names || _name;
			END IF;
	END LOOP;
	PERFORM schema_clean();
	RETURN names;
END
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION drop_schemas(schema_names)
IS 'DROP our schemas from the max in use down to $1';

CREATE OR REPLACE
FUNCTION schema_path_list()
RETURNS SETOF schema_names AS $$
	SELECT s::schema_names FROM unnest(
		current_schemas(false)::text[] || schema_trim('pg_catalog')
	) s
$$ LANGUAGE sql;

CREATE OR REPLACE VIEW schema_path_by_id AS
	SELECT id_, name_, oid_ FROM schema_path_list() AS s
	INNER JOIN schema_view ON(s = name_)
	ORDER BY id_;
COMMENT ON VIEW schema_path_by_id IS
'Used by spx_load_schema_path in spx.so';

-- still needed???
CREATE OR REPLACE
FUNCTION xxx_schema_path_name_oid_list()
RETURNS  TABLE(o oid, n text) AS $$
	SELECT bar.oid, bar.nspname::text
	FROM schema_path_list() AS foo
	INNER JOIN pg_namespace bar ON(foo=bar.nspname)
$$ LANGUAGE sql;

-- still needed???
CREATE OR REPLACE
FUNCTION type_name_to_oid_namespace(text)
RETURNS TABLE(ty oid, ns oid) AS $$
	SELECT oid, typnamespace
	FROM pg_type WHERE typname = $1::text
$$ LANGUAGE sql;
