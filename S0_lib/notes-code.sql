-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('notes-code.sql', '$Id');

--	PostgreSQL Utilities Attributed Notes Code And Metacode

-- ** Copyright

--	Copyright (c) 2005, 2006, J. Greg Davidson.
--	This code may be freely used by CreditLink Corporation
--	for their internal business needs but not redistributed
--	to third parties.

-- ** Depends

-- SELECT require_module('modules-code');

-- ** Attributed Notes Associated With Table Rows

-- This module provides machinery for managing a table of
-- timestamped and attributed notes and associating them
-- with a row of any table type.  The association mechanism
-- is very similar to that used in handles.

-- For example, given:
--	TABLE my_table(
--	  x x_types,
--	  y y_types,
--	  PRIMARY KEY(x, y),
--	  .. other fields of my_table
--	)
-- SELECT create_notes_for('my_table');
-- will create:
--  TABLE my_table_row_notes (
--    x x_types,
--    y y_types,
--    PRIMARY KEY(x, y),
--    FOREIGN KEY(x, y) REFERENCES my_table(x, y) ?? ON DELETE CASCADE ?? ,
--    note_id attributed_note_ids REFERENCES attributed_notes
--  );
--  FUNCTION add_my_table_note(attributed_note_ids, x_types, y_types)
--  FUNCTION del_my_table_note(attributed_note_ids, x_types, y_types)
--  FUNCTION my_table_notes_set(x_types, y_types) RETURNS SETOF attributed_note_ids
--  FUNCTION my_table_notes_array(x_types, y_types) RETURNS attributed_notes[]

-- Proposed new features:
--  TYPE my_table_primary_keys AS ( ... )  - just the primary fields of my_table
--  FUNCTION find_my_table_with_note AS (attributed_note_ids)
--	RETURNS SETOF my_table_primary_keys

-- ** These functions create the above naming conventions:

CREATE OR REPLACE
FUNCTION notes_table_name_(regclass) RETURNS text AS $$
	SELECT $1::text || '_row_notes'
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE
FUNCTION notes_add_func_name_(regclass) RETURNS text AS $$
	SELECT 'add_' || $1::text || '_note'
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE
FUNCTION notes_del_func_name_(regclass) RETURNS text AS $$
	SELECT 'del_' || $1::text || '_note'
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE
FUNCTION notes_set_func_name_(regclass) RETURNS text AS $$
	SELECT $1::text || '_notes_set'
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE
FUNCTION notes_array_func_name_(regclass) RETURNS text AS $$
	SELECT $1::text || '_notes_array'
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE		-- not in use yet
FUNCTION notes_find_func_name_(regclass) RETURNS text AS $$
	SELECT 'find_' || $1::text || '_with_note'
$$ LANGUAGE SQL IMMUTABLE;

-- attributed_notes service functions

CREATE OR REPLACE FUNCTION new_attributed_note(
	attributed_note_ids, event_times, note_author_ids, xml, note_feature_sets
) RETURNS attributed_note_ids AS $$
	INSERT INTO attributed_notes(id, time_, author_id, note, features)
	VALUES($1, $2, $3, $4, $5);
	SELECT $1
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION make_attributed_note(note_author_ids, xml, note_feature_sets)
RETURNS attributed_note_ids AS $$
	SELECT new_attributed_note(
		next_attributed_note_id(), event_time(), $1, $2, $3
	)
$$ LANGUAGE SQL;
COMMENT ON FUNCTION make_attributed_note(note_author_ids, xml, note_feature_sets)
IS 'makes a new attributed_notes instance';

CREATE OR REPLACE
FUNCTION make_attributed_note(text, xml) RETURNS attributed_note_ids AS $$
	SELECT make_attributed_note(note_authors_id($1), $2, empty_bitset())
$$ LANGUAGE SQL;
COMMENT ON FUNCTION make_attributed_note(text, xml)
IS '(note_authors.name, note) convenience function';

CREATE OR REPLACE
FUNCTION attributed_note_time_text(event_times) RETURNS text AS $$
	SELECT to_char ($1,  'YYYY-MM-DD HH12:MIam')
$$ LANGUAGE SQL;
COMMENT ON FUNCTION attributed_note_time_text(event_times) IS 'attributed_notes.time_ to text';

CREATE OR REPLACE
FUNCTION attributed_note_text(attributed_note_ids) RETURNS text AS $$
	SELECT attributed_note_time_text(time_) || ' '
	|| get_note_authors_handle(author_id ) || E'\n'
	||  note::text
	FROM attributed_notes WHERE id = $1
$$ LANGUAGE SQL;
COMMENT ON FUNCTION attributed_note_text(attributed_note_ids)
IS 'attributed_note_ids to lines of text';

CREATE OR REPLACE
FUNCTION attributed_notes_text(attributed_note_id_arrays) RETURNS text AS $$
	SELECT CASE
		WHEN array_is_empty(from_attributed_note_id_array($1)) THEN ''
		ELSE array_to_string(ARRAY(
			SELECT attributed_note_text(id::attributed_note_ids)
			FROM unnest(from_attributed_note_id_array($1)) id
		), E'\n')
	END
$$ LANGUAGE SQL;
COMMENT ON FUNCTION attributed_notes_text(attributed_note_id_arrays) IS
'attributed_note_id_arrays to groups of lines';

CREATE OR REPLACE
FUNCTION sort_notes_by_time(attributed_note_id_arrays)
RETURNS attributed_note_id_arrays AS $$
	SELECT ARRAY(
		SELECT id::integer FROM
			attributed_notes,
			unnest(from_attributed_note_id_array($1)) note_id
		WHERE id = note_id ORDER BY time_
	)::attributed_note_id_arrays
$$ LANGUAGE SQL;

-- ** Attributed Notes Features

CREATE OR REPLACE
FUNCTION try_note_feature(text) RETURNS note_feature_ids AS $$
	SELECT id FROM note_features WHERE name = $1
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE
FUNCTION note_feature(text) RETURNS note_feature_ids AS $$
	SELECT non_null( try_note_feature($1), 'note_feature(text)' )
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION note_feature_set(text[]) RETURNS note_feature_sets AS $$
	SELECT to_bitset(ARRAY(
		SELECT note_feature(feat)::integer
		FROM unnest($1) feat
	))::note_feature_sets
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION in_note_feature_set(note_feature_ids, note_feature_sets)
RETURNS boolean AS $$
	SELECT in_bitset($1, $2)
--  SELECT in_bitset($1::integer, $2::bitsets)
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION note_feature_set_text(note_feature_sets) RETURNS text[] AS $$
	SELECT ARRAY(
		SELECT name FROM note_features WHERE in_note_feature_set(id, $1)
	)
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION get_note_feature_set(attributed_note_ids)
RETURNS note_feature_sets AS $$
	SELECT features FROM attributed_notes WHERE id = $1
$$ LANGUAGE sql;

-- * Associating notes with rows: the meta-functions

CREATE OR REPLACE
FUNCTION meta_notes_table_for(regclass, meta_columns[]) RETURNS meta_tables AS $$
	SELECT meta_table(
			notes_table_name_($1),
			the_cols,			-- column order matters for add_note function
			_uniques := ARRAY[ index_constraint(
				NULL::text, meta_cols_name_array(the_cols)
			) ],
			_forns := ARRAY[same_forn_keys_cascade($1, $2)],
			_ := 'note ids associated with ' || $1::text || ' rows'
	)
	FROM COALESCE( meta_column('note_id', 'attributed_note_ids') || $2) the_cols
$$ LANGUAGE SQL;

-- WHAT ABOUT UNIQUENESS OF NOTE IDS?

CREATE OR REPLACE
FUNCTION create_notes_table_for(regclass, meta_columns[]) RETURNS regclass AS $$
	SELECT create_table( meta_notes_table_for($1, $2) )
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION meta_func_add_note_for(regclass, meta_columns[])
RETURNS meta_funcs AS $$
	SELECT meta_sql_func(
		_name := notes_add_func_name_($1),
		_args := meta_arg('attributed_note_ids', 'note_id')
			|| meta_cols_meta_arg_array($2),
		_returns := 'attributed_note_ids',
		_strict := 'meta__strict',	-- ???
		_body :=
			'INSERT INTO ' || notes_table_name_($1) || ' VALUES '
			|| list_texts(
					list_args( meta_column('note_id', 'attributed_note_ids') || $2 )
			)
			|| ' RETURNING note_id',
		_ :=
			'create note for row of ' || $1::text || ' given the primary field values'
	)
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION create_func_add_note_for(regclass, meta_columns[])
RETURNS regprocedure AS $$
	SELECT create_func( meta_func_add_note_for($1, $2) )
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION meta_func_del_note_for(regclass, meta_columns[])
RETURNS meta_funcs AS $$
	SELECT meta_sql_func(
		_name := notes_del_func_name_($1),
		_args := meta_arg('attributed_note_ids', 'note_id')
			|| meta_cols_meta_arg_array($2),
		_strict := 'meta__strict',						-- ???	-- ???
		_body :=
			'DELETE FROM ' || notes_table_name_($1) || ' WHERE '
				|| and_equate_cols_args(
					meta_column('note_id', 'attributed_note_ids') || $2
				),
		_ :=
			'delete note for row of ' || $1::text || ' given the primary field values'
	)
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION create_func_del_note_for(regclass, meta_columns[])
RETURNS regprocedure AS $$
	SELECT create_func( meta_func_del_note_for($1, $2) )
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION meta_func_note_set_for(regclass, meta_columns[])
RETURNS meta_funcs AS $$
	SELECT meta_sql_func(
		_name := notes_set_func_name_($1),
		_args := meta_cols_meta_arg_array($2),
		_returns := 'attributed_note_ids',
		_strict := 'meta__strict',	-- ???
		_body :=
			'SELECT note_id FROM ' || notes_table_name_($1)
			|| E'\nWHERE ' || and_equate_cols_args($2),
		_ := 
			'return SETOF notes for a row of ' || $1::text
			|| ' given the primary field values'
	)
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION create_func_note_set_for(regclass, meta_columns[])
RETURNS regprocedure AS $$
	SELECT create_func( meta_func_note_set_for($1, $2) )
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION meta_func_note_array_for(regclass, meta_columns[])
RETURNS meta_funcs AS $$
	SELECT meta_sql_func(
		_name := notes_array_func_name_($1),
		_args := args,
		_returns := 'attributed_note_id_arrays',
		_body :=
			E'SELECT sort_notes_by_time( ARRAY(\n'
				'  SELECT id::integer FROM '
				|| call_texts( notes_set_func_name_($1), list_args(args) )
				|| E' id\n' ||
			')::attributed_note_id_arrays )',
		_ :=
			'return array of notes for a row of ' || $1::text
			|| ' given the primary field values'
	)
	FROM meta_cols_meta_arg_array($2) args
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION create_func_note_array_for(regclass, meta_columns[])
RETURNS regprocedure AS $$
	SELECT create_func( meta_func_note_array_for($1, $2) )
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION try_create_notes_for(regclass)  RETURNS tables_procs AS $$
	SELECT
		ARRAY[ create_notes_table_for($1, colms) ],
		ARRAY[ create_func_add_note_for($1, colms),
		 create_func_del_note_for($1, colms),
		 create_func_note_set_for($1, colms),
		 create_func_note_array_for($1, colms)
		]
	FROM primary_meta_column_array($1) colms
$$ LANGUAGE SQL STRICT;

CREATE OR REPLACE
FUNCTION create_notes_for(regclass) RETURNS tables_procs AS $$
	SELECT non_null(
		try_create_notes_for($1),
		'create_notes_for(regclass)'
	)
$$ LANGUAGE SQL;
COMMENT ON FUNCTION create_notes_for(regclass) IS
'Creates an associated row_notes table with service functions.';

-- * Provides

-- SELECT require_procedure('notes_on(regclass, integer)');
-- SELECT require_procedure('note_on(regclass, integer, note_author_ids, text)');
-- SELECT require_procedure('note_on(regclass, integer, text, text)');
