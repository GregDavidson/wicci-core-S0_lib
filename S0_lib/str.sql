-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('str.sql', '$Id');

--	PostgreSQL String Utilities Code

-- ** Copyright

--	Copyright (c) 2005-2012, J. Greg Davidson, all rights reserved.
--	Although it is my intention to make this code available
--	under a Free Software license when it is ready, this code
--	is currently not to be copied nor shown to anyone without
--	my permission in writing.

--	This code may be freely used by CreditLink Corporation
--	for their internal business needs but not redistributed
--	to third parties.

-- ** Depends

-- ** misc
/*
CREATE OR REPLACE
FUNCTION decode_url_part(varchar) RETURNS varchar AS $$
	SELECT convert_from(
		CAST(E'\\x' || string_agg(CASE
			WHEN length(r.m[1]) = 1 THEN encode(convert_to(r.m[1], 'SQL_ASCII'), 'hex')
			ELSE substring(r.m[1] from 2 for 2)
		END, '') AS bytea), 'UTF8')
	FROM regexp_matches($1, '%[0-9a-f][0-9a-f]|.', 'gi') AS r(m);
$$ LANGUAGE SQL IMMUTABLE STRICT;

COMMENT ON FUNCTION decode_url_part(varchar) IS '
Courtesy of http://stackoverflow.com/users/1096411/mike';
*/

CREATE OR REPLACE
FUNCTION str_cgi_decode(text) RETURNS text AS $$
	SELECT string_agg(CASE
		WHEN m[1] ~ '^%[0-9a-fA-F][0-9a-fA-F]$' THEN
			convert_from(decode(substring(m[1] FROM 2 FOR 2), 'hex'), 'UTF8')
		ELSE m[1]
	END, '')
	FROM regexp_matches($1, '%[0-9a-f][0-9a-f]|[^%]+|.', 'gi') AS r(m);
$$ LANGUAGE SQL IMMUTABLE STRICT;

COMMENT ON FUNCTION str_cgi_decode(text) IS
'Rewrite in C??
Does not handle + properly!!!
';

CREATE OR REPLACE
FUNCTION str_str_delim(text, text, text DEFAULT ' ') RETURNS text AS $$
	SELECT CASE
		WHEN $1 IS NULL OR $1 = '' THEN $2
		WHEN $2 IS NULL OR $2 = '' THEN $1
		ELSE $1 || $3 || $2
	END
$$ LANGUAGE sql;
COMMENT ON FUNCTION str_str_delim(text, text, text) IS
'cats args, using delim when both non-empty';

CREATE OR REPLACE
FUNCTION str_comma(text, text) RETURNS text AS $$
	SELECT str_str_delim($1, $2, ',')
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION csv2(text, text) RETURNS text AS $$
	SELECT str_str_delim($1, $2, ',')
$$ LANGUAGE sql IMMUTABLE;

-- * trimming

CREATE OR REPLACE
FUNCTION str_trim_left(text) RETURNS TEXT AS $$
	SELECT regexp_replace($1,'^[[:space:]]+','')
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION str_trim_right(text) RETURNS TEXT AS $$
	SELECT regexp_replace($1,'[[:space:]]+$','')
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION str_trim(text) RETURNS TEXT AS $$
	SELECT str_trim_left(str_trim_right($1))
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION str_trim_lower(text) RETURNS TEXT AS $$
	SELECT lower(str_trim_left(str_trim_right($1)))
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION str_trim_lower_non_empty(text) RETURNS TEXT AS $$
	SELECT x FROM str_trim_lower($1) x WHERE x <> ''
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE
FUNCTION str_trim_deep(text) RETURNS TEXT AS $$
	SELECT regexp_replace(str_trim($1),'[[:space:]]+',' ', 'g')
$$ LANGUAGE sql IMMUTABLE;

SELECT test_func(
	'str_trim_deep(text)',
	str_trim_deep(E'  \t  \n blah     blah \t blah  '),
	'blah blah blah'
);

CREATE OR REPLACE
FUNCTION try_str_trim_right(text, integer)  RETURNS text AS $$
	SELECT substring($1 FOR length($1) - $2)
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION str_trim_right(text, integer) RETURNS text AS $$
	SELECT non_null(
		try_str_trim_right($1,$2),
		'str_trim_right(text,integer)'
	)
$$ LANGUAGE SQL;

COMMENT ON FUNCTION str_trim_right(text, integer) IS $$

$$;

-- * strings and patterns

CREATE OR REPLACE
FUNCTION try_str_match(text, text)  RETURNS text[] AS $$
	SELECT regexp_matches($1, $2) LIMIT 1
$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE
FUNCTION str_match(text, text) RETURNS text[] AS $$
	SELECT non_null(
		try_str_match($1,$2),
		'str_match(text,text)'
	)
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE
FUNCTION try_str_match(text, text, text)  RETURNS text[] AS $$
	SELECT regexp_matches($1, $2, $3) LIMIT 1
$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE
FUNCTION str_match(text, text, text) RETURNS text[] AS $$
	SELECT non_null(
		try_str_match($1,$2,$3),
		'str_match(text,text,text)'
	)
$$ LANGUAGE SQL IMMUTABLE;

/*
-- ++ substring_pair(text, pat1 regexp, pat2 regexp) -> (pat1 text, pat2 text)
CREATE OR REPLACE
FUNCTION substring_pair(text, text, text, OUT text, OUT text) AS $$
	SELECT substring($1, $2), substring($1, $3)
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION substring_pair(text, text, text, OUT text, OUT text) IS
'deprecated - use str_match instead!';
*/

-- ** string_to_array_regexp(string text, pattern text) -> text[]
CREATE OR REPLACE
FUNCTION string_to_array_regexp(original_string text, pattern text)
RETURNS text[] AS $$
	DECLARE
		str TEXT := original_string; -- we will split this up, left to right
		str_from_pattern TEXT;	--substring from first occurrance of pattern to the end
		split TEXT[] := '{ }';
		pattern_to_end CONSTANT TEXT := '(' || pattern || '.*)$';
		pattern_at_front CONSTANT TEXT := '^(' || pattern || ')';
	BEGIN
		LOOP
			-- invariant: array_to_string(split, --separators--) || str = original_string
			str_from_pattern := substring(str FROM pattern_to_end);
			IF str_from_pattern IS NULL THEN
			-- invariant: array_to_string(split, --separators--) || str = original_string
				RETURN split || str;
			END IF;
			DECLARE
				str_len INTEGER := char_length(str);
				str_from_pattern_len INTEGER := char_length(str_from_pattern);
				str_before_pattern TEXT := substring(str FROM 1 FOR str_len - str_from_pattern_len);
				pat_str TEXT := substring(str_from_pattern FROM pattern_at_front);
			BEGIN
				-- invariant: str_before_pattern || str_from_pattern = str
				IF pat_str = '' THEN
					RETURN split || str_from_pattern;  -- prevent infinite loop!
				END IF;
				split := split || str_before_pattern;
				-- str_before_pattern || pat_str || new str = current str
				str := substring(str FROM str_len - str_from_pattern_len + char_length(pat_str) + 1);
			END;
		END LOOP;
		RETURN split;
	END;
$$ LANGUAGE plpgsql;

-- ** split_string_by_pattern(string text, pattern text) -> text[]
CREATE OR REPLACE
FUNCTION try_split_string_by_pattern(original_string text, pattern text) 
RETURNS text[] AS $$
	DECLARE
		str TEXT := original_string; -- we will split this up, left to right
		str_from_pattern TEXT;	--substring from first occurrance of pattern to the end
		split TEXT[] := '{ }';
		pattern_to_end CONSTANT TEXT := '(' || pattern || '.*)$';
		pattern_at_front CONSTANT TEXT := '^(' || pattern || ')';
	BEGIN
		LOOP
			-- invariant: array_to_string(split, '') || str = original_string
			str_from_pattern := substring(str FROM pattern_to_end);
			IF str_from_pattern IS NULL THEN
			-- invariant: array_to_string(split, '') || str = original_string
				RETURN split || str;
			END IF;
			DECLARE
				str_len INTEGER := char_length(str);
				str_from_pattern_len INTEGER := char_length(str_from_pattern);
				str_before_pattern TEXT := substring(str FROM 1 FOR str_len - str_from_pattern_len);
				pat_str TEXT := substring(str_from_pattern FROM pattern_at_front);
			BEGIN
				-- invariant: str_before_pattern || str_from_pattern = str
				IF pat_str = '' THEN
					RETURN split || str_from_pattern;  -- prevent infinite loop!
				END IF;
				split := split || str_before_pattern || pat_str;
				-- str_before_pattern || pat_str || new str = current str
				str := substring(str FROM str_len - str_from_pattern_len + char_length(pat_str) + 1);
			END;
		END LOOP;
		RETURN split;
	END;
$$ LANGUAGE plpgsql STRICT;

CREATE OR REPLACE
FUNCTION split_string_by_pattern(original_string text, pattern text)
RETURNS text[] AS $$
	SELECT non_null(
		try_split_string_by_pattern($1,$2),
		'split_string_by_pattern(text,text)'
	)
$$ LANGUAGE sql;


