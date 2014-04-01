-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('debug-schema.sql', '$Id');


--	PostgreSQL Utilities
--	Debugging Schema

-- ** Copyright

--	Copyright (c) 2005, 2006, J. Greg Davidson, all rights reserved.
--	Although it is my intention to make this code available
--	under a Free Software license when it is ready, this code
--	is currently not to be copied nor shown to anyone without
--	my permission in writing.

-- ** Provides

-- * Debugging Facilities

-- ** TABLE debug_on_oids
CREATE TABLE IF NOT EXISTS debug_on_oids (
	id Oid PRIMARY KEY
);
