-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('misc.sql', '$Id');

--	PostgreSQL MISC Utilities Code

-- ** Copyright

--	Copyright (c) 2005 - 2012, J. Greg Davidson.
--	This code may be freely used by CreditLink Corporation
--	for their internal business needs but not redistributed
--	to third parties.

-- * Various Miscellaneous Functions

CREATE OR REPLACE
FUNCTION return_void() RETURNS void AS $$
BEGIN
END
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION return_void()
IS 'Just returns void - is there something else we could use?';

CREATE OR REPLACE
FUNCTION random_int(int, int DEFAULT 0) RETURNS int AS $$
	SELECT non_null(
		trunc((random()*$1)+$2)::int,
		'random_int(int, int)'
	)
$$ LANGUAGE sql;
COMMENT ON FUNCTION random_int(int, int) IS 
'Returns random integers i: $2 <= i < ($2+$1)';

CREATE OR REPLACE
FUNCTION max_nonnull(ANYELEMENT, ANYELEMENT)
RETURNS ANYELEMENT AS $$
	SELECT non_null(
		CASE WHEN first >= second THEN first ELSE second END,
		'max_nonnull(ANYELEMENT, ANYELEMENT)'
	) FROM COALESCE($1, $2) first, COALESCE($2, $1) second
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION try_enum_text(ANYENUM)  RETURNS text AS $$
	SELECT translate(substring(_s FROM position('__' IN _s)+2), '_', ' ')
	FROM CAST($1 AS text) _s
$$ LANGUAGE sql STRICT;

CREATE OR REPLACE
FUNCTION enum_text(ANYENUM) RETURNS text AS $$
	SELECT non_null(
		try_enum_text($1),
		'enum_text(ANYENUM)'
	)
$$ LANGUAGE sql;

COMMENT ON FUNCTION enum_text(ANYENUM)
IS 'given an enum value spelled <prefix>__<text>
returns translate(<text>, "_", " ")';

CREATE OR REPLACE
FUNCTION this(regprocedure) RETURNS regprocedure AS $$
	SELECT non_null( $1, 'this(regprocedure)' )
$$ LANGUAGE sql;
