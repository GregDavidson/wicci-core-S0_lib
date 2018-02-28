-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('array.sql', '$Id');

--	PostgreSQL Array Utilities Code

-- ** Copyright

--	Copyright (c) 2005-2012, J. Greg Davidson.
--	You may use this file under the terms of the
--	GNU AFFERO GENERAL PUBLIC LICENSE 3.0
--	as specified in the file LICENSE.md included with this distribution.
--	All other use requires my permission in writing.

-- IN PROCESS:
--	Rename those functions which can fail to NULL with prefix try,
--	and create a non_null version with the original name.
-- See token --HERE-- below:

CREATE OR REPLACE
FUNCTION try_array_sub(ANYARRAY, integer)
RETURNS ANYELEMENT AS $$
	SELECT $1[$2]
$$ LANGUAGE SQL STRICT IMMUTABLE;

SELECT test_func(
	'try_array_sub(ANYARRAY, integer)',
	try_array_sub(ARRAY[1], 1),
	1,
	'try_array_sub(ARRAY[1], 1)'
);

SELECT test_func(
	'try_array_sub(ANYARRAY, integer)',
	try_array_sub(ARRAY[1], 0), NULL, 'try_array_sub(ARRAY[1], 0)'
);

SELECT test_func(
	'try_array_sub(ANYARRAY, integer)',
	try_array_sub(ARRAY[1], 2), NULL, 'try_array_sub(ARRAY[1], 2)'
);

CREATE OR REPLACE
FUNCTION array_sub(ANYARRAY, integer, regprocedure = NULL::regprocedure)
RETURNS ANYELEMENT AS $$
	SELECT non_null(
		try_array_sub($1, $2),
		COALESCE($3, 'array_sub(ANYARRAY, integer, regprocedure)')
	)
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION array_sub(ANYARRAY, integer, regprocedure)
IS 'returns the element of the given array at the given index;
handy for using array indices in FROM clauses';

SELECT test_func(
	'array_sub(ANYARRAY, integer, regprocedure)',
	array_sub(ARRAY[1], 1),
	1
);

CREATE OR REPLACE
FUNCTION array_is_empty(ANYARRAY) RETURNS boolean AS $$
	SELECT $1 IS NULL OR array_upper($1, 1) IS NULL
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION array_is_empty(ANYARRAY)
IS 'true for NULL or empty arrays';

SELECT test_func(
	'array_is_empty(ANYARRAY)',
	array_is_empty(ARRAY[1]),
	false
);

SELECT test_func(
	'array_is_empty(ANYARRAY)',
	array_is_empty('{}'::integer[]),
	true
);

SELECT test_func(
	'array_is_empty(ANYARRAY)',
	array_is_empty(NULL::integer[]),
	true
);

-- **  array_length(ANYARRAY) -> integer
CREATE OR REPLACE
FUNCTION array_length(ANYARRAY) RETURNS integer AS $$
	SELECT COALESCE( array_length($1, 1), 0 )
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION array_length(ANYARRAY)
IS 'gives 0 for NULL or empty arrays';

SELECT test_func(
	'array_length(ANYARRAY)',
	array_length(ARRAY[1]),
	1
);

SELECT test_func(
	'array_length(ANYARRAY)',
	array_length('{}'::integer[]),
	0
);

SELECT test_func(
	'array_length(ANYARRAY)',
	array_length(NULL::integer[]),
	0
);

CREATE OR REPLACE
FUNCTION array_or_empty(ANYARRAY) RETURNS ANYARRAY AS $$
	SELECT COALESCE($1, '{}')
$$ LANGUAGE SQL;
COMMENT ON FUNCTION array_or_empty(ANYARRAY)
IS 'normalizes NULL arrays to empty arrays';

SELECT test_func(
	'array_or_empty(ANYARRAY)',
	array_or_empty(ARRAY[1]),
	ARRAY[1]
);

SELECT test_func(
	'array_or_empty(ANYARRAY)',
	array_or_empty(null::integer[]),
	'{}'::integer[]
);

CREATE OR REPLACE
FUNCTION array_head(ANYARRAY) RETURNS ANYELEMENT AS $$
	SELECT CASE WHEN low IS NOT NULL THEN $1[low] END
	FROM array_lower($1, 1) low
$$ LANGUAGE SQL;
COMMENT ON FUNCTION array_head(ANYARRAY)
IS 'first element of array or NULL';

SELECT test_func(
	'array_head(ANYARRAY)',
	array_head(ARRAY[1]),
	1
);

SELECT test_func(
	'array_head(ANYARRAY)',
	array_head('{}'::integer[]) IS NULL
);

CREATE OR REPLACE
FUNCTION array_tail(ANYARRAY, OUT ANYARRAY) AS $$
	SELECT CASE
		WHEN lo = hi THEN '{}'
		WHEN lo < hi THEN
			$1[ lo+1 : hi ]
	END
	FROM array_lower($1, 1) lo, array_upper($1, 1) hi
$$ LANGUAGE SQL;
COMMENT ON FUNCTION array_tail(ANYARRAY)
IS 'all but first element of array or NULL';

SELECT test_func(
	'array_tail(ANYARRAY)',
	array_tail(ARRAY[1]),
	'{}'::integer[]
);

SELECT test_func(
	'array_tail(ANYARRAY)',
	array_tail('{}'::integer[]) IS NULL
);

-- **  array_steps(array, step, dimension) -> set of indices of the array
CREATE OR REPLACE
FUNCTION array_steps(ANYARRAY, integer, integer DEFAULT 1)
RETURNS SETOF integer AS $$
	SELECT generate_series(
		CASE WHEN $2 > 0 THEN lo WHEN $2 < 0 THEN hi END,
		CASE WHEN $2 > 0 THEN hi WHEN $2 < 0 THEN lo END,
		$2
	) FROM
		array_lower($1, $3) lo,
		array_upper($1, $3) hi
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION array_steps(ANYARRAY, integer, integer) IS
'returns every step $2 index of the array $1';

SELECT test_func(
	'array_steps(ANYARRAY, integer, integer)',
	ARRAY(SELECT array_steps(ARRAY[1,2,3], -2)),
	ARRAY[3,1]
);

CREATE OR REPLACE FUNCTION array_pairs(
	VARIADIC ANYARRAY,
	OUT ANYELEMENT, OUT ANYELEMENT
) RETURNS SETOF RECORD AS $$
	SELECT ($1)[i], ($1)[i+1] FROM array_steps($1, 2) i
	WHERE ($1)[i] IS NOT NULL AND ($1)[i+1] IS NOT NULL
$$ LANGUAGE SQL;
COMMENT ON FUNCTION array_pairs(ANYARRAY) IS
'Returns a set of adjacent pairs taken from the given array;
Any pairs with either member NULL will be suppressed;
WARNING: Does not warn if number of elements is not even!!';

SELECT test_func(
	'array_pairs(ANYARRAY)',
	array_pairs(1,2) = ROW(1, 2)
);

SELECT test_func(
	'array_pairs(ANYARRAY)',
	array_pairs(1,2,3) = ROW(1, 2)
);

SELECT test_func(
	'array_pairs(ANYARRAY)',
	( SELECT COUNT(x) FROM array_pairs(1)x ) = 0
);

SELECT test_func(
	'array_pairs(ANYARRAY)',
	( SELECT COUNT(x) FROM array_pairs(1,2,3,4)x ) = 2
);

-- **  array_indices(arrayi, dimension) -> set of indices of the array
CREATE OR REPLACE
FUNCTION array_indices(ANYARRAY, integer DEFAULT 1) RETURNS SETOF integer AS $$
	SELECT generate_subscripts($1, $2)
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION array_indices(ANYARRAY, integer) IS
'returns the indices of the array from lowest to highest';

SELECT test_func(
	'array_indices(ANYARRAY, integer)',
	ARRAY(SELECT array_indices('{}'::integer[])),
	'{}'::integer[]
);

SELECT test_func(
	'array_indices(ANYARRAY, integer)',
	ARRAY(SELECT array_indices(ARRAY[1])),
	ARRAY[1]
);

SELECT test_func(
	'array_indices(ANYARRAY, integer)',
	ARRAY(SELECT array_indices(ARRAY[1,2])),
	ARRAY[1,2]
);

-- **  array_rindices(array, dimension) -> reversed set of indices of the array
CREATE OR REPLACE
FUNCTION array_rindices(ANYARRAY, integer DEFAULT 1) RETURNS SETOF integer AS $$
	SELECT generate_subscripts($1, $2, true)
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION array_rindices(ANYARRAY, integer) IS
'returns the indices of the array from highest to lowest';

SELECT test_func(
	'array_rindices(ANYARRAY, integer)',
	ARRAY(SELECT array_rindices('{}'::integer[])),
	'{}'::integer[]
);

SELECT test_func(
	'array_rindices(ANYARRAY, integer)',
	ARRAY(SELECT array_rindices(ARRAY[1])),
	ARRAY[1]
);

SELECT test_func(
	'array_rindices(ANYARRAY, integer)',
	ARRAY(SELECT array_rindices(ARRAY[1,2])),
	ARRAY[2, 1]
);

-- this would copy a non-empty array:
-- select ARRAY(select a[i] from array_indices(a) i) from COALESCE(array[1,2]) a;

-- this would convert a set to an array:
-- ARRAY( select ....; )
-- where the select returns rows of one column

-- **  array_to_set(array) -> set of (index, value) records
-- requires "column definition list" when used, e.g.:
--  select *  from array_to_set( $${'a','b','c'}$$::TEXT[] ) AS ("index" integer, "value" text);
CREATE OR REPLACE
FUNCTION array_to_set(ANYARRAY) RETURNS SETOF RECORD AS $$
 SELECT i AS "index", $1[i] as "value" FROM generate_subscripts($1, 1) i
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION array_to_set(ANYARRAY) IS
'returns the array as a set of RECORD(index, value) pairs';

-- need tests!!

-- BREAKS IN PG 8.4 beta[12]
-- fixed with patch, Thursday 11 June 2009 ???
-- new error on this test:
-- array.sql:238: ERROR:  0A000: PL/pgSQL functions cannot accept type record[]
-- CONTEXT:  compilation of PL/pgSQL function "test_func" near line 0
-- LOCATION:  do_compile, pl_comp.c:419
-- make: *** [array.sql-out] Error 3

-- SELECT test_func(
--   'array_to_set(ANYARRAY)',
--   ARRAY( SELECT array_to_set(ARRAY['one', 'two']) ),
--   ARRAY[ ROW(1, 'one'), ROW(2, 'two') ]
-- );

-- Obsoleted by 9.2 unnest
-- **  array_to_list(array) -> set of array values
-- question: can we guarantee the values will be seen in order?
-- CREATE OR REPLACE
-- FUNCTION array_to_list(ANYARRAY) RETURNS SETOF ANYELEMENT AS $$
-- --    SELECT $1[i]  FROM array_indices($1) i
-- 		SELECT unnest($1)
-- $$ LANGUAGE SQL IMMUTABLE;
-- COMMENT ON FUNCTION array_to_list(ANYARRAY) IS
-- 'returns the array as a set of its elements from lowest to highest';

-- SELECT test_func(
--   'array_to_list(ANYARRAY)',
--   ARRAY( SELECT array_to_list(ARRAY['one', 'two']) ),
--   ARRAY['one', 'two']
-- );

-- SELECT test_func(
--   'array_to_list(ANYARRAY)',
--   array_to_list('{}'::text[] ) IS NULL
-- );

-- **  array_to_rlist(array) -> set of array values reversed
CREATE OR REPLACE
FUNCTION array_to_rlist(ANYARRAY) RETURNS SETOF ANYELEMENT AS $$
		SELECT $1[i]  FROM array_rindices($1) i
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION array_to_rlist(ANYARRAY) IS
'returns the array as a set of its elements from hiighest to lowest';

SELECT test_func(
  'array_to_rlist(ANYARRAY)',
  ARRAY( SELECT array_to_rlist(ARRAY['one', 'two']) ),
  ARRAY['two', 'one']
);

CREATE OR REPLACE
FUNCTION try_array(ANYELEMENT) RETURNS ANYARRAY AS $$
	SELECT ARRAY(SELECT $1 WHERE $1 IS NOT NULL)
$$ LANGUAGE sql;
COMMENT ON FUNCTION try_array(ANYELEMENT) IS
'return an empty array or a singleton';

-- need tests!!

CREATE OR REPLACE
FUNCTION array_has_null(ANYARRAY) RETURNS boolean AS $$
	SELECT EXISTS(SELECT x FROM unnest($1) x WHERE x IS NULL)
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION array_has_null(ANYARRAY)
IS 'at least one of the elements is null';

-- need tests!!

CREATE OR REPLACE
FUNCTION array_has_no_nulls(ANYARRAY) RETURNS boolean AS $$
	SELECT NOT array_has_null($1)
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION array_has_no_nulls(ANYARRAY)
IS 'none of the elements are null';

-- need tests!!

/*
CREATE OR REPLACE
FUNCTION array_non_nulls(ANYARRAY) RETURNS ANYARRAY AS $$
	SELECT COALESCE( ARRAY(
		SELECT x FROM unnest($1) x WHERE x IS NOT NULL
	), '{}' )
$$ LANGUAGE SQL IMMUTABLE;
-- ERROR:  22004: function returning set of rows cannot return null value
-- CONTEXT:  SQL function "array_non_nulls" statement 1
*/

CREATE OR REPLACE
FUNCTION array_non_nulls(ANYARRAY) RETURNS ANYARRAY AS $$
	SELECT COALESCE( ARRAY(
		SELECT ($1)[i]
		FROM generate_subscripts($1, 1) i
		WHERE ($1)[i] IS NOT NULL
	), '{}' )
$$ LANGUAGE SQL IMMUTABLE;

COMMENT ON FUNCTION array_non_nulls(ANYARRAY)
IS 'return array of non-null elements of given array';

SELECT test_func(
  'array_non_nulls(ANYARRAY)',
	array_non_nulls(ARRAY[1,NULL,2]),
	ARRAY[1,2]
);

SELECT test_func(
  'array_non_nulls(ANYARRAY)',
	array_non_nulls(ARRAY[NULL::integer]),
	'{}'::integer[]
);

CREATE OR REPLACE
FUNCTION array_reverse(ANYARRAY) RETURNS ANYARRAY AS $$
	SELECT CASE
		WHEN array_length($1) < 2 THEN $1
		ELSE ARRAY( SELECT array_to_rlist($1) )
	END
$$ LANGUAGE SQL IMMUTABLE;

SELECT test_func(
  'array_reverse(ANYARRAY)',
  array_reverse(ARRAY['one', 'two']),
  ARRAY['two', 'one']
);

-- ** array_without(ANYARRAY, integer) -> ANYARRAY
CREATE OR REPLACE
FUNCTION array_without(ANYARRAY, integer) RETURNS ANYARRAY AS $$
	SELECT CASE
		WHEN array_is_empty($1) THEN $1
		ELSE $1[array_lower($1, 1):$2-1] ||  $1[$2+1:array_upper($1, 1)]
	END
$$ LANGUAGE SQL;
COMMENT ON FUNCTION array_without(ANYARRAY, integer)
IS 'return a shorter array omitting the element at the specified index';

SELECT test_func(
  'array_without(ANYARRAY, integer)',
  array_without(ARRAY['one', 'two'], 1),
  ARRAY['two']
);

-- ** array_minus(ANYARRAY, ANYELEMENT) -> ANYARRAY
-- OBSOLETED BY NEW built-in FUNCTION array_remove
-- CREATE OR REPLACE
-- FUNCTION array_minus(ANYARRAY, ANYELEMENT) RETURNS ANYARRAY AS $$
-- 	SELECT CASE
-- 		WHEN array_is_empty($1) THEN $1
-- 		ELSE ARRAY( SELECT $1[i] FROM array_indices($1) i WHERE $1[i] != $2 )
-- 	END
-- $$ LANGUAGE SQL;
-- COMMENT ON FUNCTION array_minus(ANYARRAY, ANYELEMENT)
-- IS 'return a (possibly) shorter array omitting the specified element';

-- the ::text cast is because pg-8.3.5 cannot
-- figure the type given overloaded array_minus
-- SELECT test_func(
--   'array_minus(ANYARRAY, ANYELEMENT)',
--   array_minus(ARRAY['one', 'two'], 'one'::text),
--   ARRAY['two']
-- );

-- Test PostgreSQL 9.3 array_remove function:
SELECT test_func(
  'array_remove(ANYARRAY, ANYELEMENT)',
  array_remove(ARRAY['one', 'two'], 'one'::text),
  ARRAY['two']
);


-- ** array_diff(ANYARRAY, ANYARRAY) -> ANYARRAY
CREATE OR REPLACE
FUNCTION array_diff(ANYARRAY, ANYARRAY) RETURNS ANYARRAY AS $$
	SELECT CASE WHEN array_lower($1, 1) IS NULL THEN $1
		ELSE ARRAY( SELECT $1[i] FROM array_indices($1) i WHERE $1[i] != ALL($2) )
	END
$$ LANGUAGE SQL;
COMMENT ON FUNCTION array_diff(ANYARRAY, ANYARRAY)
IS 'return the elements in the first array that are not in the second array;
i.e. set difference';

SELECT test_func(
  'array_diff(ANYARRAY, ANYARRAY)',
  array_diff(ARRAY[1, 2, 3], ARRAY[1, 2]),
  ARRAY[3]
);

-- ~~~ array_interpose(array, element-to-interpose) -> new-array
-- ARRAY MUST START WITH AN ODD INDEX -- 
-- To be fixed !!!
CREATE OR REPLACE
FUNCTION array_interpose(ANYARRAY, ANYELEMENT) RETURNS ANYARRAY AS $$
	SELECT ARRAY(
		SELECT CASE WHEN i % 2 = 1 THEN $1[(i+1)/2] ELSE $2 END
		FROM generate_series(array_lower($1, 1), array_upper($1, 1)*2-1) i
	)
$$ LANGUAGE SQL; -- monotonic
COMMENT ON FUNCTION array_interpose(ANYARRAY, ANYELEMENT)
IS 'the elements of the first array interleaved by the specified element';

SELECT test_func(
  'array_interpose(ANYARRAY, ANYELEMENT)',
  array_interpose(ARRAY['one', 'two'], 'and'),
  ARRAY['one', 'and', 'two']
);

-- ++ array_join(ANYARRAY, join_with TEXT) -> TEXT
-- Given: an array of elements convertable to TEXT and a value to join them with
-- Result: the elements of the array as TEXT joined with the given join_with value
CREATE OR REPLACE
FUNCTION array_join(ANYARRAY, TEXT) RETURNS TEXT AS $$
	SELECT array_to_string( ARRAY(SELECT value::TEXT FROM unnest($1) value), $2 )
$$ LANGUAGE SQL; -- monotonic
COMMENT ON FUNCTION array_join(ANYARRAY, TEXT)
IS 'same as array_to_string except that the elements do not have to be text,
merely of some type which can be cast to text';

SELECT test_func(
  'array_join(ANYARRAY, TEXT)',
  array_join(ARRAY['one', 'two'], ' and '),
  'one and two'
);

CREATE OR REPLACE
FUNCTION array_add(ANYARRAY, VARIADIC ANYARRAY) RETURNS ANYARRAY AS $$
	SELECT $1 || $2
$$ LANGUAGE SQL; -- monotonic
COMMENT ON FUNCTION array_add(ANYARRAY, ANYARRAY)
IS 'a generalization version of array_append';

-- need tests!!

CREATE OR REPLACE
FUNCTION array_add1(ANYARRAY, ANYELEMENT) RETURNS ANYARRAY AS $$
	SELECT $1 || $2
$$ LANGUAGE SQL; -- monotonic
COMMENT ON FUNCTION array_add1(ANYARRAY, ANYELEMENT)
IS 'a version of array_append';

CREATE OR REPLACE
FUNCTION array_dup(ANYARRAY, integer) RETURNS ANYARRAY AS $$
	SELECT CASE
		WHEN $2 <= 0 THEN empty
		ELSE (
			SELECT duped || duped || CASE
				WHEN $2 % 2 = 0 THEN empty ELSE $1
			END FROM array_dup($1, $2/2) duped
		)
	END FROM COALESCE(($1)[1:0]) empty
$$ LANGUAGE SQL; -- monotonic
COMMENT ON FUNCTION array_dup(ANYARRAY, integer)
IS 'duplicates $1 $2 times';

-- need tests!!

-- * hitmap filtering functions

-- Now moved to hitmap-arrays.sql

-- * array multi-matching functions

CREATE OR REPLACE
FUNCTION array_matching_indices(ANYARRAY,ANYELEMENT)
RETURNS SETOF integer AS $$
	SELECT i
	FROM generate_series(array_lower($1, 1), array_upper($1, 1)) i
	WHERE ($1)[i] IS NOT DISTINCT FROM $2
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE
FUNCTION array_key_vals(ANYARRAY,ANYELEMENT, ANYARRAY)
RETURNS SETOF ANYELEMENT AS $$
	SELECT ($3)[i]
	FROM generate_series(array_lower($1, 1), array_upper($1, 1)) i
	WHERE ($1)[i] IS NOT DISTINCT FROM $2
$$ LANGUAGE SQL IMMUTABLE;

-- * Provides

-- SELECT provide_procedure('array_is_empty(ANYARRAY)');
-- SELECT provide_procedure('array_indices(ANYARRAY)');
-- SELECT provide_procedure('array_rindices(ANYARRAY)');
-- SELECT provide_procedure('array_reverse(ANYARRAY)');
-- -- SELECT provide_procedure('array_minus(ANYARRAY, ANYELEMENT)');
-- SELECT provide_procedure('array_diff(ANYARRAY, ANYARRAY)');
-- SELECT provide_procedure('array_length(ANYARRAY)');
-- SELECT provide_procedure('array_to_set(ANYARRAY)');
-- -- SELECT provide_procedure('array_to_list(ANYARRAY)');
-- SELECT provide_procedure('array_to_rlist(ANYARRAY)');
-- SELECT provide_procedure('array_interpose(ANYARRAY, ANYELEMENT)');
-- SELECT provide_procedure('array_join(ANYARRAY, TEXT)');
