-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('meta-ids.sql', '$Id');

--	PostgreSQL typed and segregated integer id 

-- ** Copyright

--	Copyright (c) 2005, 2006, J. Greg Davidson.
--	This code may be freely used by CreditLink Corporation
--	for their internal business needs but not redistributed
--	to third parties.

-- ** Depends

-- SELECT require_module('modules-schema-code');

-- This module provides machinery for attaching a convenience name
-- aka a handle, to a specific row of some table.  Much of the machinery
-- here requires that the primary key of the row be an integer.

-- For example, given:
--	TABLE my_table(
--	  x x_types,
--	  y y_types,
--	  PRIMARY KEY(x, y),
--	  .. other fields of my_table
--	)
-- SELECT handles_for('my_table');
-- will create:
--	TABLE my_table_row_handles (
--	  x x_types,
--	  y y_types,
--	  PRIMARY KEY(x, y),
--	  FOREIGN KEY(x, y) REFERENCES my_table(x, y) ON DELETE CASCADE,
--	  handle handles
--	);
--	TABLE my_table_row_handles ( ... )
--	FUNCTION set_my_table_row(handles, x_types, y_types) RETURNS my_table
--	FUNCTION my_table_x(handles) RETURNS x_types
--	FUNCTION my_table_y(handles) RETURNS y_types
--	FUNCTION my_table_row(handles) RETURNS my_table
--	FUNCTION my_table_default_handle(x_types, y_types) RETURNS handles
--	FUNCTION my_table_handle(x_types, y_types) RETURNS handles

-- Proposed new feature:
--	TYPE my_table_primary_keys AS ( ... )  - just the primary fields of my_table

-- These functions create these naming conventions:

CREATE OR REPLACE
FUNCTION handle_table_name_(regclass) RETURNS text AS $$
  SELECT $1::text || '_row_handles'
$$ LANGUAGE SQL STRICT IMMUTABLE;

CREATE OR REPLACE
FUNCTION keys_table_name_(regclass) RETURNS text AS $$
  SELECT $1::text || '_primary_keys'
$$ LANGUAGE SQL STRICT IMMUTABLE;

CREATE OR REPLACE
FUNCTION set_handle_name_(regclass) RETURNS text AS $$
  SELECT 'set_' || $1::text || '_row'
$$ LANGUAGE SQL STRICT IMMUTABLE;

CREATE OR REPLACE
FUNCTION get_handle_field_name_(regclass, meta_columns) RETURNS text AS $$
  SELECT $1::text || '_' || quote_ident(($2).name_)
$$ LANGUAGE SQL STRICT IMMUTABLE;

CREATE OR REPLACE
FUNCTION get_handle_row_name_(regclass) RETURNS text AS $$
  SELECT $1::text || '_row'
$$ LANGUAGE SQL STRICT IMMUTABLE;

CREATE OR REPLACE
FUNCTION default_handle_for_name_(regclass) RETURNS text AS $$
  SELECT $1::text || '_default_handle'
$$ LANGUAGE SQL STRICT IMMUTABLE;

CREATE OR REPLACE
FUNCTION get_handle_name_(regclass) RETURNS text AS $$
  SELECT 'get_' || $1::text || '_handle'
$$ LANGUAGE SQL STRICT IMMUTABLE;

-- Row Handles

CREATE DOMAIN handles AS text NOT NULL;
COMMENT ON DOMAIN handles IS
'a convenience name for a tuple which will go away if the tuple does';

CREATE OR REPLACE
FUNCTION meta_cols_same_forn_keys_cascade(regclass, meta_columns[])
RETURNS meta_foreign_keys AS $$
  SELECT meta_foreign_key(
    NULL::text,
    col_names,			-- our columns
    constraint_deferring(),
    $1,				-- the foreign table
    col_names,			-- the foreign columns
    foreign_key_matching(),
    'foreign_key_cascade_',	-- ON DELETE CASCADE
    foreign_key_action()
  ) FROM meta_cols_name_array($2) col_names
$$ LANGUAGE 'sql' STRICT;
COMMENT ON FUNCTION meta_cols_same_forn_keys_cascade(regclass, meta_columns[]) IS
'Turn the array of columns into a foreign key constraint where
the foreign keys and the local keys have the same name
and the ON DELETE action should be CASCADE';

CREATE OR REPLACE
FUNCTION meta_handle_table_for(regclass, meta_columns[]) RETURNS meta_tables AS $$
  SELECT meta_table(
      handle_table_name_($1),
      ARRAY[ meta_column('handle', 'handles', NULL::text, true, NULL::text) ]
      || $2,			-- column order matters for set function
      NULL::check_constraints[],
      meta_cols_primary_key($2),
      ARRAY[ index_constraint(
	  NULL::text,
	  ARRAY['handle']::column_name_arrays,
	  constraint_deferring()
      ) ],
      ARRAY[meta_cols_same_forn_keys_cascade($1, $2)],
      NULL::regclass[],
      false,
      'row handles associated with ' || $1::text || ' rows'
  )
$$ LANGUAGE SQL STRICT;

CREATE OR REPLACE
FUNCTION create_handle_table_for(regclass, meta_columns[]) RETURNS regclass AS $$
  SELECT create_table( meta_handle_table_for($1, $2) )
$$ LANGUAGE SQL STRICT;

CREATE OR REPLACE
FUNCTION meta_func_set_handle_for(regclass, meta_columns[]) RETURNS meta_funcs AS $$
  SELECT meta_func(
    true,
    set_handle_name_($1),
    ARRAY[ meta_arg('handle', 'handles') ]
    || meta_cols_meta_arg_array($2),
    handle_table_name_($1)::regtype,
    false,
    'meta_func_sql_',
    meta_func_stability(),
    true,
    ARRAY[
      'INSERT INTO ' || handle_table_name_($1) || ' VALUES ('
      || list_args_with_array( ARRAY[ meta_column('handle', 'handles') ] || $2 )
      || ')',
      'SELECT * FROM '|| handle_table_name_($1)||' WHERE $1 = handle'
    ]
  )
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE
FUNCTION create_func_set_handle_for(regclass, meta_columns[]) RETURNS regprocedure AS $$
  SELECT create_func(
    meta_func_set_handle_for($1, $2),
    'create handle for row of ' || $1::text || ' given the primary field values'
  )
$$ LANGUAGE SQL STRICT;

CREATE OR REPLACE
FUNCTION meta_func_handle_field_for(regclass, meta_columns) RETURNS meta_funcs AS $$
  SELECT meta_func(
    true,
    get_handle_field_name_($1, $2),
    ARRAY[ meta_arg('handle', 'handles') ],
    ($2).type_,
    false,
    'meta_func_sql_',
    meta_func_stability(),
    true,
    ARRAY[
      E'  SELECT non_null(\n'
      || E'  the_field,\n'
      || E'  ''meta_func_handle_field_for(regclass, meta_columns)''::regprocedure'
      || ', ' || quote_literal(($2).name_) || E'\n'
      || E') FROM (\n'
      || '  SELECT '
      || ($2).name_
      || ' FROM '
      || handle_table_name_($1)
      || E' WHERE handle = $1\n'
      || ') foo(the_field)'
    ]
  )
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE
FUNCTION create_funcs_handle_fields_for(regclass, meta_columns[])
RETURNS SETOF regprocedure AS $$
  SELECT create_func(
    meta_func_handle_field_for($1, c),
    'given a row handle for ' || $1::text || ' return value of field ' || c
  )
  FROM array_to_list($2) c
$$ LANGUAGE SQL STRICT;

CREATE OR REPLACE
FUNCTION meta_func_handle_row_for(regclass, meta_columns[]) RETURNS meta_funcs AS $$
  SELECT meta_func(
    true, 
    get_handle_row_name_($1),
    ARRAY[ handle_arg ],
    $1::text::regtype,
    false,
    'meta_func_sql_',
    meta_func_stability(),
    true,
    ARRAY[
	'SELECT * FROM '
	|| $1::text || ',' || handles_table::text
	|| ' WHERE $1 = ' || class_field_text(handles_table, handle_col)
	|| ' AND ' || equate_class_fields($1, handles_table, $2)
    ]
  ) FROM
    CAST(handle_table_name_($1) AS regclass) handles_table,
    meta_column('handle', 'handles') handle_col,
    meta_arg('handle', 'handles') handle_arg
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE
FUNCTION create_func_handle_row_for(regclass, meta_columns[]) RETURNS regprocedure AS $$
  SELECT create_func(
    meta_func_handle_row_for($1, $2),
    'return a row given a handle for ' || $1::text
  )
$$ LANGUAGE SQL STRICT;

CREATE OR REPLACE
FUNCTION meta_func_default_handle_for(regclass, meta_columns[]) RETURNS meta_funcs AS $$
  SELECT meta_func(
    true,
    default_handle_for_name_($1),
    meta_cols_meta_arg_array($2),
    'text',
    false,
    'meta_func_sql_',
    meta_func_stability(),
    true,
    ARRAY[
      'SELECT ' || array_to_string( ARRAY(
        SELECT quote_literal(n || '=') || ' || ($' || i::text || ')::text'
        FROM array_to_set(meta_cols_name_array($2)) AS (i integer, n text)
      ), '|| '';'' ||' )
      || E'\nFROM ' || $1::text
      || E'\nWHERE ' || equate_args_with_array($2)
    ]
  )
$$ LANGUAGE SQL STRICT;

CREATE OR REPLACE
FUNCTION create_func_default_handle_for(regclass, meta_columns[]) RETURNS regprocedure AS $$
  SELECT create_func(
    meta_func_default_handle_for($1, $2),
    'returns a default row handle (textual primary key) for ' || $1::text || ' as text'
  )
$$ LANGUAGE SQL STRICT;

CREATE OR REPLACE
FUNCTION meta_func_get_handle_for(regclass, meta_columns[]) RETURNS meta_funcs AS $$
  SELECT meta_func(
    true,
    get_handle_name_($1),
    meta_cols_meta_arg_array($2),
    'text',
    false,
    'meta_func_sql_',
    meta_func_stability(),
    true,
    ARRAY[
      E'SELECT COALESCE(\n  (SELECT handle FROM ' || handle_table_name_($1)
      || ' WHERE ' || equate_args_with_array($2)
      || E'),\n  '
      || default_handle_for_name_($1)
      || '(' || list_args_with_array($2) || E')\n)'
  ] )
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE
FUNCTION create_func_get_handle_for(regclass, meta_columns[]) RETURNS regprocedure AS $$
  SELECT create_func(
    meta_func_get_handle_for($1, $2),
    'return a row handle (textual primary key) for ' || $1::text || ' as text'
  )
$$ LANGUAGE SQL STRICT;

-- * Now wrap it up into a great omnibus function

CREATE TYPE tables_procs AS (
  tables regclass[],
  procs regprocedure[]
);

CREATE OR REPLACE
FUNCTION handles_for(regclass) RETURNS tables_procs AS $$
  SELECT
    ARRAY[ create_handle_table_for($1, colms) ],
    ARRAY[ create_func_set_handle_for($1, colms) ]
    || ARRAY( SELECT proc FROM create_funcs_handle_fields_for($1, colms) proc )
    || ARRAY[
	 create_func_default_handle_for($1, colms),
  	 create_func_get_handle_for($1, colms)
    ]
  FROM primary_meta_column_array($1) colms
$$ LANGUAGE SQL STRICT;
COMMENT ON FUNCTION handles_for(regclass) IS
'Creates an associated row_handles table with service functions.';


CREATE OR REPLACE
FUNCTION handles_for(regclass, column_names) RETURNS regclass AS $$
  SELECT $1
$$ LANGUAGE SQL STRICT;
COMMENT ON FUNCTION handles_for(regclass, column_names) IS
'Creates handles functions using the column $1.$2.  The functions
work the same as if there were an associated row_handles table.
NOTE: This is just a dummy - this code has not yet been written!';

