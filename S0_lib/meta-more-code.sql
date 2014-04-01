-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('meta-more-code.sql', '$Id');

--	PostgreSQL Metaprogramming Utilities Code
-- Code support for meta-more-schema

-- ** Copyright

--	Copyright (c) 2012, J. Greg Davidson.
--	This code may be freely used by CreditLink Corporation
--	for their internal business needs but not redistributed
--	to third parties.

-- * ALTER COLUMN

CREATE OR REPLACE FUNCTION try_alter_column_default_text(
	_table regclass, _column text, _value text
)  RETURNS text AS $$
	SELECT 'ALTER TABLE ' || $1
	|| ' ALTER COLUMN ' || $2
	|| ' SET DEFAULT ' || $3
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE FUNCTION alter_column_default_text(
	_table regclass, _column text, _value text
) RETURNS text AS $$
	SELECT non_null(
		try_alter_column_default_text($1,$2,$3),
		'alter_column_default_text(regclass,text,text)'
	)
$$ LANGUAGE sql;

-- * CREATE TYPE

-- * CREATE SEQUENCE

/*
CREATE [TEMP] SEQUENCE name  [INCREMENT increment ]
    [ MINVALUE minvalue] [MAXVALUE maxvalue]
    [START start] [ CACHE cache ] [[NO] CYCLE]
    [OWNED BY {table.column}]
*/

CREATE OR REPLACE FUNCTION try_sequence_text(
	_name text, _owner regclass=NULL, _column text=NULL,
	_min bigint=NULL, _max bigint=NULL, _by int=NULL,
	_start bigint=NULL, _cycle boolean = true
)  RETURNS text AS $$
	SELECT 'CREATE SEQUENCE ' || _name ||
		COALESCE(' OWNED BY ' || _owner::text || '.' || _column, '') ||
		COALESCE(' MINVALUE ' || _min::text, '') ||
		COALESCE(' MAXVALUE ' || _max::text, '') ||
		COALESCE(
			' INCREMENT ' ||
			COALESCE(
				_by, CASE WHEN COALESCE(_start,_min) > _max THEN -1 END
			)::text,
			''
		) ||
		COALESCE(' START ' || _start::text, '') ||
		CASE WHEN _cycle THEN ' CYCLE' ELSE '' END
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sequence_text(
	_name text, _owner regclass=NULL, _column text=NULL,
	_min bigint=NULL, _max bigint=NULL, _by int=NULL,
	_start bigint=NULL, _cycle boolean = true
) RETURNS text AS $$
	SELECT non_null(
		try_sequence_text(_name,_owner,_column,_min,_max,_by,_start,_cycle),
		'sequence_text(text,regclass,text,bigint,bigint,int,bigint,boolean)'
	)
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION create_sequence(
	_name text, _owner regclass=NULL, _column text=NULL,
	_min bigint=NULL, _max bigint=NULL, _by int=NULL,
	_start bigint=NULL, _cycle boolean = true
) RETURNS boolean AS $$
	SELECT meta_execute(
				 this,
				 sequence_text(_name,_owner,_column,_min,_max,_by,_start,_cycle)
	) FROM this(
		'create_sequence(text, regclass, text,bigint, bigint, int,	bigint, boolean)'
	)
$$ LANGUAGE sql;

COMMENT ON FUNCTION 
create_sequence(_name text, _owner regclass, _column text,
	_min bigint, _max bigint, _by int, _start bigint, _cycle boolean)
IS 'Named argument "_by" is NOT the calling regprocedure!!';

-- * CREATE CAST

-- * CREATE OPERATOR

-- * CREATE OPERATOR CLASS

