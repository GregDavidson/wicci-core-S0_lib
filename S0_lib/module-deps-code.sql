-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('module-deps-code.sql', '$Id');

-- Utility for managing module dependencies

-- ** Copyright

-- Copyright (c) 2005 - 2009, J. Greg Davidson.

-- * module_file_id and require_module functions

CREATE OR REPLACE
VIEW the_modules AS
	SELECT module_id, schema_name, module_name,
	file_name, nice_rev(rev) AS "revision"
	FROM modules_schemas;

-- ** module_required_modules

CREATE OR REPLACE
VIEW the_required_modules(requiring_name_id, required_name_id) AS
SELECT r_ing.module_id as "requiring id",
	r_ing.schema_name as "requiring schema",
	r_ing.module_name as "requiring name",
	r_ing.revision as "requiring revision",
	r_ed.module_id as "required id",
	r_ed.schema_name as "required schema",
	r_ed.module_name as "required name",
	r_ed.revision as "required revision"
FROM module_required_modules m_r_m, the_modules r_ing, the_modules r_ed
WHERE m_r_m.requiring = r_ing.module_id AND m_r_m.required = r_ed.module_id;

-- ~~~ module_requires_module(requiring, required) -> description of required
CREATE OR REPLACE
FUNCTION module_requires_module(module_ids, module_ids)
RETURNS TEXT AS $$
DECLARE
	the_rev TEXT;
	kilroy_was_here boolean := false;
	this regprocedure
		:= 'module_requires_module(module_ids, module_ids)';
BEGIN
	LOOP
		PERFORM * FROM module_required_modules
		WHERE requiring = $1 AND required = $2;
		IF FOUND THEN
				RETURN module_nice_text($2);
		END IF;
		IF kilroy_was_here THEN
			RAISE EXCEPTION '% looping with % %', this, $1, $2;
		END IF;
		kilroy_was_here := true;
		BEGIN
			INSERT INTO module_required_modules(requiring, required)
			VALUES($1, $2);
		EXCEPTION
			WHEN unique_violation THEN			-- another thread??
				RAISE NOTICE '% % % raised %!', this, $1, $2, 'unique_violation';
		END;
	END LOOP;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION module_requires_module(module_ids, module_ids) IS
'insert or check a module requirement relationship';

CREATE OR REPLACE
VIEW the_current_module AS
SELECT * FROM the_modules WHERE module_id = this_module();

CREATE OR REPLACE
FUNCTION require_module(module_names) RETURNS TEXT AS $$
	SELECT module_requires_module( this_module(), module_id($1) )
$$ LANGUAGE sql;
COMMENT ON FUNCTION require_module(module_names) IS
'check and record inter-module dependency, return description of required module';

-- * Summary views

-- these things depend on pg-meta which is not yet loaded!

-- CREATE OR REPLACE
-- VIEW the_module_entities(module, entity) AS
--   SELECT module_name(provider), entity_text(entity)
--   FROM module_provided_entities;

-- CREATE OR REPLACE
-- VIEW the_entities(module, entity) AS
--   SELECT module_name(provider), entity_kind(entity) || ' ' || entity_name(entity)
--   FROM module_provided_entities;

-- CREATE OR REPLACE
-- VIEW the_entities_required(requiring_module, requiring_entity, required_module, required_entity) AS
--   SELECT
--     module_name(requiring.provider) AS "requiring_module",
--     entity_kind(requiring.entity) || ' ' || entity_name(requiring.entity)
--       AS "requiring_entity",
--     module_name(required.provider) AS "required_module",
--     entity_kind(required.entity) || ' ' || entity_name(required.entity)
--       AS "required_entity"
--   FROM module_provided_entities requiring, module_provided_entities required,
--        module_entity_required_entities ent
--   WHERE requiring.entity = ent.requiring
--     AND required.entity = ent.required;

-- * module_provides function family

-- ** module_functions

-- ~~~ module_provides_entity(module, entity) -> void
CREATE OR REPLACE
FUNCTION module_provides_entity(module_ids, oid)
RETURNS void AS $$
DECLARE
	this regprocedure := 'module_provides_entity(module_ids, oid)';
BEGIN
	INSERT INTO module_provided_entities(provider, entity)
	VALUES($1, $2);
EXCEPTION
	WHEN unique_violation THEN	-- another thread?
		RAISE NOTICE '% % % raised %!', this, $1, $2, 'unique_violation';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE
FUNCTION provide_procedure(regprocedure) RETURNS TEXT AS $$
	SELECT module_provides_entity(this_module(), $1);
	SELECT $1::text
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION provide_type(regtype) RETURNS TEXT AS $$
	SELECT module_provides_entity(this_module(), $1);
	SELECT $1::text
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION provide_table(regclass) RETURNS TEXT AS $$
	SELECT module_provides_entity(this_module(), $1);
	SELECT $1::text
$$ LANGUAGE sql;

-- ~~~ module_requires_entity(module, entity) -> void
CREATE OR REPLACE
FUNCTION module_requires_entity(module_ids, oid)
RETURNS void AS $$
DECLARE
	this regprocedure := 'module_requires_entity(module_ids, oid)';
BEGIN
	INSERT INTO
		module_required_entities(requiring_module, required_entity)
		VALUES($1, $2);
EXCEPTION
	WHEN unique_violation THEN	-- another thread?
		RAISE NOTICE '% % % raised %!', this, $1, $2, 'unique_violation';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE
FUNCTION require_procedure(regprocedure) RETURNS TEXT AS $$
	SELECT module_requires_entity(this_module(), $1);
	SELECT $1::text
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION require_type(regtype) RETURNS TEXT AS $$
	SELECT module_requires_entity(this_module(), $1);
	SELECT $1::text
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION require_table(regclass) RETURNS TEXT AS $$
	SELECT module_requires_entity(this_module(), $1);
	SELECT $1::text
$$ LANGUAGE sql;

-- * Module Declarations

SELECT require_module('module-deps-schema');

-- sed -n -e 's/^FUNCTION \(.*(.*)\).*/SELECT require_procedure('\''\1'\'');/p' module-deps-code.sql

SELECT require_procedure('module_requires_module(module_ids, module_ids)');
SELECT require_procedure('require_module(module_names)');

SELECT require_procedure('module_provides_entity(module_ids, oid)');
SELECT require_procedure('require_procedure(regprocedure)');
SELECT require_procedure('require_type(regtype)');
SELECT require_procedure('require_table(regclass)');

SELECT require_procedure('module_requires_entity(module_ids, oid)');
SELECT require_procedure('require_procedure(regprocedure)');
SELECT require_procedure('require_type(regtype)');
SELECT require_procedure('require_table(regclass)');

-- rename require_procedure/type/table to provide_...
