-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('pg-meta.sql', '$Id');

-- Views and Functions on PostgreSQL system classes

SELECT require_module('array');

-- ** Copyright

-- Copyright (c) 2005, 2006, J. Greg Davidson.
-- You may use this file under the terms of the
-- GNU AFFERO GENERAL PUBLIC LICENSE 3.0
-- as specified in the file LICENSE.md included with this distribution.
-- All other use requires my permission in writing.

-- documentation functions can associate module with entities defined in that
-- module

-- * PostgreSQL meta-code to get entity names and kinds

-- This file extends and generalizes the facilities which
-- modules-code originally defined for its own purposes.

-- -- ** regprocedure_nargs(regprocedure) -> number of arguments
-- CREATE OR REPLACE
-- FUNCTION regprocedure_nargs(regprocedure) RETURNS integer AS $$
-- 	SELECT pronargs::integer FROM pg_proc WHERE oid = $1
-- $$ LANGUAGE SQL IMMUTABLE;

-- CREATE OR REPLACE
-- FUNCTION regproc_proargtypes(regprocedure) RETURNS oidvector AS $$
--   SELECT oid as "procid", array_to_set(proargtypes) FROM pg_proc
-- $$ LANGUAGE SQL IMMUTABLE;

CREATE TYPE index_type_pairs AS ( index integer, type regtype );

CREATE OR REPLACE
FUNCTION oid_array_to_index_type_pairs(oid[])
RETURNS SETOF index_type_pairs AS $$
	SELECT (id, $1[id] )::index_type_pairs
	FROM generate_series(array_lower($1, 1), array_upper($1, 1)) id;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE
FUNCTION proc_arg_index_type_pairs(regprocedure)
RETURNS SETOF index_type_pairs AS $$
	SELECT oid_array_to_index_type_pairs(COALESCE(proallargtypes, proargtypes))
	FROM pg_proc WHERE oid = $1
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE
FUNCTION proc_arg_types(regprocedure)
RETURNS SETOF regtype AS $$
	SELECT type FROM proc_arg_index_type_pairs($1) ORDER BY index
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE
FUNCTION table_column_type(regclass, name)
RETURNS regtype AS $$
	SELECT atttypid FROM pg_attribute
	WHERE attrelid = $1 AND attname = $2
$$ LANGUAGE SQL IMMUTABLE;

-- ** views

-- my attempt to create a pg_arguments view built on top of proc_arg_index_type_pairs
-- has been an abject failure due to my failing to understand how to create nested
-- queries

-- * Module Declarations

