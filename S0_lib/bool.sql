-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('bool.sql', '$Id');

--    (setq outline-regexp "^--[ \t]+[*+-~=]+ ")
--    (outline-minor-mode)

--	Wicci Project Type Boolean Utilities Code

-- ** Copyright

--	Copyright (c) 2005, 2006, J. Greg Davidson.
--	You may use this file under the terms of the
--	GNU AFFERO GENERAL PUBLIC LICENSE 3.0
--	as specified in the file LICENSE.md included with this distribution.
--	All other use requires my permission in writing.


-- ++ bool_to(BOOLEAN, true_value, false_value) -> the_value
CREATE OR REPLACE
FUNCTION bool_to(BOOLEAN, ANYELEMENT, ANYELEMENT)
RETURNS ANYELEMENT AS $$
	SELECT CASE WHEN $1 THEN $2 ELSE $3 END
$$ LANGUAGE SQL;

-- ++ bool_text(BOOLEAN, true_value, false_value) -> the_value
CREATE OR REPLACE
FUNCTION bool_text(BOOLEAN, TEXT, TEXT) RETURNS TEXT AS $$
	SELECT bool_to($1, $2, $3)
$$ LANGUAGE SQL;

-- ++ bool_text(BOOLEAN) -> false/true
CREATE OR REPLACE
FUNCTION bool_text(BOOLEAN) RETURNS TEXT AS $$
	SELECT bool_text($1, 'true', 'false')
$$ LANGUAGE SQL;
