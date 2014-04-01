-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('module-deps-schema.sql', '$Id');

-- Manage module contents and dependencies

-- ** Copyright

-- Copyright (c) 2005 - 2009, J. Greg Davidson.

-- Eventually I would like to have more attributes associated with these
-- various entities: modules, functions, classes.

-- * Definitions

-- * module contents and dependencies

CREATE TABLE IF NOT EXISTS module_provided_entities (
	provider module_ids NOT NULL REFERENCES modules ON DELETE CASCADE,
	entity oid PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS module_required_entities (
	requiring_module module_ids NOT NULL REFERENCES modules ON DELETE CASCADE,
	required_entity OID NOT NULL,
	PRIMARY KEY(requiring_module, required_entity)
);

CREATE TABLE IF NOT EXISTS module_required_modules (
	requiring module_ids REFERENCES modules ON DELETE CASCADE,
	required module_ids REFERENCES modules ON DELETE CASCADE,
	PRIMARY KEY(requiring, required),
	CONSTRAINT required_modules_non_reflexive CHECK(requiring != required)
);

-- Constraints to add:
-- entities are never required by the module which provides them
-- entities are never provided by the module which requires them

-- Moving from module to entity requirements
-- Ideally all module requirements would be inferred

-- Moving to hierarchical packages
-- Modules would require packages
-- Packages would consist of modules
-- Within a package, module-module dependencies are used.
-- Outside a package, only current-module to other-package
-- could be used.
-- Can simulate this by having a module in each package
-- which has a simple name and is simply a file with
-- dependencies on all of the other modules within that
-- package!

-- Possibly adding entity-to-entity requirements
-- Can't check ahead of time, so not as useful
-- module_provides could set current_entity to make it
-- easier to follow a definition with the required entities.

CREATE TABLE IF NOT EXISTS module_entity_required_entities (
	requiring OID REFERENCES module_provided_entities,
	required OID REFERENCES module_provided_entities,
	PRIMARY KEY(requiring, required),
	CONSTRAINT required_modules_non_reflexive CHECK(requiring != required)
);
