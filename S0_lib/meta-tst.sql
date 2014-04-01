-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('meta-tst.sql', '$Id');

--	PostgreSQL Metaprogramming Utilities Code

-- ** Copyright

--	Copyright (c) 2005, 2006, J. Greg Davidson.
--	This code may be freely used by CreditLink Corporation
--	for their internal business needs but not redistributed
--	to third parties.

-- ** Depends

-- SELECT require_module('utilities_meta_schema');

-- * creating functions

SELECT test_func(
	'arg_text(meta_args, bool)',
	arg_text( meta_arg('text', 'name'), true ),
	'name text'
);

SELECT test_func(
	'arg_text(meta_args, bool)',
	arg_text( meta_arg('text', 'name'), false ),
	'text'
);

SELECT test_func(
	'arg_text(meta_args, bool)',
	arg_text( meta_arg('integer','code', _mode := 'meta__out'), true ),
	'OUT code integer'
 );

SELECT test_func(
	'arg_text(meta_args, bool)',
	arg_text( meta_arg('integer','code',_mode := 'meta__out'), false ),
	'OUT integer'
);

SELECT test_func_tokens(
	'meta_func_head_text(text, meta_args[], bool)',
	meta_func_head_text(
	'meta_func_head_text',
	 ARRAY[
		 meta_arg('text', 'name'),
		 meta_arg('meta_args[]', 'args'),
		 meta_arg('bool', 'show arg names')
	 ], 
	 true
	),
	'meta_func_head_text(name text, args meta_args[], show arg names boolean)'
);

SELECT test_func_tokens(
	'meta_func_head_text(text, meta_args[], bool)',
	meta_func_head_text(
	'meta_func_head_text',
	 ARRAY[
		 meta_arg('text', 'name'),
		 meta_arg('meta_args[]', 'args'),
		 meta_arg('bool', 'show_arg_names')
	 ], 
	 false
	),
	'meta_func_head_text(text, meta_args[], boolean)'
);


SELECT test_func_tokens(
	'func_head_comment_text(regproc, meta_args[])',
	func_head_comment_text(
		'func_head_comment_text', 
		 ARRAY[
			 meta_arg('regproc', 'name'), meta_arg('meta_args[]', 'args')
		 ]
 ),
 'func_head_comment_text(name, args)'
);

SELECT test_func_tokens(
	'func_head_comment_text(regproc, meta_args[])',
	func_head_comment_text(
		'func_head_comment_text',
		 ARRAY[
			 meta_arg('text', 'func_name'),
			 meta_arg('meta_args[]', 'arg_descriptions'),
			 meta_arg('bool', 'show_arg_names')
		 ]
	),
	'func_head_comment_text(func_name, arg_descriptions, show_arg_names)'
);

SELECT meta_sql_func(
	_name := 'test_func_tokens',
	_args := ARRAY[
		meta_arg('text', 'name'),
		meta_arg('regtype', 'return_type'),
		meta_arg('meta_args[]', 'args'),
		meta_arg('text', 'comment'),
		meta_arg('meta_langs', 'lang'),
		meta_arg('text', 'body')
	],
	_stability := 'meta__stable',
	_strict := 'meta__strict',
	_body := $$ SELECT 'hello world!' $$
);

SELECT test_func_tokens(
	'meta_func_text(meta_funcs)',
	meta_func_text(
		meta_sql_func(
			_name := 'test_func_tokens',
			_args := ARRAY[
				meta_arg('text', 'name'),
				meta_arg('regtype', 'return_type'),
				meta_arg('meta_args[]', 'args'),
				meta_arg('text', 'comment'),
				meta_arg('meta_langs', 'lang'),
				meta_arg('text', 'body')
			],
			_stability := 'meta__stable',
			_strict := 'meta__strict',	-- ???
			_body := $$ SELECT 'hello world!' $$
		)
	),
	$$CREATE  OR REPLACE
FUNCTION test_func_tokens(
name text, return_type regtype, args meta_args[], comment text, lang meta_langs, body text
)
RETURNS void LANGUAGE SQL STABLE STRICT AS
' SELECT ''hello world!'' ';
$$
);

SELECT
	meta_func_text(
		meta_sql_func(
			_name := 'test_func_tokens',
			_args := ARRAY[
				meta_arg('text', 'name'),
				meta_arg('regtype', 'return_type'),
				meta_arg('meta_args[]', 'args'),
				meta_arg('text', 'comment'),
				meta_arg('meta_langs', 'lang'),
				meta_arg('text', 'body')
			],
			_strict := 'meta__strict',	-- ???
			_body := $$ SELECT 'hello world!' $$
		)
	);

SELECT test_func_tokens(
	'meta_func_text(meta_funcs)',
	meta_func_text(
		meta_sql_func(
			_name := 'test_func_tokens',
			_args := ARRAY[
				meta_arg('text', 'name'),
				meta_arg('regtype', 'return_type'),
				meta_arg('meta_args[]', 'args'),
				meta_arg('text', 'comment'),
				meta_arg('meta_langs', 'lang'),
				meta_arg('text', 'body')
			],
			_strict := 'meta__strict',	-- ???
			_body := $$ SELECT 'hello world!' $$
		)
	),
$$CREATE  OR REPLACE
FUNCTION test_func_tokens(
name text, return_type regtype, args meta_args[], comment text, lang meta_langs, body text
)
RETURNS void LANGUAGE SQL STRICT AS
' SELECT ''hello world!'' ';
$$
);

SELECT func_comment_text(
	'func_comment_text(regprocedure, meta_args[], text)',
	ARRAY[
		 meta_arg('regprocedure', 'func'),
		 meta_arg('meta_args[]', 'args'),
		 meta_arg('text', 'comment')
	 ],
 'generate a nice comment for a function'
);

CREATE OR REPLACE
FUNCTION greet(name text) RETURNS TEXT AS $$
	SELECT 'Hello ' || $1 || ', how do you do?'
$$ LANGUAGE SQL;

DROP FUNCTION greet(name text);

SELECT test_func_tokens(
	'meta_func_text(meta_funcs)',
	meta_func_text(
		meta_sql_func(
			_name := 'greet',
			_args := ARRAY[meta_arg('text', 'name')],
			_returns := 'text',
			_strict := 'meta__strict',	-- ???
			_body := $$ SELECT 'Hello ' || $1 || ', how do you do?' $$
		)
	),
	$$CREATE  OR REPLACE
FUNCTION greet(name text)
RETURNS text LANGUAGE SQL STRICT AS
' SELECT ''Hello '' || $1 || '', how do you do?'' ';
$$
);

SELECT create_func(
	_name := 'greet',
	_args := ARRAY[meta_arg('text', 'name')],
	_returns := 'text',
	_strict := 'meta__strict',	-- ???
	_body := $$ SELECT 'Hello ' || $1 || ', how do you do?' $$,
	_ := 'greet someone nicely'
);

SELECT greet('Lynn');

-- * creating tables

SELECT test_func_tokens(
	'column_name_array_text(column_name_arrays)',
	column_name_array_text(ARRAY['foo', 'bar']::column_name_arrays),
	'(foo, bar)'
);

SELECT test_func(
	'is_table_constraint(abstract_constraints)',
	is_table_constraint(
		ROW(
			'constraint_name',
			ARRAY['foo', 'bar']::column_name_arrays,
			constraint_deferring()
		)::abstract_constraints
	),
	true
);

SELECT test_func(
	'is_column_constraint(column_names, abstract_constraints)',
	is_column_constraint(
		'foo',
		ROW(
			'constraint_name',
			ARRAY['foo', 'bar']::column_name_arrays,
			constraint_deferring()
		)::abstract_constraints
	),
	false
);

SELECT test_func(
	'is_column_constraint(column_names, abstract_constraints)',
	is_column_constraint(
		'foo',
		ROW(
			'constraint_name',
			ARRAY['foo']::column_name_arrays,
			constraint_deferring()
		)::abstract_constraints
	),
	false
);

SELECT test_func(
	'is_column_constraint(column_names, abstract_constraints)',
	is_column_constraint(
		'foo',
		ROW(
			NULL::text,
			ARRAY['foo']::column_name_arrays,
			constraint_deferring()
		)::abstract_constraints
	),
	true
);

SELECT test_func_tokens(
	'check_constraint(
		text, column_name_arrays, constraint_deferrings, maybe_sql_exprs
	)',
	check_constraint_text(
		check_constraint(
			'constraint_name',
			ARRAY['foo', 'bar']::column_name_arrays,
			constraint_deferring(),
			'foo > bar'
	)  ),
	'CONSTRAINT constraint_name CHECK(foo > bar)'
);


SELECT
	table_check_constraint_texts(ARRAY[
		check_constraint(
			'foo_bar_cnst',
			ARRAY['foo', 'bar']::column_name_arrays,
			constraint_deferring(),
			'foo > bar'
		),
		check_constraint(
			'foobar_cnst',
			ARRAY['foobar']::column_name_arrays,
			constraint_deferring(),
			'foobar > 0'
		),
		check_constraint(
			NULL::text,
			ARRAY['fubar']::column_name_arrays,
			constraint_deferring(),
			'foobar > 0'
		)
] );

-- looks like a bug in the PostgreSQL parser!
-- SELECT test_func(
--   'table_check_constraint_texts(check_constraints[])',
--   table_check_constraint_texts(ARRAY[
--     check_constraint(
--       'constraint_name',
--       ARRAY['foo', 'bar']::column_name_arrays,
--       constraint_deferring(),
--       'foo > bar'
--     ),
--     check_constraint(
--       'constraint_name',
--       ARRAY['foobar']::column_name_arrays,
--       constraint_deferring(),
--       'foobar > 0'
--     )
--   ] ),
--   'x'
-- );

SELECT
	try_column_checks_text(
		'foobar',
		ARRAY[
			check_constraint(
	'foo_bar_cnst',
	ARRAY['foo', 'bar']::column_name_arrays,
	constraint_deferring(),
	'foo > bar'
			),
			check_constraint(
	NULL::text,
	ARRAY['foobar']::column_name_arrays,
	constraint_deferring(),
	'foobar > 0'
			),
			check_constraint(
	'fubar_cnst',
	ARRAY['fubar']::column_name_arrays,
	constraint_deferring(),
	'fubar > 0'
			)
	]
);


SELECT test_func_tokens(
	'index_constraint_text(text, index_constraints)',
	index_constraint_text(
		'PRIMARY KEY',
		index_constraint(
			'foo_bar_cnst',
			ARRAY['foo', 'bar']::column_name_arrays,
			constraint_deferring()
		)
	),
	'CONSTRAINT foo_bar_cnst PRIMARY KEY(foo, bar)'
);

SELECT test_func_tokens(
	'index_constraint_text(text, index_constraints)',
	index_constraint_text(
		'PRIMARY KEY',
		index_constraint(
			NULL::text,
			ARRAY['foo', 'bar']::column_name_arrays,
			constraint_deferring()
		)
	),
	' PRIMARY KEY(foo, bar)'
);

SELECT test_func_tokens(
	'index_constraint_text(text, index_constraints)',
	index_constraint_text(
		'PRIMARY KEY',
		index_constraint(
			NULL::text,
			ARRAY['foobar']::column_name_arrays,
			constraint_deferring()
		)
	),
	' PRIMARY KEY(foobar)'
);

SELECT test_func_tokens(
	'try_column_primary_text(column_names, index_constraints)',
	try_column_primary_text(
		'foobar',
		index_constraint(
			NULL::text,
			ARRAY['foobar']::column_name_arrays,
			constraint_deferring()
		)
	),
	' PRIMARY KEY'
);

SELECT test_func_tokens(
	'try_column_unique_text(column_names, index_constraints[])',
	try_column_unique_text(
		'foobar',
		ARRAY[ index_constraint(
			NULL::text,
			ARRAY['foobar']::column_name_arrays,
			constraint_deferring()
		) ]
	),
	' UNIQUE'
);

SELECT
 test_func_tokens(
	'foreign_key_text(meta_foreign_keys)',
	foreign_key_text(
		meta_foreign_key(
			'foobar_entity_traits_ref',
			ARRAY['entity']::column_name_arrays,
			constraint_deferring(),
			'meta_entity_traits',
			ARRAY['entity']::column_name_arrays,
			foreign_key_matching(),
			foreign_key_action(),
			foreign_key_action()
		)
	),
	'CONSTRAINT foobar_entity_traits_ref FOREIGN KEY(entity) REFERENCES meta_entity_traits(entity)'
);

SELECT meta_column(
	'id', 'integer', '0', true, _ := 'Not the Freudian one!'
);

SELECT test_func_tokens(
	'meta_column_text(meta_columns)',
	meta_column_text(
		meta_column(
			'name', 'text', _ := 'it''s not the thing!'
		)
	),
	'name text'
);

SELECT primary_meta_column_array('meta_entity_traits');

/*
SELECT test_func_tokens(
	'comment_meta_column(regclass, meta_columns)',
	comment_meta_column(
		'meta_langs_names',
		meta_column('name', 'text', 'it''s not the thing!')
	),
	E'COLUMN meta_langs_names.name\n\tit''s not the thing!'
);
*/

SELECT
--  meta_column_texts(colms, tbl)
	ARRAY(
		SELECT meta_column_text(c)
		|| try_column_checks_text( (c).name_, (t).checks )
		|| try_column_primary_text( (c).name_, (t).primary_key )
		|| try_column_unique_text( (c).name_, (t).uniques )
		|| try_column_forn_key_text( (c).name_, (t).forn_keys )
		FROM unnest(
			ARRAY[
	meta_column(
		'name', 'text',
		_ := 'a PostgreSQL entity text name'
	)
			]
		) c
	)
FROM meta_table(
	'meta_entity_traits',
	ARRAY[
		meta_column(
			'name', 'text',
			_ := 'a PostgreSQL entity text name'
		)
	],
	_oids := true,
	_ := 'associates key properties with meta_entities'
) t;

-- meta_table(
--  text, meta_columns[], check_constraints[], index_constraints,
--  index_constraints[], meta_foreign_keys[], regclass[], boolean,
--  text
-- )
-- see TABLE meta_entity_traits in utility_meta_schema.sql
SELECT array_to_string(
	meta_column_texts(
			ARRAY[
	meta_column(
		'entity', 'meta_entities', _ := 'a PostgreSQL entity enum'
	),
	meta_column(
		'name', 'text', _ := 'a PostgreSQL entity text name'
	),
	meta_column(
		'commentable', 'boolean',
		_default := 'true', _not_null := true,
		_ := 'is this entity supported by PostgreSQL COMMENT ON'
	)
			],
		meta_table(
			'meta_entity_traits',
			ARRAY[
				meta_column(
					'entity', 'meta_entities', _ := 'a PostgreSQL entity enum'
				),
				meta_column(
					'name', 'text', 	_ := 'a PostgreSQL entity text name'
				),
				meta_column(
					'commentable', 'boolean',
					_default := 'true', _not_null := true,
					_ := 'is this entity supported by PostgreSQL COMMENT ON'
				)
			],
			NULL::check_constraints[],
			index_constraint(
				NULL::text,
				ARRAY['entity']::column_name_arrays
			),
			ARRAY[ index_constraint(
				NULL::text,
				ARRAY['name']::column_name_arrays
			) ],
			_oids := true,
			_ := 'associates key properties with meta_entities'
		)
	),
	E',\n'
);


SELECT test_func_tokens(
	'meta_table_text(meta_tables)',
	meta_table_text(
		meta_table(
			'id_name_pairs',
			ARRAY[
	meta_column('id', 'integer', 'next_pair_id()', false, 'Not Freudian!'),
	meta_column('name', 'text', NULL::text, true, 'it''s not the thing!')
			],
			NULL::check_constraints[],
			index_constraint(
				NULL::text, ARRAY['id']::column_name_arrays
			),
			ARRAY[ index_constraint(
				NULL::text, ARRAY['name']::column_name_arrays
			) ],
			_oids := true,
			_ := 'associates key properties with meta_entities'
		)
	),
$$CREATE TABLE id_name_pairs (
	id integer DEFAULT 'next_pair_id()' PRIMARY KEY,
	name text NOT NULL UNIQUE
) WITH OIDS;
$$
);

SELECT test_func(
	'primary_meta_column_array(regclass)',
	array_length( primary_meta_column_array('meta_entity_traits')),
	1
);

SELECT test_func_tokens(
	'get_primary_forn_keys(regclass)',
	foreign_key_text(get_primary_forn_keys('meta_entity_traits')),
	' FOREIGN KEY(entity) REFERENCES meta_entity_traits(entity)'
);

-- * meta_triggers

SELECT meta_trigger(
	'our_namespace_insert',
	'our_namespaces',
	'trigger__before',
	meta_trigger_on('trigger__insert'),
	'our_namespace_insert()',
	_per_row := 'true'
);

SELECT test_func_tokens(
	'meta_trigger_text(meta_triggers)',
	meta_trigger_text( meta_trigger),
	'CREATE TRIGGER our_namespace_insert' ||
	' before insert ON our_namespaces' ||
	' FOR EACH ROW EXECUTE PROCEDURE our_namespace_insert'
) FROM meta_trigger(
	'our_namespace_insert',
	'our_namespaces',
	'trigger__before',
	meta_trigger_on('trigger__insert'),
	'our_namespace_insert()',
	_per_row := 'true'
);

-- more tests, please!!
