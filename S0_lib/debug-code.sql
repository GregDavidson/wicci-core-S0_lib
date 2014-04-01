-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('debug-code.sql', '$Id');

--    (setq outline-regexp "^--[ \t]+[*+-~=]+ ")
--    (outline-minor-mode)

--	PostgreSQL Utilities
--	Debugging Code

-- ** Copyright

--	Copyright (c) 2005, 2006, J. Greg Davidson, all rights reserved.
--	Although it is my intention to make this code available
--	under a Free Software license when it is ready, this code
--	is currently not to be copied nor shown to anyone without
--	my permission in writing.

-- ** Requires (from utilities-schema.sql):

-- ** Provides

-- * Debugging Facilities

CREATE OR REPLACE FUNCTION debug_text(
	ANYELEMENT, VARIADIC text[] = NULL
) RETURNS text AS $$
	SELECT COALESCE($1::text, '<NULL>')
	|| COALESCE(' ' || array_to_string($2, ' '), '');
$$ LANGUAGE sql;
COMMENT ON FUNCTION debug_text(ANYELEMENT, text[]) IS
'Convert a debugging message to text.';

-- ** debug_on(regprocedure) -> BOOLEAN
CREATE OR REPLACE
FUNCTION debug_on(regprocedure)
RETURNS BOOLEAN AS $$
	SELECT $1 IN (SELECT id FROM debug_on_oids)
$$ LANGUAGE SQL STABLE;
COMMENT ON FUNCTION debug_on(regprocedure)
IS 'Is debugging turned on for this function?
E.g.: select debug_on(''debug_on(regprocedure)'')';

-- ** debug_on(regprocedure, boolean) -> void
CREATE OR REPLACE
FUNCTION debug_on(regprocedure, boolean)
RETURNS void AS $$
BEGIN
	IF $2 THEN
		 BEGIN
			 INSERT INTO debug_on_oids(id) VALUES ($1);
			 EXCEPTION WHEN unique_violation THEN
			 	-- it was already on
		 END;
	ELSE
		DELETE FROM debug_on_oids WHERE id = $1;
	END IF;
END
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION debug_on(regprocedure, boolean)
IS 'Set debugging for this procedure to indicated value.
E.g.: select debug_on(''debug_on(regprocedure, boolean)'', true)';

/*
CREATE OR REPLACE FUNCTION debug_assert_failed(
	regprocedure, ANYELEMENT, text[]
) RETURNS ANYELEMENT AS $$
	SELECT debug_fail(,$1, $2, VARIADIC 'assert'::text || $3 )
$$ LANGUAGE sql;
COMMENT ON FUNCTION debug_assert_failed(
	regprocedure, ANYELEMENT, text[]
)IS 'Report failure of assertion in function involving entity';
*/

/*
-- ++ debug_assert(regprocedure, boolean) -> boolean
CREATE OR REPLACE
FUNCTION debug_assert(regprocedure, boolean)
RETURNS boolean AS $$
	SELECT CASE
		WHEN COALESCE($2, false) THEN $2
		ELSE debug_assert_failed($1, false, '{}')
	END
$$ LANGUAGE SQL;
COMMENT ON FUNCTION debug_assert(regprocedure, boolean)
IS 'Report failure of function unless boolean is true.';
*/

CREATE OR REPLACE FUNCTION debug_assert(
	regprocedure, boolean, ANYELEMENT,
	VARIADIC text[] = NULL
) RETURNS ANYELEMENT AS $$
	SELECT CASE
		WHEN COALESCE($2,false) THEN $3
		ELSE debug_fail($1, $3, VARIADIC 'assertion failed'::text || $4)
	END
$$ LANGUAGE SQL;
COMMENT ON FUNCTION debug_assert(
	regprocedure, boolean, ANYELEMENT, text[]
) IS 'Returns given value when condition true otherwise
fails.';

-- Here's how to find out what signatures are around for
-- a given function name, e.g. debug_on:
--
-- select oid::regprocedure from pg_proc where proname =
-- 'debug_on';

CREATE OR REPLACE FUNCTION raise_debug_note(
	regprocedure, ANYELEMENT, VARIADIC text[] = NULL
) RETURNS void AS $$
	BEGIN
		RAISE NOTICE 'DEBUG % note: %',
		$1, debug_text($2, VARIADIC $3);
	END
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION raise_debug_note(
	regprocedure, ANYELEMENT, text[]
) IS 'RAISE NOTICE about given procedure with given values.';

CREATE OR REPLACE FUNCTION debug_note(
	regprocedure, ANYELEMENT, VARIADIC text[] = NULL
) RETURNS void AS $$
	SELECT CASE
		WHEN debug_on($1)
			THEN raise_debug_note($1, $2, VARIADIC $3)
	END
$$ LANGUAGE sql;
COMMENT ON FUNCTION debug_note(
	regprocedure, ANYELEMENT, text[]
) IS 'If debugging given procedure, RAISE NOTICE with given
message.';

CREATE OR REPLACE
FUNCTION raise_debug_enter(regprocedure)
RETURNS void AS $$
	BEGIN RAISE NOTICE 'Entered %', $1; END
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION raise_debug_enter(regprocedure)
IS 'RAISE NOTICE that we''ve entered the given function.
This is intended to be called by other debug functions!';

CREATE OR REPLACE
FUNCTION debug_enter(regprocedure)
RETURNS regprocedure AS $$
	SELECT CASE WHEN debug_on($1)
		THEN raise_debug_enter($1) END;
	SELECT $1
$$ LANGUAGE sql;
COMMENT ON FUNCTION debug_enter(regprocedure)
IS 'When debugging is on for the given function, RAISE NOTICE
that we have entered it.';

CREATE OR REPLACE FUNCTION raise_debug_enter(
	regprocedure, ANYELEMENT, VARIADIC text[] = NULL
) RETURNS void AS $$
	BEGIN RAISE NOTICE 'DEBUG Entered %: %',
		$1, debug_text($2, VARIADIC $3);
	END
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION raise_debug_enter(
	regprocedure, ANYELEMENT, text[]
) IS 'RAISE NOTICE that we''ve entered the given function
along with the given message.  This is intended to be called
by other debug functions!';

CREATE OR REPLACE FUNCTION debug_enter(
	regprocedure, ANYELEMENT, VARIADIC text[] = NULL
) RETURNS regprocedure AS $$
	SELECT CASE WHEN debug_on($1)
		THEN raise_debug_enter($1, $2, VARIADIC $3) END;
	SELECT $1
$$ LANGUAGE sql;
COMMENT ON FUNCTION debug_enter(
	regprocedure, ANYELEMENT, text[]
) IS 'When debugging is on for the given function, RAISE
NOTICE that we have entered it and include the given
message.';

CREATE OR REPLACE FUNCTION raise_debug_show(
	regprocedure, text, ANYELEMENT, VARIADIC text[] = NULL
) RETURNS void AS $$
BEGIN
	RAISE NOTICE 'DEBUG %: % %', $1,
		COALESCE($2 || ' = ', ''),
		debug_text($3, VARIADIC $4);
END
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION raise_debug_show(
	regprocedure, text, ANYELEMENT, text[]
) IS 'RAISE a NOTICE showing a named value';

CREATE OR REPLACE FUNCTION debug_show(
	regprocedure, text, ANYELEMENT, VARIADIC text[] = NULL
) RETURNS void AS $$
	SELECT CASE WHEN debug_on($1)
		THEN raise_debug_show($1, $2, $3, VARIADIC $4)
	END
$$ LANGUAGE sql;
COMMENT ON FUNCTION debug_show(
	regprocedure, text, ANYELEMENT, text[]
) IS 'When debuggin this function, RAISE a NOTICE showing a
named value';

CREATE OR REPLACE FUNCTION raise_debug_return(
	regprocedure, ANYELEMENT, VARIADIC text[] = NULL
) RETURNS ANYELEMENT AS $$
BEGIN
	RAISE NOTICE 'DEBUG % returns %',
		$1, debug_text($2, VARIADIC $3);
	RETURN $2;
END
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION raise_debug_return(
	regprocedure, ANYELEMENT, text[]
) IS 'RAISE a NOTICE that the given function is returning the
given value and return it.';

CREATE OR REPLACE FUNCTION debug_return(
	regprocedure, ANYELEMENT, VARIADIC text[] = NULL
) RETURNS ANYELEMENT AS $$
	SELECT CASE WHEN debug_on($1)
		THEN raise_debug_return($1, $2, VARIADIC $3)
	END;
	SELECT $2
$$ LANGUAGE sql;
COMMENT ON FUNCTION debug_return(
	regprocedure, ANYELEMENT, text[]
) IS 'If we are debugging the given function, RAISE a NOTICE
that it is returning the given value and return it.';
