-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('notes-tst.sql', '$Id');

-- NEEDS UPDATING! NO LONGER WORKS!!!

--	PostgreSQL Row Notes Utilities Test Code

-- ** Copyright

--	Copyright (c) 2005, 2006, J. Greg Davidson, all rights reserved.
--	Although it is my intention to make this code available
--	under a Free Software license when it is ready, this code
--	is currently not to be copied nor shown to anyone without
--	my permission in writing.

-- This module provides machinery for attaching timestamped and
-- attributed notes associated with specific rows of any table.

-- ** Tests

CREATE OR REPLACE
FUNCTION make_note_author(note_author_ids, text) RETURNS boolean AS $$
BEGIN
	BEGIN
		INSERT INTO note_authors(id) VALUES ($1);
		INSERT INTO note_author_names(id, name) VALUES ($1, $2);
	EXCEPTION
		WHEN OTHERS THEN
				RETURN false;
	END;
	RETURN true;
END
$$ LANGUAGE plpgsql STRICT;

SELECT make_note_author(1, 'jgd');

SELECT note_on( note_authors_id('jgd'), 'jgd', 'the proud author');

SELECT note_on(
	'note_author_notes'::regclass,
	note_authors_id('jgd')::integer,
	'jgd', 'a PostgreSQL root user'
 );

 SELECT array_length( notes_on( note_authors_id('jgd') ) ) = 2;

 SELECT array_length(
 	notes_on( 'note_author_notes'::regclass, note_authors_id('jgd') )
) = 2;

 SELECT text_notes_on( note_authors_id('jgd') ) =
	 text_notes_on( 'note_author_notes'::regclass, note_authors_id('jgd') );

SELECT drop_note_on( note_authors_id('jgd'), 2 );

 SELECT array_length( notes_on( note_authors_id('jgd') ) ) = 1;

SELECT note_on( note_authors_id('jgd'), 'jgd', 'a postgreSQL root user');

SELECT array_length( notes_on( note_authors_id('jgd') ) ) = 2;

SELECT drop_note_on(
	'note_author_notes'::regclass,
	note_authors_id('jgd')::integer,
	2
);

SELECT array_length( notes_on( note_authors_id('jgd') ) ) = 1;

SELECT note_on( note_authors_id('jgd'), 'jgd', 'who will read this note?');

SELECT drop_notes_on( note_authors_id('jgd') );

SELECT array_length( notes_on( note_authors_id('jgd') ) ) = 0;

SELECT note_on( note_authors_id('jgd'), 'jgd', 'note 1');
SELECT note_on( note_authors_id('jgd'), 'jgd', 'note 2');
SELECT note_on( note_authors_id('jgd'), 'jgd', 'note 3');

SELECT drop_notes_on(
	'note_author_notes'::regclass,
	note_authors_id('jgd')::integer
);

SELECT array_length( notes_on( note_authors_id('jgd') ) ) = 0;
