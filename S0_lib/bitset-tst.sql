-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('bitset-tst.sql', '$Id');

--	PostgreSQL Bitset Utilities Test Code

-- ** Copyright

--	Copyright (c) 2005, 2006, J. Greg Davidson, all rights reserved.
--	Although it is my intention to make this code available
--	under a Free Software license when it is ready, this code
--	is currently not to be copied nor shown to anyone without
--	my permission in writing.

-- ** Depends

-- ???
-- SELECT require_module('bitset-code');

SELECT test_func(
	'empty_bitset_chunk()',
	empty_bitset_chunk(), 0::bitset_chunks_
);

SELECT test_func(
	'to_bitset(integer)',
	from_bitset( to_bitset(0) ), ARRAY[1::int8]
);

SELECT test_func(
	'to_bitset(integer)',
	from_bitset( to_bitset(bitset_chunksize_()) ), ARRAY[0::int8, 1::int8]
);

SELECT test_func(
	'in_bitset(integer, bitsets)',
	in_bitset(0, to_bitset(0))
);

SELECT test_func(
	'in_bitset(integer, bitsets)',
	NOT in_bitset(0, empty_bitset())
);

SELECT test_func(
	'in_bitset(integer, bitsets)',
	NOT in_bitset(0, to_bitset(1))
);

SELECT test_func(
	'in_bitset(integer, bitsets)',
	in_bitset(bitset_chunksize_(), to_bitset(bitset_chunksize_()))
);

SELECT test_func(
	'ni_bitset(integer, bitsets)',
	ni_bitset(0, to_bitset(bitset_chunksize_()))
);

SELECT test_func(
	'bitset_chunk_text(bitset_chunks_)',
	bitset_chunk_text(empty_bitset_chunk()),
	repeat('0', bitset_chunksize_())
);

SELECT test_func(
	'bitset_chunk_text(bitset_chunks_)',
	bitset_chunk_text(to_bitset_chunk_(1)),
	repeat('0', bitset_chunksize_()-1) || '1'
);

SELECT test_func(
	'bitset_chunk_text_trimmed(bitset_chunks_)',
	bitset_chunk_text_trimmed(to_bitset_chunk_(1)),
	'1'
);

SELECT test_func(
	'bitset_text(bitsets)',
	bitset_text(empty_bitset()),
	'0'
);

SELECT test_func(
	'bitset_text(bitsets)',
	bitset_text(to_bitset(0)),
	'1'
);

SELECT test_func(
	'bitset_text(bitsets)',
	bitset_text(to_bitset(0)),
	'1'
);

SELECT test_func(
	'bitset_text(bitsets)',
	bitset_text(to_bitset(bitset_chunksize_())),
	'1' || repeat('0', bitset_chunksize_())
);
