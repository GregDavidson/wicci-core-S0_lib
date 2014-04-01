-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('bitset-code.sql', '$Id');

--	PostgreSQL bitset Utilities Code

-- ** Copyright

--	Copyright (c) 2005, 2006, J. Greg Davidson.
--	This code may be freely used by CreditLink Corporation
--	for their internal business needs but not redistributed
--	to third parties.

-- ** Depends

-- ???
-- SELECT require_module('bitset-schema');

-- The code here is independent of the choices of
-- chunk size and type established in the schema file.

-- * bitset support

CREATE OR REPLACE
FUNCTION empty_bitset_chunk() RETURNS bitset_chunks_ AS $$
	SELECT to_bitset_chunk_(0)
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION bitset_chunk_singleton_(integer)
RETURNS bitset_chunks_ AS $$
	SELECT to_bitset_chunk_( 1::bitset_chunks_ << $1 )
	WHERE $1 <= bitset_chunksize_()
$$ LANGUAGE sql IMMUTABLE;
COMMENT ON FUNCTION bitset_chunk_singleton_(integer) IS'
	Converts a small integer value to a bitset singleton,
	i.e. a bitset with only that one value on, all others off.
';

CREATE OR REPLACE
FUNCTION in_bitset_chunk(integer, bitset_chunks_) RETURNS boolean AS $$
	SELECT ($1 + 1) & from_bitset_chunk_($2) != 0
	WHERE $1 >= 0 AND $1 < bitset_chunksize_();
$$ LANGUAGE sql IMMUTABLE;
COMMENT ON FUNCTION in_bitset_chunk(integer, bitset_chunks_) IS'
	Returns true iff bit $1 in bitset $2 is on.
	$2 can be either a bit varying type or an integer with a bitset value.
';

CREATE OR REPLACE
FUNCTION empty_bitset() RETURNS bitsets AS $$
	SELECT '{}'::bitsets
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION bitset_is_empty(bitsets) RETURNS boolean AS $$
	SELECT array_is_empty(from_bitset($1))
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION to_bitset(integer) RETURNS bitsets AS $$
	SELECT bitset_cons_(
			bitset_chunk_singleton_( $1 - zeros * bitset_chunksize_() ),
			array_dup( from_bitset_zero(), zeros )
	) FROM COALESCE( bitset_chunks_($1) - 1 ) zeros
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION bitset_trim_(bitsets) RETURNS bitsets AS $$
	SELECT to_bitset(CASE
		WHEN array_is_empty(bits) THEN bits
		WHEN array_head(bits) = 0
			THEN bitset_trim_(array_tail(from_bitset($1)))
		ELSE bits
	END) FROM from_bitset($1) bits
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION bitset_trim(bitsets) RETURNS bitsets AS $$
	SELECT to_bitset(array_reverse(from_bitset(bitset_trim_(array_reverse(from_bitset($1))))))
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION bitset_diff_(bitsets, bitsets) RETURNS bitsets AS $$
	SELECT ARRAY(
		SELECT COALESCE(($1)[i], 0) & ~ COALESCE(($2)[i], 0)
		FROM generate_series(1, upper) i
	)::bitsets
	FROM max_nonnull( bitset_chunks_($1), bitset_chunks_($2) ) upper
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION bitset_diff(bitsets, bitsets) RETURNS bitsets AS $$
	SELECT CASE
		WHEN bitset_is_empty($1) THEN $1
		WHEN bitset_is_empty($2) THEN $1
		ELSE bitset_trim(bitset_diff_($1, $2))
	END
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION bitset_drop(bitsets, integer) RETURNS bitsets AS $$
	SELECT bitset_diff($1, to_bitset($2))
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION bitset_intersect_(bitsets, bitsets) RETURNS bitsets AS $$
	SELECT ARRAY(
		SELECT COALESCE(($1)[i], 0) & COALESCE(($2)[i], 0)
		FROM generate_series(1, upper) i
	)::bitsets
	FROM max_nonnull( bitset_chunks_($1), bitset_chunks_($2) ) upper
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION bitset_intersect(bitsets, bitsets) RETURNS bitsets AS $$
	SELECT CASE
		WHEN bitset_is_empty($1) THEN $1
		WHEN bitset_is_empty($2) THEN $2
		ELSE bitset_trim(bitset_intersect_($1, $2))
	END
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION bitset_union(bitsets, bitsets) RETURNS bitsets AS $$
	SELECT CASE
		WHEN bitset_is_empty($1) THEN $2
		WHEN bitset_is_empty($2) THEN $1
		ELSE ARRAY(
			SELECT COALESCE(($1)[i], 0) | COALESCE(($2)[i], 0)
			FROM generate_series(1, upper) i
		)
	END::bitsets
	FROM max_nonnull( bitset_chunks_($1), bitset_chunks_($2) ) upper
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION to_bitset(integer[]) RETURNS bitsets AS $$
	SELECT CASE WHEN array_is_empty($1) THEN empty_bitset()
	ELSE
		bitset_union(to_bitset(array_head($1)), to_bitset(array_tail($1)))
	END
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION try_in_bitset(integer, bitsets)  RETURNS boolean AS $$
	SELECT CASE
		WHEN chunk > bitset_chunks_($2) THEN false
		ELSE in_bitset_chunk($1 - (chunk-1) * bitset_chunksize_(), ($2)[chunk])
	END FROM bitset_chunks_($1) chunk
$$ LANGUAGE sql IMMUTABLE STRICT;

CREATE OR REPLACE
FUNCTION in_bitset(integer, bitsets) RETURNS boolean AS $$
	SELECT non_null(
		try_in_bitset($1,$2), 'in_bitset(integer,bitsets)'
	)
$$ LANGUAGE sql IMMUTABLE;
COMMENT ON FUNCTION in_bitset(integer, bitsets) IS
'$1 is in bitset $2';

CREATE OR REPLACE
FUNCTION ni_bitset(integer, bitsets) RETURNS boolean AS $$
	SELECT NOT in_bitset($1, $2)
$$ LANGUAGE sql IMMUTABLE;
COMMENT ON FUNCTION ni_bitset(integer, bitsets) IS
'$1 is NOT in bitset $2';

CREATE OR REPLACE
FUNCTION bitset_chunk_text(bitset_chunks_) RETURNS text AS $$
	SELECT $1::bitset_chunk_bits_::text
$$ LANGUAGE sql IMMUTABLE;
COMMENT ON FUNCTION bitset_chunk_text(bitset_chunks_) IS
'represent a bitset chunk as untrimmed text';

CREATE OR REPLACE
FUNCTION bitset_chunk_text_trimmed(bitset_chunks_) RETURNS text AS $$
	SELECT regexp_replace(bitset_chunk_text($1),'^0+','')
$$ LANGUAGE sql IMMUTABLE;
COMMENT ON FUNCTION bitset_chunk_text(bitset_chunks_) IS
'represent a bitset chunk as trimmed text';

CREATE OR REPLACE
FUNCTION bitset_text(bitsets) RETURNS text AS $$
	SELECT CASE
		WHEN bitset_is_empty($1) THEN '0'
		ELSE bitset_chunk_text_trimmed( ($1)[array_upper(from_bitset($1),1)] ) ||
			array_to_string(
				ARRAY( SELECT bitset_chunk_text( chunk )
				 FROM unnest(array_tail(array_reverse(from_bitset($1)))) chunk
				 WHERE chunk IS NOT NULL
	),
			''
			)
	END
$$ LANGUAGE sql IMMUTABLE;
COMMENT ON FUNCTION bitset_text(bitsets) IS
'represent a bitset as text';
