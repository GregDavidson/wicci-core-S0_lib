-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('handles.sql', '$Id');

--	PostgreSQL Row Notes and Names Utilities Code

-- ** Copyright

--	Copyright (c) 2005, 2006, J. Greg Davidson.
--	This code may be freely used by CreditLink Corporation
--	for their internal business needs but not redistributed
--	to third parties.

-- * Specification

-- SELECT require_module('modules-code');

-- This module provides machinery for attaching a convenience name
-- aka a handle, to a specific row of some table.

-- For example, given:
--	TABLE foos(
--	  x x_types,
--	  y y_types,
--	  PRIMARY KEY(x, y),
--	  .. other fields of foos
--	)
-- SELECT create_handles_for('foos');
-- will create:
--  TABLE foos_row_handles (
--	x x_types,
--	y y_types,
--	PRIMARY KEY(x, y),
--	FOREIGN KEY(x, y) REFERENCES foos(x, y) ON DELETE CASCADE,
--	  handle handles
--	);
--	TABLE foos_row_handles ( ... )
--	FUNCTION foos_row(handles, x_types, y_types) RETURNS foos
--		sets handle, error if already set to different value
--	FUNCTION foos_row(handles) RETURNS foos
--		retrieves row given handle, returns NULL if none
-- and when the primary key is a single field, as in
--	TABLE bars(
--	  ref refs PRIMARY KEY,
--	  .. other fields of table bars
--	)
-- we also create these two functions:
-- FUNCTION bars_ref(handles, refs) RETURNS refs
-- FUNCTION bars_ref(handles) RETURNS refs
-- returns the value of the field "ref" of the indicated row.

-- SELECT create_handles_plus_for('foos');
-- creates the above plus these additional functions:
-- FUNCTION foos_default_handle(x_types, y_types) RETURNS handles
-- FUNCTION get_foos_handle(x_types, y_types) RETURNS handles

-- create_handles_for used to create these additional functions:
--	FUNCTION foos_x(handles) RETURNS x_types
--	FUNCTION foos_y(handles) RETURNS y_types
-- but that code is now disabled exce.

-- Note: We create these helper functions you should not call:
--  FUNCTION foos_row_set_(handles, x_types, y_types) RETURNS foos
--  FUNCTION foos_row_get_(handles, x_types, y_types) RETURNS foos

-- It might be useful to create this
--	TYPE foos_keys AS ( ... )  - just the primary fields of foos
-- and/or this
--	FUNCTION foos_(x_types, y_types) RETURNS foos

-- ** These functions create the specified naming conventions:

CREATE OR REPLACE
FUNCTION handle_table_name_(regclass) RETURNS text AS $$
	SELECT $1::text || '_row_handles'
$$ LANGUAGE SQL IMMUTABLE;

-- CREATE OR REPLACE
-- FUNCTION keys_table_name_(regclass) RETURNS text AS $$
--   SELECT $1::text || '_primary_keys'
-- $$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE
FUNCTION table_row_name_(regclass) RETURNS text AS $$
	SELECT $1::text || '_row'
$$ LANGUAGE SQL IMMUTABLE;
-- name of function for getting or setting whole row

CREATE OR REPLACE
FUNCTION table_field_name_(regclass, meta_columns)
RETURNS text AS $$
	SELECT $1::text || '_' || quote_ident(($2).name_)
$$ LANGUAGE SQL IMMUTABLE;
-- name of function for getting or setting a single primary key field

CREATE OR REPLACE
FUNCTION row_getter_name_(regclass) RETURNS text AS $$
	SELECT table_row_name_($1)
$$ LANGUAGE SQL IMMUTABLE;
-- name of function for getting a whole row

CREATE OR REPLACE
FUNCTION row_setter_name_(regclass) RETURNS text AS $$
	SELECT table_row_name_($1)
$$ LANGUAGE SQL IMMUTABLE;
-- name of function for setting a whole row

CREATE OR REPLACE
FUNCTION row_setter_get_name_(regclass) RETURNS text AS $$
	SELECT table_row_name_($1) || '_get_'
$$ LANGUAGE SQL IMMUTABLE;
-- name of helper get function for setting a whole row

CREATE OR REPLACE
FUNCTION row_setter_set_name_(regclass) RETURNS text AS $$
	SELECT table_row_name_($1) || '_set_'
$$ LANGUAGE SQL IMMUTABLE;
-- name of helper set function for setting a whole row

CREATE OR REPLACE
FUNCTION handle_getter_name_(regclass) RETURNS text AS $$
	SELECT 'get_' || $1::text || '_handle'
$$ LANGUAGE SQL IMMUTABLE;
-- name of function for returning a handle given primary key,
-- i.e. the inverse of the usual getter function

CREATE OR REPLACE
FUNCTION default_handle_getter_name_(regclass)
RETURNS text AS $$
	SELECT $1::text || '_default_handle'
$$ LANGUAGE SQL IMMUTABLE;
-- name of function for returning a default handle name
-- i.e. a name to use for a row which doesn't have a set handle
-- NOTE: for output purposes only - will not work as a handle!

-- * Implementation

DROP DOMAIN IF EXISTS handles CASCADE;

CREATE DOMAIN handles AS text NOT NULL;
COMMENT ON DOMAIN handles IS
'a convenience name for a tuple which will go away if the tuple does';

CREATE OR REPLACE
FUNCTION handle_meta_table_(regclass, meta_columns[])
RETURNS meta_tables AS $$
	SELECT meta_table(
			handle_table_name_($1),
			meta_column('handle', 'handles', _not_null := true)
			|| $2,			-- column order matters for set function
			_primary := meta_cols_primary_key($2),
			_uniques := ARRAY[ index_constraint(
				NULL::text, ARRAY['handle']::column_name_arrays
			) ],
			_forns := ARRAY[same_forn_keys_cascade($1, $2)],
			_ := 'row handles associated with ' || $1::text || ' rows'
	)
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION create_handle_table_for(regclass, meta_columns[])
RETURNS regclass AS $$
	SELECT create_table( handle_meta_table_($1, $2) )
$$ LANGUAGE SQL;

-- ** set function requires two auxiliary functions

CREATE OR REPLACE
FUNCTION row_setter_get_meta_func_(regclass, meta_columns[])
RETURNS meta_funcs AS $$
	SELECT meta_sql_func(
		_name := row_setter_get_name_($1),
		_args :=
			meta_arg('handles', 'handle') || meta_cols_meta_arg_array($2),
		_returns := reg_class_type($1),
		_strict := 'meta__strict',	-- ???
		_body := 'SELECT ' || $1::text || E'.*\n'
			|| ' FROM '|| $1::text || ',' || htab
			|| E'\nWHERE\n'
			|| and_equate_cols_args(
				meta_column('handle', 'handles') || $2, htab
			)
			|| E'\nAND\n'
			|| and_equate_cols_args($2, $1::text, 1),
		_ :=
			'find existing handle for row of ' || $1::text || '; do not call directly'
	) FROM handle_table_name_($1) htab
$$ LANGUAGE sql;
COMMENT ON
FUNCTION row_setter_get_meta_func_(regclass, meta_columns[])
IS 'creates function which tries to get existing row';

CREATE OR REPLACE
FUNCTION row_setter_set_meta_func_(regclass, meta_columns[])
RETURNS meta_funcs AS $$
	SELECT meta_sql_func(
		_name := row_setter_set_name_($1),
		_args :=
			meta_arg('handles', 'handle') || meta_cols_meta_arg_array($2),
		_returns := reg_class_type($1),
		_strict := 'meta__strict',	-- ???
		_body := meta_func_body(
			'INSERT INTO ' || handle_table_name_($1) || ' VALUES ' || body,
			'SELECT ' || row_setter_get_name_($1) || body
		),
		_ :=
			'make new handle for row of ' || $1::text || '; do not call directly'
	) FROM list_texts(
			list_args( meta_column('handle', 'handles') || $2 )
	) body
$$ LANGUAGE sql;
COMMENT ON
FUNCTION row_setter_set_meta_func_(regclass, meta_columns[])
IS 'creates non-idempotent setter function';

CREATE OR REPLACE
FUNCTION row_setter_meta_func_(regclass, meta_columns[])
RETURNS meta_funcs AS $$
	SELECT (
		SELECT meta_sql_func(
			_name := row_setter_name_($1),
			_args := args,
			_returns := reg_class_type($1),
			_strict := 'meta__strict',	-- ???
			_body := in_call_text('  ', 'SELECT COALESCE',
				row_setter_get_name_($1) || body,
				row_setter_set_name_($1) || body
			) || in_call_text(
				' ',
				'FROM debug_enter',
quote_literal( meta_func_head_text( row_setter_name_($1), args ) ) || '::regprocedure',
				'$2', '$1'
		),
		_ :=
'ensure handle for row of ' || $1::text || ' given the primary field values'
		)
		FROM list_texts(
			list_args( meta_column('handle', 'handles') || $2 )
		) body
	) FROM array_prepend(
			meta_arg('handles', 'handle'), meta_cols_meta_arg_array($2)
	) args
$$ LANGUAGE sql;
COMMENT ON
FUNCTION row_setter_meta_func_(regclass, meta_columns[])
IS 'creates idempotent setter function';

CREATE OR REPLACE
FUNCTION create_row_setter_get_(regclass, meta_columns[])
RETURNS regprocedure AS $$
	SELECT create_func(row_setter_get_meta_func_($1, $2));
	SELECT create_func(row_setter_set_meta_func_($1, $2));
	SELECT create_func(row_setter_meta_func_($1, $2))
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION row_getter_meta_func_(regclass, meta_columns[])
RETURNS meta_funcs AS $$
	SELECT meta_sql_func(
		_name := row_getter_name_($1),
		_args := ARRAY[ handle_arg ],
		_returns := reg_class_type($1),
		_strict := 'meta__strict',	-- ???
		_body :=
			'SELECT ' || $1::text  ||  E'.*\n  FROM '
				|| $1::text || ', ' || handles_table::text
				|| E'\n  WHERE $1 = '
				|| class_field_text(handles_table, handle_col)
				|| E'\n    AND ' || equate_class_fields($1, handles_table, $2),
		_ := 'return a row given a handle for ' || $1::text
	) FROM
		CAST(handle_table_name_($1) AS regclass) handles_table,
		meta_column('handle', 'handles') handle_col,
		meta_arg('handles', 'handle') handle_arg
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION create_row_getter(regclass, meta_columns[])
RETURNS regprocedure AS $$
	SELECT create_func(row_getter_meta_func_($1, $2))
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION default_handle_getter_meta_func_(regclass, meta_columns[])
RETURNS meta_funcs AS $$
	SELECT meta_sql_func(
		_name := default_handle_getter_name_($1),
		_args := meta_cols_meta_arg_array($2),
		_returns := 'text',
		_strict := 'meta__strict',	-- ???
		_body :=
			'SELECT ' || array_to_string(
				ARRAY(
SELECT quote_literal(n || '=') || ' || ($' || i::text || ')::text'
FROM array_to_set(from_column_name_array(meta_cols_name_array($2))) AS (i integer, n text)
				),
				'|| '';'' ||'
			)
			|| E'\nFROM ' || $1::text
			|| E'\nWHERE ' || and_equate_cols_args($2),
		_ :=
			'returns a default row handle (textual primary key) for '
			|| $1::text || ' as text'
	)
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION create_default_handle_getter(regclass, meta_columns[])
RETURNS regprocedure AS $$
	SELECT create_func(default_handle_getter_meta_func_($1, $2))
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION handle_getter_meta_func_(
	regclass, meta_columns[]
) RETURNS meta_funcs AS $$
	SELECT meta_sql_func(
		_name := handle_getter_name_($1),
		_args := meta_cols_meta_arg_array($2),
		_returns := 'text',
		_strict := 'meta__strict',	-- ???
		_body := in_call_text('  ', 'SELECT COALESCE',
			'(SELECT handle FROM ' || handle_table_name_($1)
			|| ' WHERE ' || and_equate_cols_args($2) || ')',
			call_texts( default_handle_getter_name_($1), list_args($2) )
		)
	)
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION create_handle_getter(regclass, meta_columns[])
RETURNS regprocedure AS $$
	SELECT create_func(handle_getter_meta_func_($1, $2))
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION field_getter_meta_func_(regclass, meta_columns)
RETURNS meta_funcs AS $$
	SELECT meta_sql_func(
		_name := table_field_name_($1, $2),
		_args := ARRAY[ meta_arg('handles', 'handle') ],
		_returns := ($2).type_,
		_strict := 'meta__strict',	-- ???
		_body :=
			'SELECT ' || ($2).name_
				|| ' FROM ' || handle_table_name_($1)
				|| ' WHERE handle = $1',
		_ :=
			'given a row handle for ' || $1::text || ' return primary key'
	)
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION field_setter_meta_func_(regclass, meta_columns)
RETURNS meta_funcs AS $$
	SELECT meta_sql_func(
		_name := table_field_name_($1, $2),
		_args :=
			ARRAY[ meta_arg('handles', 'handle'), meta_col_meta_arg($2) ],
		_returns := ($2).type_,
		_strict := 'meta__strict',	-- ???
		_body :=
			'SELECT (' || row_setter_name_($1) || body || ').' || ($2).name_,
		_ :=
			'set handle for primary key of ' || $1::text || ' and return key'
	) FROM list_texts(
		list_args( ARRAY[meta_column('handle', 'handles'), $2] )
	) body
$$ LANGUAGE sql;

-- * Now wrap it up into some handy omnibus functions

DROP TYPE IF EXISTS tables_procs CASCADE;

CREATE TYPE tables_procs AS (
	tables regclass[],
	procs regprocedure[]
);

CREATE OR REPLACE
FUNCTION create_handles_for(regclass) RETURNS tables_procs AS $$
	SELECT
		ARRAY[ create_handle_table_for($1, colms) ],
		ARRAY[
	create_row_setter_get_($1, colms),
	create_row_getter($1, colms)
		] || CASE WHEN array_length(colms) <> 1
		THEN '{}'::regprocedure[]
		ELSE
			ARRAY[
				create_func( field_getter_meta_func_($1, colms[1]) ),
				create_func( field_setter_meta_func_($1, colms[1]) )
			 ]
		END
	FROM primary_meta_column_array($1) colms
$$ LANGUAGE SQL;
COMMENT ON FUNCTION create_handles_for(regclass) IS
'Creates an associated row_handles table with 2 service functions.';

CREATE OR REPLACE
FUNCTION create_handles_plus_for(regclass) RETURNS tables_procs AS $$
	SELECT
		ARRAY[ create_handle_table_for($1, colms) ],
		ARRAY[
			create_row_setter_get_($1, colms),
			create_row_getter($1, colms),
			create_default_handle_getter($1, colms),
			create_handle_getter($1, colms)
		] || CASE WHEN array_length(colms) <> 1
		THEN '{}'::regprocedure[]
		ELSE
			ARRAY[
				create_func( field_getter_meta_func_($1, colms[1]) ),
				create_func( field_setter_meta_func_($1, colms[1]) )
			]
		END
	FROM primary_meta_column_array($1) colms
$$ LANGUAGE SQL;
COMMENT ON FUNCTION create_handles_plus_for(regclass) IS
'Creates an associated row_handles table with 4 service functions.';


-- * old stuff that may live again someday

-- CREATE OR REPLACE
-- FUNCTION show(regclass) RETURNS text AS $$
--   SELECT
--     meta_func_text( create_meta_func_set_set_handle_for($1, colms) )
--   FROM primary_meta_column_array($1) colms
-- $$ LANGUAGE SQL;

-- CREATE OR REPLACE
-- FUNCTION create_funcs_handle_fields_for(regclass, meta_columns[])
-- RETURNS SETOF regprocedure AS $$
--   SELECT create_func(
--     field_getter_meta_func_($1, c),
--     'given a row handle for ' || $1::text || ' return value of field ' || c
--   )
--   FROM unnest($2) c
-- $$ LANGUAGE SQL;


-- CREATE OR REPLACE
-- FUNCTION create_old_handles_for(regclass) RETURNS tables_procs AS $$
--   SELECT
--     ARRAY[ create_handle_table_for($1, colms) ],
--     ARRAY[ create_row_setter_get_($1, colms) ]
--     || ARRAY( SELECT proc FROM create_funcs_handle_fields_for($1, colms) proc )
--     || ARRAY[
-- 	 create_default_handle_getter($1, colms),
--   	 create_handle_getter($1, colms)
--     ]
--   FROM primary_meta_column_array($1) colms
-- $$ LANGUAGE SQL;

-- CREATE OR REPLACE
-- FUNCTION create_field_handles_for(regclass, VARIADIC TEXT[])
-- RETURNS regclass AS $$
--   SELECT $1
-- $$ LANGUAGE SQL;
-- COMMENT ON FUNCTION create_field_handles_for(regclass, TEXT[]) IS
-- 'Creates handles functions using the columns $1.$2.  The functions
-- work the same as if there were an associated row_handles table.
-- NOTE: This is just a dummy - this code has not yet been written!';
