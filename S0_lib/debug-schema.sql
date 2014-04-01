-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('debug-schema.sql', '$Id');


--	PostgreSQL Utilities
--	Debugging Schema

-- ** Copyright

--	Copyright (c) 2005, 2006, J. Greg Davidson.
--	You may use this file under the terms of the
--	GNU AFFERO GENERAL PUBLIC LICENSE 3.0
--	as specified in the file LICENSE.md included with this distribution.
--	All other use requires my permission in writing.

-- ** Provides

-- * Debugging Facilities

-- ** TABLE debug_on_oids
CREATE TABLE IF NOT EXISTS debug_on_oids (
	id Oid PRIMARY KEY
);
