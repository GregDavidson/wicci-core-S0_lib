-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('bitset-schema.sql', '$Id');

--	PostgreSQL bitset Utilities Schema

-- ** Copyright

--	Copyright (c) 2005-2012, J. Greg Davidson.
--	This code may be freely used by CreditLink Corporation
--	for their internal business needs but not redistributed
--	to third parties.

-- ** Depends


-- Size and/or Type-Specific bitsets could be meta-generated,
-- but we're being simpler here.

-- These integer bitsets can grow as needed.  Our bitset operations
-- do not require uniformity of length.

DROP DOMAIN IF EXISTS bitset_chunk_bits_ CASCADE;
DROP DOMAIN IF EXISTS bitset_chunks_ CASCADE;
DROP DOMAIN IF EXISTS bitsets CASCADE;

CREATE DOMAIN bitsets AS int8[] NOT NULL;

-- The definitions in this schema file are dependent on our
-- choices for chunk size and type.  All of the definitions
-- below end in _ indicating that they are not part of the
-- bitsets API.

CREATE DOMAIN bitset_chunks_ AS int8 NOT NULL;
CREATE DOMAIN bitset_chunk_bits_ AS bit(64) NOT NULL;

CREATE OR REPLACE
FUNCTION from_bitset_chunk_(bitset_chunks_) RETURNS int8 AS $$
	SELECT $1::int8
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION to_bitset_chunk_(int8) RETURNS bitset_chunks_ AS $$
	SELECT $1::bitset_chunks_
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION from_bitset(bitsets)
RETURNS int8[] AS $$
	SELECT $1::int8[]
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION from_bitset_zero() RETURNS int8[] AS $$
	SELECT ARRAY[ 0::int8 ];
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION to_bitset(int8[])
RETURNS bitsets AS $$
	SELECT $1::bitsets
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION bitset_chunksize_() RETURNS integer AS $$
	SELECT 64
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION bitset_chunks_(integer) RETURNS integer AS $$
	SELECT $1 / bitset_chunksize_() + 1
	WHERE $1 >= 0
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION bitset_chunks_(bitsets) RETURNS integer AS $$
	SELECT COALESCE( array_upper(from_bitset($1), 1 ), 0 )
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION bitset_cons_(bitset_chunks_, bitsets) RETURNS bitsets AS $$
	SELECT to_bitset( from_bitset($2) || from_bitset_chunk_($1) )
$$ LANGUAGE sql IMMUTABLE;
