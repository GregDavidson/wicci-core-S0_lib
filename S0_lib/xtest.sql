-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('xtest.sql', '$Id');

-- PostgreSQL Unit Test Framework - Very Simple!

-- ** Copyright

-- Copyright (c) 2008 - 2012, J. Greg Davidson.
-- You may use this file under the terms of the
-- GNU AFFERO GENERAL PUBLIC LICENSE 3.0
-- as specified in the file LICENSE.md included with this distribution.
-- All other use requires my permission in writing.

CREATE OR REPLACE
FUNCTION test_if(bool, text = 'test') RETURNS bool AS $$
BEGIN
	IF $1 IS NULL OR NOT $1 THEN
		RAISE EXCEPTION 'Failed %!', $2;
	END IF;
	RETURN $1;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE
FUNCTION test_func(regprocedure, bool, text = 'test')
RETURNS regprocedure AS $$
BEGIN
	IF $2 IS NULL OR NOT $2 THEN
		RAISE EXCEPTION 'FUNCTION % failed %!', $1, $3;
	END IF;
	RETURN $1;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE
FUNCTION test_func(regprocedure, ANYELEMENT, ANYELEMENT, text = '')
RETURNS regprocedure AS $$
BEGIN
	IF $2 IS NULL != $3 IS NULL OR $2 != $3 THEN
		RAISE EXCEPTION
		E'FUNCTION % RETURNED:\n"%" ! "%"',
		$1::text || $4, $2, $3;
	END IF;
	RETURN $1;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE
FUNCTION text_tokens(text) RETURNS text AS $$
	SELECT regexp_replace($1, E'[[:space:]\n]+', ' ', 'g')
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION test_func_tokens(regprocedure, text, text, text = '')
RETURNS regprocedure AS $$
BEGIN
	IF $2 IS NULL != $3 IS NULL
	OR text_tokens($2) != text_tokens($3) THEN
		RAISE EXCEPTION
		E'FUNCTION % RETURNED:\n~~>%<~~ ! ~~>%<~~',
		$1::text || $4, $2, $3;
	END IF;
	RETURN $1;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE
FUNCTION test_select(text) RETURNS bool AS $$
DECLARE
	the_result boolean;
	_select text := 'SELECT ' || $1;
BEGIN
	EXECUTE _select INTO the_result;
	IF the_result = false THEN
		RAISE EXCEPTION 'Failed %', _select;
	END IF;
	RETURN the_result;
END
$$ LANGUAGE plpgsql STRICT;
