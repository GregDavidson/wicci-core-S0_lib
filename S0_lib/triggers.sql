-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('misc.sql', '$Id');

--	PostgreSQL triggers and meta-trigger code

-- ** Copyright

--	Copyright (c) 2005, 2006, J. Greg Davidson.
--	This code may be freely used by CreditLink Corporation
--	for their internal business needs but not redistributed
--	to third parties.

-- upgrade to use meta_code.sql:create_trigger!!


-- * Trigger Meta Code Generation Functions

CREATE OR REPLACE FUNCTION create_trigger_text(
	regclass, text, boolean, regprocedure, VARIADIC text[]
) RETURNS text AS $$
	SELECT 'CREATE TRIGGER ' || $2 || E'\n  '
	 || CASE WHEN $3 THEN 'BEFORE ' ELSE 'AFTER ' END
	 || array_to_string($5, ' OR ') || ' ON ' || $1::text || E'\n  '
	 || 'FOR EACH ROW EXECUTE PROCEDURE ' || $4::text
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION before_trigger_text(
	regclass, text, regprocedure, VARIADIC text[]
) RETURNS text AS $$
	SELECT create_trigger_text( $1, $2, true, $3, VARIADIC $4 )
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION after_trigger_text(
	regclass, text, regprocedure, VARIADIC text[]
) RETURNS text AS $$
	SELECT create_trigger_text( $1, $2, true, $3, VARIADIC $4 )
$$ LANGUAGE sql;

CREATE OR REPLACE
FUNCTION drop_trigger_text(regclass, text) RETURNS text AS $$
	SELECT 'DROP TRIGGER IF EXISTS ' || $2 || ' ON ' || $1::text || ' CASCADE';
$$ LANGUAGE sql;

-- * Generic Trigger Functions

CREATE OR REPLACE
FUNCTION prohibition_trigger() RETURNS trigger AS $$
	BEGIN
		RAISE EXCEPTION 'Operation % on table % prohibited!',
			TG_OP, TG_TABLE_NAME;
		RETURN NULL;
	END
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION prohibition_trigger() IS
'A trigger to attach to a table to prohibit specific operations.';

CREATE OR REPLACE
FUNCTION abstract_table_trigger() RETURNS trigger AS $$
	BEGIN
		 RAISE EXCEPTION 'Operation % on abstract table % prohibited',
			 TG_OP, TG_TABLE_NAME;
		RETURN NULL;
	END
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION abstract_table_trigger() IS
'A trigger to attach to an abstract table which will
generate an error on ANY operation.';

-- * Abstract Trigger Meta Code

CREATE OR REPLACE
FUNCTION declare_abstract(regclass) RETURNS regclass AS $$
DECLARE
	this regprocedure := 'declare_abstract(regclass)';
	name_ text := quote_ident($1::text || '_abstract_trigger');
	drop_result boolean := meta_execute(this, drop_trigger_text($1, name_));
	create_result boolean := meta_execute(this, before_trigger_text(
		$1, name_, 'abstract_table_trigger()', 'INSERT', 'UPDATE', 'DELETE'
	));
BEGIN RETURN $1; END
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION declare_abstract(regclass) IS
'Attaches a trigger prohibiting inserts.';

-- * Updates Prohibited Code

CREATE OR REPLACE
FUNCTION declare_monotonic(regclass) RETURNS regclass AS $$
DECLARE
	this regprocedure := 'declare_monotonic(regclass)';
	name_ text := quote_ident($1::text || '_no_update_trigger');
	drop_result boolean := meta_execute(this, drop_trigger_text($1, name_));
	create_result boolean := meta_execute(this, before_trigger_text(
		$1, name_, 'prohibition_trigger()', 'UPDATE'
	));
BEGIN RETURN $1; END
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION declare_monotonic(regclass) IS
'Attaches a trigger prohibiting updates.';
