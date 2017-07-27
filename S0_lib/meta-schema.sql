-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('meta-schema.sql', '$Id');

--	PostgreSQL Metaprogramming Utilities Schema

--	Future Plans prefaced by "Wicci Next"

-- ** Copyright

--	Copyright (c) 2005, 2006, J. Greg Davidson.
--	This code may be freely used by CreditLink Corporation
--	for their internal business needs but not redistributed
--	to third parties.

-- ** Depends

-- SELECT require_module('modules-code');

-- This module provides machinery for creating PostgreSQL
-- entities from specifications.  Currently supports
-- CREATE OR REPLACE FUNCTION
-- and CREATE TABLE
-- with most features.

-- * creating comments

-- You can have a lot of different kinds of entities in a PostgreSQL
-- database, and you can attach comments to most of them.  For a list
-- of all the entities which can take comments, see the COMMENT ON
-- command in the PostgreSQL manual.

DROP TYPE IF EXISTS meta_entities CASCADE;

CREATE TYPE meta_entities AS ENUM (
	'meta__arg',
	'meta__cast',
	'meta__column',
	'meta__constraint',
	'meta__domain',
	'meta__function',
	'meta__operator_class',
	'meta__operator_family',
	'meta__operator',
	'meta__sequence',
	'meta__table',
	'meta__trigger',
	'meta__type',
	'meta__view'
);
COMMENT ON TYPE meta_entities IS
'an enumeration of PostgreSQL metaprogrammable entities';

-- To be able to generate comments automatically, we'll need to know
-- the proper name of each kind of entity.  It's possible that we may
-- want to use this table to hold additional traits for purposes other
-- than generating comments, so perhaps more columns will be added
-- later.  We might then want to add some of the PostgreSQL entities
-- which do not support comments, e.g. function arguments.  Looking
-- ahead, the commentable field will allow us to know if PostgreSQL
-- can store comments for the corresponding entity.

-- Wicci Next: Accept comments on all entities.
-- Store comments ourselves where PostgreSQL doesn't!!

CREATE TABLE IF NOT EXISTS meta_entity_traits (
	entity meta_entities PRIMARY KEY,
	name text UNIQUE,
	commentable bool NOT NULL DEFAULT true
);
COMMENT ON TABLE meta_entity_traits IS
'associates key properties with meta_entities';
COMMENT ON COLUMN meta_entity_traits.commentable IS
'is this entity supported by PostgreSQL COMMENT ON';

INSERT INTO meta_entity_traits(entity, name, commentable) VALUES
	( 'meta__arg', NULL, false );

INSERT INTO meta_entity_traits(entity, name) VALUES
	( 'meta__cast', 'CAST' ),
	( 'meta__column', 'COLUMN' ),
	( 'meta__constraint', 'CONSTRAINT' ),
	( 'meta__domain', 'DOMAIN' ),
	( 'meta__function', 'FUNCTION' ),
	( 'meta__operator_class', 'OPERATOR CLASS' ),
	( 'meta__operator_family', 'OPERATOR FAMILY' ),
	( 'meta__operator', 'OPERATOR' ),
	( 'meta__sequence', 'SEQUENCE' ),
	( 'meta__table', 'TABLE' ),
	( 'meta__type', 'TYPE' ),
	( 'meta__view', 'VIEW' );

-- * meta support

DROP DOMAIN IF EXISTS sql_exprs CASCADE;
DROP DOMAIN IF EXISTS maybe_sql_exprs CASCADE;

CREATE DOMAIN sql_exprs AS TEXT NOT NULL;
COMMENT ON DOMAIN sql_exprs IS
'an sql expression yielding a value';
CREATE DOMAIN maybe_sql_exprs AS TEXT;

-- Wicci Next:
-- Add fields from meta_columns
--   not_null boolean,
--   comment_ text
-- Get rid of
--   TABLE meta_args
--   TABLE meta_columns
-- and just use meta_colargs.
-- We want comments for everything
--   We should record them when PostgreSQL doesn't
-- We want to know if we should allow args to be null
--   We should check them when PostgreSQL doesn't
--   Interacts with whether function is strict!
-- Note that default field names exist
--   based on the ordinal position of the
--   column starting at 1.

CREATE TABLE IF NOT EXISTS meta_colargs (
	name_ text, -- NOT NULL,
	type_ regtype NOT NULL,
	default_ maybe_sql_exprs
	-- , comment_ text
);
COMMENT ON TABLE meta_colargs IS
'Base type for meta_args and meta_columns.';
COMMENT ON COLUMN meta_colargs.name_ IS
'Name of argument or column';
COMMENT ON COLUMN meta_colargs.name_ IS
'Can this be NULL???';
COMMENT ON COLUMN meta_colargs.default_ IS
'Optional default value for argument or column';

SELECT declare_abstract('meta_colargs');

-- * creating functions

-- ** function arguments

CREATE TYPE meta_argmodes AS ENUM (
	'meta__in',
	'meta__out',
	'meta__inout'
);

CREATE DOMAIN arg_names AS TEXT NOT NULL;
CREATE DOMAIN maybe_arg_names AS TEXT;
CREATE DOMAIN arg_name_arrays AS TEXT[] NOT NULL;

CREATE OR REPLACE
FUNCTION from_arg_name(arg_names) RETURNS text AS $$
	SELECT $1::text
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION from_arg_name_array(arg_name_arrays)
RETURNS text[] AS $$
	SELECT $1::text[]
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION to_arg_name_array(text[])
RETURNS arg_name_arrays AS $$
	SELECT $1::arg_name_arrays
$$ LANGUAGE sql;

-- Wicci Next: replace with meta_colargs

CREATE TABLE IF NOT EXISTS meta_args (
	mode_ meta_argmodes DEFAULT 'meta__in',
	variadic_ boolean DEFAULT false
) INHERITS (meta_colargs);

SELECT declare_abstract('meta_args');

-- ** individual function features

CREATE TYPE meta_func_stabilities AS ENUM (
	'meta__volatile',	-- the default
	'meta__stable',
	'meta__immutable'
);

CREATE FUNCTION meta_func_stability()
RETURNS meta_func_stabilities AS $$
	SELECT 'meta__volatile'::meta_func_stabilities
$$ LANGUAGE sql IMMUTABLE;

CREATE TYPE meta_func_stricts AS ENUM (
	'meta__strict',
	'meta__non_strict',
	'meta__strict2',				-- create strict try and non_strict non_null
	'meta__auto_strict' -- the default (strict iff func-name ~ /try_/)
);

CREATE FUNCTION meta_func_strict()
RETURNS meta_func_stricts AS $$
	SELECT 'meta__auto_strict'::meta_func_stricts
$$ LANGUAGE sql IMMUTABLE;

CREATE TYPE meta_func_securities AS ENUM (
	'meta__invoker',	-- the default
	'meta__definer',	-- PostgreSQL alternative
	'meta__ext_invoker', -- SAME AS 'meta__invoker' in pgsql <= 8.4
	'meta__ext_definer' -- SAME AS 'meta__definer' in pgsql <= 8.4
);

CREATE FUNCTION meta_func_security() RETURNS meta_func_securities AS $$
	SELECT 'meta__invoker'::meta_func_securities
$$ LANGUAGE sql IMMUTABLE;

CREATE TYPE meta_langs AS ENUM (
	'meta__sql',
	'meta__plpgsql',
	'meta__tcl',
	'meta__c'
);

/*
CREATE TABLE IF NOT EXISTS meta_langs_names (
	lang meta_langs PRIMARY KEY,
	name text UNIQUE NOT NULL,
	named_args bool NOT NULL
);

INSERT INTO meta_langs_names(lang, name, named_args)
VALUES
	( 'meta__sql', 'sql', false ),
	( 'meta__plpgsql', 'plpgsql', true ),
	( 'meta__tcl', 'tcl', false ), -- is this true ???
	( 'meta__c', 'c', false );	    -- is this true ???
*/

CREATE TYPE meta_func_set_vars AS (
--  var_name text NOT NULL,	-- reference a system table?
	var_name text,		-- reference a system table?
	var_val text			-- 'FROM LOCAL' is special here
);

CREATE DOMAIN meta_func_bodies AS text;

-- ** meta_funcs: putting it all together

CREATE TABLE IF NOT EXISTS meta_funcs (
	replace_ boolean NOT NULL default true,
	name_ text NOT NULL,
	args meta_args[] NOT NULL,
	returns_ regtype DEFAULT 'void',
	returns_set bool NOT NULL DEFAULT false,
	CHECK( NOT returns_set OR returns_ IS NOT NULL  ),
	lang meta_langs,
	stability meta_func_stabilities DEFAULT meta_func_stability(),
	strict_ meta_func_stricts DEFAULT meta_func_strict(),
	security_ meta_func_securities NOT NULL DEFAULT meta_func_security(),
	cost_ integer,
	rows_ integer,
	CHECK( rows_ IS NULL OR returns_set IS NOT NULL  ),
	set_vars meta_func_set_vars[],
	body meta_func_bodies,
	obj_file text,
	CHECK( obj_file IS NULL OR body IS NOT NULL  ),
	link_symbol text,
	CHECK( link_symbol IS NULL OR obj_file IS NOT NULL  ),
	comment_ text
);
COMMENT ON TABLE meta_funcs IS
'Probably just want a TYPE here, but then we couldn''t express all of
the constraints which hopefully PostgreSQL will eventually enforce for
types as it enforces for tables.  It would also be great to be able
to specify UNIQUE(name_, meta_args_types(args)).';

SELECT declare_abstract('meta_funcs');

-- * creating composite types and tables

CREATE DOMAIN table_spaces AS TEXT NOT NULL;
CREATE DOMAIN maybe_table_spaces AS TEXT;

CREATE DOMAIN column_names AS TEXT NOT NULL;
-- CREATE DOMAIN column_name_arrays AS TEXT[] NOT NULL;
-- NOT NULL constraint gave error:
-- ERROR:  23502: domain column_name_arrays does not allow null values
-- CONTEXT:  PL/pgSQL function "create_table" while storing call arguments into local variables
-- LOCATION:  domain_check_input, domains.c:128
CREATE DOMAIN column_name_arrays AS TEXT[];

CREATE OR REPLACE
FUNCTION from_column_name(column_names) RETURNS text AS $$
	SELECT $1::text
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION from_column_name_array(column_name_arrays)
RETURNS text[] AS $$
	SELECT $1::text[]
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION to_column_name_array(text[])
RETURNS column_name_arrays AS $$
	SELECT $1::column_name_arrays
$$ LANGUAGE sql;

-- ** constraints

CREATE TYPE constraint_deferrings AS ENUM (
	'meta__not_deferrable', -- the default
	'meta__immediate',      -- the default if DEFERRABLE
	'meta__deferred'
);
COMMENT ON TYPE constraint_deferrings IS
'is a constraint deferrable, and if so, how';

CREATE FUNCTION constraint_deferring() RETURNS constraint_deferrings AS $$
	SELECT 'meta__not_deferrable'::constraint_deferrings
$$ LANGUAGE sql IMMUTABLE;


CREATE TABLE IF NOT EXISTS abstract_constraints (
	cnst_name text,		-- optional constraint name
	cols column_name_arrays,	-- optional columns
	defer_ constraint_deferrings NOT NULL DEFAULT 'meta__not_deferrable'
);

CREATE DOMAIN check_constraint_exprs AS TEXT NOT NULL;
COMMENT ON DOMAIN check_constraint_exprs IS
'an expression yielding bool suitable as a check constraint';

SELECT declare_abstract('abstract_constraints');

CREATE TABLE IF NOT EXISTS check_constraints (
	check_ check_constraint_exprs NOT NULL
) INHERITS (abstract_constraints);

SELECT declare_abstract('check_constraints');

CREATE TYPE storage_vars_vals AS (
	var_name TEXT,		-- can I just ref a system table?
	var_val TEXT
);

CREATE TABLE IF NOT EXISTS index_constraints (
	withs storage_vars_vals[],
	space_ maybe_table_spaces
) INHERITS (abstract_constraints);

SELECT declare_abstract('index_constraints');

CREATE TYPE foreign_key_matchings AS ENUM (
	'meta__match_simple', -- the default
	'meta__match_full',
	'meta__match_partial'
);
COMMENT ON TYPE foreign_key_matchings IS
'matching strategies for foreign key constraints';

CREATE FUNCTION foreign_key_matching() RETURNS foreign_key_matchings AS $$
	SELECT 'meta__match_simple'::foreign_key_matchings
$$ LANGUAGE sql IMMUTABLE;


CREATE TYPE foreign_key_actions AS ENUM (
	'meta__error',	-- the default "NO ACTION"
	'meta__restrict',
	'meta__cascade',
	'meta__set_null',
	'meta__set_default'
);
COMMENT ON TYPE foreign_key_actions IS
'action to perform when foreign key is broken';

CREATE FUNCTION foreign_key_action() RETURNS foreign_key_actions AS $$
	SELECT 'meta__error'::foreign_key_actions
$$ LANGUAGE sql IMMUTABLE;

CREATE TABLE IF NOT EXISTS meta_foreign_keys (
	forn_table regclass NOT NULL,
	forn_cols column_name_arrays,
	matching foreign_key_matchings
		NOT NULL DEFAULT foreign_key_matching(),
	deleting foreign_key_actions
		NOT NULL DEFAULT foreign_key_action(),
	updating foreign_key_actions
		NOT NULL DEFAULT foreign_key_action()
) INHERITS (abstract_constraints);

SELECT declare_abstract('meta_foreign_keys');

-- ** TYPE meta_columns

-- Wicci Next: replace with meta_colargs

CREATE TABLE IF NOT EXISTS meta_columns (
	CHECK(name_ IS NOT NULL),
	not_null boolean,
	comment_ text
) INHERITS (meta_colargs);
COMMENT ON TABLE meta_columns IS
'describes a single row of a PostgreSQL table';

SELECT declare_abstract('meta_columns');

-- *** meta_temp_tables

CREATE TYPE meta_temp_tables AS ENUM (
	'meta__not_temp_table',	-- not a temp table
	'meta__preserve_rows',	-- temp table default
	'meta__delete_rows',
	'meta__drop'
);

-- ** meta_types

-- Wicci Next: Why not accept all the features of tables
-- for composite types?  In some cases we can generate
-- code to do the right thing even though PostgreSQL doesn't!!

CREATE TABLE IF NOT EXISTS meta_composite_types (
	name_ text NOT NULL PRIMARY KEY,
	cols meta_columns[] NOT NULL,
	comment_ text
);
COMMENT ON TABLE meta_composite_types IS
'A model for PostgreSQL composite types created along with
tables or created with "CREATE TYPE ... AS".  Currently
PostgreSQL types do not support all of the integrity
constraints which tables support.  Should such features be
added in later versions of PostgreSQL, they can simply be
moved from meta_tables to meta_composite_types.  Ironically
this table is being created just for its type, so that we
can use the richer featureset of tables to get the types we
want, e.g. inheritance.  Although better than what is
available for types, the constraint system for tables is
also too limited to allow the expression of all of the
needed constraints, e.g. requiring that the names of columns
in a meta_columns array be unique.  For this reason,
constructor functions should be provided for creating all
instances of types.';

SELECT declare_abstract('meta_composite_types');

-- ** meta_tables

CREATE TABLE IF NOT EXISTS meta_tables (
	checks check_constraints[],
	primary_key index_constraints,
	uniques index_constraints[],
	forn_keys meta_foreign_keys[],
	inherits_ regclass[],
	with_oids boolean NOT NULL default false,
	temp_ meta_temp_tables NOT NULL default 'meta__not_temp_table',
	space_ maybe_table_spaces,
	withs storage_vars_vals[]
-- currently unimplemented features:
--  likes meta_table_likes[],		-- a poor substitute for inherits?
--  local_ bool NOT NULL DEFAULT false,	-- does nothing in PostgreSQL
) INHERITS (meta_composite_types);
COMMENT ON TABLE meta_tables IS
'See the "COMMENT ON TABLE meta_composite_types".  Given the limitations
on table constraints it is essential to provide and use constructor
functions for all table insertions and mutator functions for all
table updates.';

SELECT declare_abstract('meta_tables');

-- ** meta_triggers

CREATE TYPE meta_trigger_types AS ENUM (
	'trigger__before',
	'trigger__after',
	'trigger__instead_of'
);

CREATE TYPE meta_trigger_ons AS ENUM (
	'trigger__insert',
	'trigger__update',
	'trigger__update_of',
	'trigger__delete',
	'trigger__truncate'
);

CREATE OR REPLACE FUNCTION meta_trigger_on(
	VARIADIC meta_trigger_ons[]
) RETURNS meta_trigger_ons[] AS $$
	SELECT $1
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION valid_trigger_on(meta_trigger_ons[])
RETURNS boolean AS $$
	SELECT array_length($1) > 0 AND
		ARRAY(SELECT x FROM unnest($1) x ORDER BY 1) = 
		ARRAY(SELECT DISTINCT x FROM unnest($1) x ORDER BY 1)
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION valid_trigger_proc(
	regprocedure, num_args int = 0
) RETURNS boolean AS $$
	SELECT pronargs = 0 OR pronargs = $2
	AND prorettype = 'trigger'::regtype
	FROM pg_proc WHERE oid = $1
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION is_class(regclass, text = NULL)
RETURNS boolean AS $$
	SELECT exists(
		SELECT oid FROM pg_class WHERE oid = $1
		AND COALESCE(position(relkind IN $2) != 0, true)
	)
$$ LANGUAGE sql;

/*
CREATE [ CONSTRAINT ] TRIGGER name
{ BEFORE | AFTER | INSTEAD OF }{ event [ OR ... ] }
ON table[ FROM referenced_table_name ]
{ NOT DEFERRABLE
	| [ DEFERRABLE ] { INITIALLY IMMEDIATE | INITIALLY DEFERRED }
}
[ FOR [ EACH ] { ROW | STATEMENT } ]
[ WHEN ( condition ) ]
EXECUTE PROCEDURE function_name [ ( argument [, ... ]) ]

event:
INSERT | UPDATE [ OF column_name [, ... ] ] | DELETE | TRUNCATE
*/

CREATE TABLE IF NOT EXISTS meta_triggers (
	comment_ text DEFAULT '',
	name_ name NOT NULL,
	table_ regclass NOT NULL CHECK( is_class(table_, 'rv') ),
	type_ meta_trigger_types NOT NULL,
	constraint_ boolean NOT NULL DEFAULT false,
	CHECK(NOT constraint_ OR type_ = 'trigger__after'),
	on_ meta_trigger_ons[] NOT NULL CHECK(valid_trigger_on(on_)),
	cols_ text[] NOT NULL DEFAULT '{}',
	CHECK( array_length(cols_) = 0
		OR on_ = meta_trigger_on('trigger__update_of')
			AND type_ != 'trigger__instead_of'
	),
	from_ regclass CHECK( from_ IS NULL OR is_class(from_, 'r') ),
	CHECK(from_ IS NULL OR constraint_),
	deferrable_ boolean NOT NULL DEFAULT false,
	CHECK(NOT constraint_ OR NOT deferrable_),
	initially_deferred_ boolean NOT NULL DEFAULT false,
	CHECK(NOT initially_deferred_ OR NOT deferrable_),
	per_row_ boolean NOT NULL DEFAULT false,
	CHECK( NOT constraint_ OR per_row_ ),
	when_ text,
	CHECK( when_ IS NULL OR type_ != 'trigger__instead_of' ),
	proc_ regprocedure NOT NULL,
	args_ text[],
	CHECK( valid_trigger_proc(proc_, array_length(args_)) )
);

-- SELECT declare_always_empty('meta_triggers');

COMMENT ON TABLE meta_triggers IS '
Currently this "table" exists only to provide a
type for tuples, which means that its constraints
and defaults will not be respected.
Tuples of this type should therefore be created
only with constructors which enforce these
constraints and might provide these defaults
for convenience.
';

COMMENT ON COLUMN meta_triggers.name_ IS '
The name to give the new trigger. This must be distinct from
the name of any other trigger for the same table. The name
cannot be schema-qualified — the trigger inherits the schema
of its table. For a constraint trigger, this is also the
name to use when modifying the trigger''s behavior using SET
CONSTRAINTS.
';

COMMENT ON COLUMN meta_triggers.table_ IS '
The table or view the trigger is for.
';

COMMENT ON COLUMN meta_triggers.when_ IS '
A Boolean expression that determines whether the trigger
function will actually be executed. If WHEN is specified,
the function will only be called if the condition returns
true. In FOR EACH ROW triggers, the WHEN condition can refer
to columns of the old and/or new row values by writing
OLD.column_name or NEW.column_name respectively. Of course,
INSERT triggers cannot refer to OLD and DELETE triggers
cannot refer to NEW.
';

COMMENT ON COLUMN meta_triggers.from_ IS '
Another table referenced by the constraint. This option is
used for foreign-key constraints and is not recommended for
general use. This can only be specified for constraint
triggers.
';

COMMENT ON COLUMN meta_triggers.proc_ IS '
A user-supplied function that is declared as taking no
arguments and returning type trigger, which is executed when
the trigger fires.
---> No arguments??? but what if we supply arguments
with CREATE TRIGGER???
';

COMMENT ON COLUMN meta_triggers.args_ IS '
An optional comma-separated list of arguments to be provided
to the function when the trigger is executed. The arguments
are literal string constants. Simple names and numeric
constants can be written here, too, but they will all be
converted to strings. Please check the description of the
implementation language of the trigger function to find out
how these arguments can be accessed within the function; it
might be different from normal function arguments.
--> So does this mean it''s OK for the function to take
arguments, contradicting what was said about the trigger
function?
';
