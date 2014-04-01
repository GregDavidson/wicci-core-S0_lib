-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('notes-schema.sql', '$Id');

--	PostgreSQL Attributed Notes Schema

-- ** Copyright

--	Copyright (c) 2005, 2006, J. Greg Davidson.
--	This code may be freely used by CreditLink Corporation
--	for their internal business needs but not redistributed
--	to third parties.

-- ** Depends

-- SELECT require_module('modules-code');

-- * Note Authors and Notes

-- ** Note Authors

DROP DOMAIN IF EXISTS note_author_ids CASCADE;

CREATE DOMAIN note_author_ids AS integer NOT NULL;

DROP SEQUENCE IF EXISTS note_author_id_seq CASCADE;

CREATE SEQUENCE note_author_id_seq START -1 INCREMENT -1;

CREATE OR REPLACE
FUNCTION next_note_author_id() RETURNS note_author_ids AS $$
	SELECT nextval('note_author_id_seq')::note_author_ids
$$ LANGUAGE sql;

CREATE TABLE IF NOT EXISTS note_authors (
	id note_author_ids PRIMARY KEY DEFAULT next_note_author_id()
);
COMMENT ON TABLE note_authors IS
'just id values - client code might associate these with a higher level identity system';

ALTER SEQUENCE note_author_id_seq OWNED BY note_authors.id;

SELECT create_handles_plus_for('note_authors');

CREATE OR REPLACE
FUNCTION make_note_author(handles, note_author_ids)
RETURNS note_authors AS $$
	INSERT INTO note_authors VALUES($2);
	SELECT note_authors_row($1, $2)
$$ LANGUAGE SQL;

CREATE OR REPLACE
FUNCTION make_note_author(handles)
RETURNS note_authors AS $$
	SELECT make_note_author($1, next_note_author_id())
$$ LANGUAGE SQL;

-- ** Attributed notes and their service functions

DROP DOMAIN IF EXISTS note_feature_ids CASCADE;
DROP DOMAIN IF EXISTS note_feature_sets CASCADE;

CREATE DOMAIN note_feature_ids AS integer;

CREATE DOMAIN note_feature_sets AS bitsets;

CREATE TABLE IF NOT EXISTS note_features (
	id note_feature_ids PRIMARY KEY,
	name text
);
COMMENT ON TABLE note_features IS
'num rows must equal num bits of note_feature_sets';

DROP DOMAIN IF EXISTS attributed_note_ids CASCADE;
DROP DOMAIN IF EXISTS attributed_note_id_arrays CASCADE;

CREATE DOMAIN attributed_note_ids AS integer NOT NULL;
CREATE DOMAIN attributed_note_id_arrays AS integer[] NOT NULL;

CREATE OR REPLACE
FUNCTION from_attributed_note_id(attributed_note_ids) RETURNS integer AS $$
	SELECT $1::integer
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION from_attributed_note_id_array(attributed_note_id_arrays)
RETURNS integer[] AS $$
	SELECT $1::integer[]
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION to_attributed_note_id_array(integer[])
RETURNS attributed_note_id_arrays AS $$
	SELECT $1::attributed_note_id_arrays
$$ LANGUAGE sql;

DROP SEQUENCE IF EXISTS attributed_note_id_seq CASCADE;

CREATE SEQUENCE attributed_note_id_seq;

CREATE OR REPLACE
FUNCTION next_attributed_note_id() RETURNS attributed_note_ids AS $$
	SELECT nextval('attributed_note_id_seq')::attributed_note_ids
$$ LANGUAGE sql;

CREATE TABLE IF NOT EXISTS attributed_notes (
	id attributed_note_ids PRIMARY KEY DEFAULT next_attributed_note_id(),
	time_ event_times,
	author_id note_author_ids REFERENCES note_authors,
	note xml,
	features note_feature_sets DEFAULT empty_bitset()
);

ALTER SEQUENCE attributed_note_id_seq OWNED BY attributed_notes.id;

SELECT create_handles_for('attributed_notes');

-- * Provides

-- SELECT require_procedure('notes_on(regclass, integer)');
-- SELECT require_procedure('note_on(regclass, integer, note_author_ids, text)');
-- SELECT require_procedure('note_on(regclass, integer, text, text)');
