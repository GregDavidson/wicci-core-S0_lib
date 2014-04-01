-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('handles-tst-data.sql', '$Id');

--	PostgreSQL Utility Row Handles Test Data

-- ** Copyright

--	Copyright (c) 2005, 2006, J. Greg Davidson.
--	This code may be freely used by CreditLink Corporation
--	for their internal business needs but not redistributed
--	to third parties.

-- We need a table with two primary keys with some rows

CREATE TABLE IF NOT EXISTS table_with_2_primaries (
	i integer,
	n text,
	PRIMARY KEY(i, n)
);

INSERT INTO table_with_2_primaries(i, n) VALUES (5, 'five');

-- We need some convenience functions for generating text

CREATE OR REPLACE
FUNCTION handle_table_for_text(regclass) RETURNS text AS $$
	SELECT meta_table_text(handle_meta_table_($1, colms))
	FROM primary_meta_column_array($1) colms
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION create_handle_table_for(regclass) RETURNS regclass AS $$
	SELECT
		create_handle_table_for($1, colms)
	FROM primary_meta_column_array($1) colms
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION get_handle_for_text(regclass) RETURNS text AS $$
	SELECT meta_func_text(row_getter_meta_func_($1, colms))
	FROM primary_meta_column_array($1) colms
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION set_handle_for_text(regclass) RETURNS text AS $$
	SELECT meta_func_text(row_setter_meta_func_($1, colms))
	FROM primary_meta_column_array($1) colms
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION default_handle_for_text(regclass) RETURNS text AS $$
	SELECT meta_func_text(default_handle_getter_meta_func_($1, colms))
	FROM primary_meta_column_array($1) colms
$$ LANGUAGE SQL;
