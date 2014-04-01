-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('name-oid-pairs.sql', '$Id');

-- cp name-id-pairs.sql oid-pairs.sql
-- %s/name_id_pair/name_oid_pair/g
-- %s/name_oid_pair_ids/oid/g
-- %s/maybe_oid/oid/g
-- g/CREATE DOMAIN oid AS/d

-- Row type name_oid_pairs with associated functions and operators

-- ** Copyright

-- Copyright (c) 2005 - 2009, J. Greg Davidson, all rights reserved.
-- Although it is my intention to make this code available
-- under a Free Software license when it is ready, this code
-- is currently not to be copied nor shown to anyone without
-- my permission in writing.

-- ** TYPE name_oid_pairs

CREATE TABLE name_oid_pairs (
	pair_id oid,
	pair_name text NOT NULL
);
COMMENT ON TABLE name_oid_pairs IS
'mostly for the type, not the table';

CREATE FUNCTION name_oid_pair(text, oid)
RETURNS name_oid_pairs AS $$
	SELECT ROW($2, $1)::name_oid_pairs
$$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION name_oid_pairs_name(name_oid_pairs)
RETURNS text AS $$
	SELECT $1.pair_name
$$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION name_oid_pairs_id(name_oid_pairs)
RETURNS oid AS $$
	SELECT $1.pair_id
$$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION name_oid_pairs_cmp(name_oid_pairs, name_oid_pairs)
RETURNS int4 AS $$
	SELECT CASE
		WHEN ($1).pair_id < ($2).pair_id THEN -1
		WHEN ($1).pair_id > ($2).pair_id THEN 1
		ELSE CASE
			WHEN ($1).pair_name < ($2).pair_name THEN -1
			WHEN ($1).pair_name > ($2).pair_name THEN 1
			ELSE 0
		END
	END
$$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION name_oid_pairs_lt(name_oid_pairs, name_oid_pairs)
RETURNS bool AS $$ SELECT name_oid_pairs_cmp($1, $2) < 0 $$
LANGUAGE SQL IMMUTABLE;

CREATE FUNCTION name_oid_pairs_le(name_oid_pairs, name_oid_pairs)
RETURNS bool AS $$ SELECT name_oid_pairs_cmp($1, $2) <= 0 $$
LANGUAGE SQL IMMUTABLE;

CREATE FUNCTION name_oid_pairs_eq(name_oid_pairs, name_oid_pairs)
RETURNS bool AS $$ SELECT name_oid_pairs_cmp($1, $2) = 0 $$
LANGUAGE SQL IMMUTABLE;

CREATE FUNCTION name_oid_pairs_neq(name_oid_pairs, name_oid_pairs)
RETURNS bool AS $$ SELECT name_oid_pairs_cmp($1, $2) <> 0 $$
LANGUAGE SQL IMMUTABLE;

CREATE FUNCTION name_oid_pairs_ge(name_oid_pairs, name_oid_pairs)
RETURNS bool AS $$ SELECT name_oid_pairs_cmp($1, $2) >= 0 $$
LANGUAGE SQL IMMUTABLE;

CREATE FUNCTION name_oid_pairs_gt(name_oid_pairs, name_oid_pairs)
RETURNS bool AS $$ SELECT name_oid_pairs_cmp($1, $2) > 0 $$
LANGUAGE SQL IMMUTABLE;

CREATE OPERATOR < (
	 leftarg = name_oid_pairs, rightarg = name_oid_pairs,
	 procedure = name_oid_pairs_lt,
	 commutator = > , negator = >= ,
	 restrict = scalarltsel, join = scalarltjoinsel
);

CREATE OPERATOR <= (
	 leftarg = name_oid_pairs, rightarg = name_oid_pairs,
	 procedure = name_oid_pairs_le,
	 commutator = >= , negator = > ,
	 restrict = scalarltsel, join = scalarltjoinsel
);

CREATE OPERATOR = (
	 leftarg = name_oid_pairs, rightarg = name_oid_pairs,
	 procedure = name_oid_pairs_eq,
	 commutator = = ,
	 negator = <> ,
	 restrict = eqsel, join = eqjoinsel
);

CREATE OPERATOR <> (
	 leftarg = name_oid_pairs, rightarg = name_oid_pairs,
	 procedure = name_oid_pairs_neq,
	 commutator = <> ,
	 negator = = ,
	 restrict = neqsel, join = neqjoinsel
);

CREATE OPERATOR >= (
	 leftarg = name_oid_pairs, rightarg = name_oid_pairs,
	 procedure = name_oid_pairs_ge,
	 commutator = <= , negator = < ,
	 restrict = scalargtsel, join = scalargtjoinsel
);

CREATE OPERATOR > (
	 leftarg = name_oid_pairs, rightarg = name_oid_pairs,
	 procedure = name_oid_pairs_gt,
	 commutator = < , negator = <= ,
	 restrict = scalargtsel, join = scalargtjoinsel
);

-- now we can make the operator class
CREATE OPERATOR CLASS name_oid_pairs_ops
		DEFAULT FOR TYPE name_oid_pairs USING btree AS
				OPERATOR        1       < ,
				OPERATOR        2       <= ,
				OPERATOR        3       = ,
				OPERATOR        4       >= ,
				OPERATOR        5       > ,
				FUNCTION        1       name_oid_pairs_cmp(name_oid_pairs, name_oid_pairs);
