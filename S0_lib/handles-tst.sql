-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('handles-tst.sql', '$Id');

--	PostgreSQL Utility Row Handles Test

-- ** Copyright

--	Copyright (c) 2005, 2006, J. Greg Davidson.
--	This code may be freely used by CreditLink Corporation
--	for their internal business needs but not redistributed
--	to third parties.

-- * create_meta_func_default_handle_for

SELECT handle_table_for_text('meta_entity_traits');

SELECT create_handle_table_for('meta_entity_traits');

SELECT create_handle_table_for('table_with_2_primaries');

-- * create_meta_handle_table_for

SELECT test_func(
	'create_handle_table_for(regclass, meta_columns[])',
	meta_table_text(handle_meta_table_('meta_entity_traits', colms)),
$$CREATE TABLE meta_entity_traits_row_handles (
	handle handles NOT NULL UNIQUE,
	entity meta_entities PRIMARY KEY  REFERENCES meta_entity_traits(entity)ON DELETE CASCADE
);
$$
) FROM primary_meta_column_array('meta_entity_traits') colms;

SELECT test_func(
	'create_handle_table_for(regclass, meta_columns[])',
	handle_table_for_text('table_with_2_primaries'),
$$CREATE TABLE table_with_2_primaries_row_handles (
	handle handles NOT NULL UNIQUE,
	i integer,
	n text,
	 PRIMARY KEY(i, n),
	 FOREIGN KEY(i, n) REFERENCES table_with_2_primaries(i, n)ON DELETE CASCADE
);
$$
) FROM primary_meta_column_array('table_with_2_primaries') colms;;

-- * further testing

SELECT create_handles_plus_for('meta_entity_traits');

SELECT create_handles_plus_for('table_with_2_primaries');

-- * create_meta_func_set_handle_for
