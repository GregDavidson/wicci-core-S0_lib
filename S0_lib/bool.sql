-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('bool.sql', '$Id');

--    (setq outline-regexp "^--[ \t]+[*+-~=]+ ")
--    (outline-minor-mode)

--	Wicci Project Type Boolean Utilities Code

-- ** Copyright

--	Copyright (c) 2005, 2006, J. Greg Davidson, all rights reserved.
--	Although it is my intention to make this code available
--	under a Free Software license when it is ready, this code
--	is currently not to be copied nor shown to anyone without
--	my permission in writing.


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
