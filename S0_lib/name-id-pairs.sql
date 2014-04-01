-- * Header  -*-Mode: sql;-*-
\ir settings.sql
SELECT set_file('name-id-pairs.sql', '$Id');

-- Row type name_id_pairs with associated functions and operators

-- ** Copyright

-- Copyright (c) 2005 - 2009, J. Greg Davidson.
-- You may use this file under the terms of the
-- GNU AFFERO GENERAL PUBLIC LICENSE 3.0
-- as specified in the file LICENSE.md included with this distribution.
-- All other use requires my permission in writing.

-- ** TYPE name_id_pairs

CREATE DOMAIN name_id_pair_ids AS integer NOT NULL;
CREATE DOMAIN maybe_name_id_pair_ids AS integer;

CREATE TABLE name_id_pairs (
	pair_id name_id_pair_ids,
	pair_name text NOT NULL
);
COMMENT ON TABLE name_id_pairs IS
'mostly for the type, not the table';

CREATE FUNCTION name_id_pair(text, name_id_pair_ids)
RETURNS name_id_pairs AS $$
	SELECT ROW($2, $1)::name_id_pairs
$$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION name_id_pairs_name(name_id_pairs)
RETURNS text AS $$
	SELECT $1.pair_name
$$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION name_id_pairs_id(name_id_pairs)
RETURNS name_id_pair_ids AS $$
	SELECT $1.pair_id
$$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION name_id_pairs_cmp(name_id_pairs, name_id_pairs)
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

CREATE FUNCTION name_id_pairs_lt(name_id_pairs, name_id_pairs)
RETURNS bool AS $$ SELECT name_id_pairs_cmp($1, $2) < 0 $$
LANGUAGE SQL IMMUTABLE;

CREATE FUNCTION name_id_pairs_le(name_id_pairs, name_id_pairs)
RETURNS bool AS $$ SELECT name_id_pairs_cmp($1, $2) <= 0 $$
LANGUAGE SQL IMMUTABLE;

CREATE FUNCTION name_id_pairs_eq(name_id_pairs, name_id_pairs)
RETURNS bool AS $$ SELECT name_id_pairs_cmp($1, $2) = 0 $$
LANGUAGE SQL IMMUTABLE;

CREATE FUNCTION name_id_pairs_neq(name_id_pairs, name_id_pairs)
RETURNS bool AS $$ SELECT name_id_pairs_cmp($1, $2) <> 0 $$
LANGUAGE SQL IMMUTABLE;

CREATE FUNCTION name_id_pairs_ge(name_id_pairs, name_id_pairs)
RETURNS bool AS $$ SELECT name_id_pairs_cmp($1, $2) >= 0 $$
LANGUAGE SQL IMMUTABLE;

CREATE FUNCTION name_id_pairs_gt(name_id_pairs, name_id_pairs)
RETURNS bool AS $$ SELECT name_id_pairs_cmp($1, $2) > 0 $$
LANGUAGE SQL IMMUTABLE;

CREATE OPERATOR < (
	 leftarg = name_id_pairs, rightarg = name_id_pairs,
	 procedure = name_id_pairs_lt,
	 commutator = > , negator = >= ,
	 restrict = scalarltsel, join = scalarltjoinsel
);

CREATE OPERATOR <= (
	 leftarg = name_id_pairs, rightarg = name_id_pairs,
	 procedure = name_id_pairs_le,
	 commutator = >= , negator = > ,
	 restrict = scalarltsel, join = scalarltjoinsel
);

CREATE OPERATOR = (
	 leftarg = name_id_pairs, rightarg = name_id_pairs,
	 procedure = name_id_pairs_eq,
	 commutator = = ,
	 negator = <> ,
	 restrict = eqsel, join = eqjoinsel
);

CREATE OPERATOR <> (
	 leftarg = name_id_pairs, rightarg = name_id_pairs,
	 procedure = name_id_pairs_neq,
	 commutator = <> ,
	 negator = = ,
	 restrict = neqsel, join = neqjoinsel
);

CREATE OPERATOR >= (
	 leftarg = name_id_pairs, rightarg = name_id_pairs,
	 procedure = name_id_pairs_ge,
	 commutator = <= , negator = < ,
	 restrict = scalargtsel, join = scalargtjoinsel
);

CREATE OPERATOR > (
	 leftarg = name_id_pairs, rightarg = name_id_pairs,
	 procedure = name_id_pairs_gt,
	 commutator = < , negator = <= ,
	 restrict = scalargtsel, join = scalargtjoinsel
);

-- now we can make the operator class
CREATE OPERATOR CLASS name_id_pairs_ops
		DEFAULT FOR TYPE name_id_pairs USING btree AS
				OPERATOR        1       < ,
				OPERATOR        2       <= ,
				OPERATOR        3       = ,
				OPERATOR        4       >= ,
				OPERATOR        5       > ,
				FUNCTION        1       name_id_pairs_cmp(name_id_pairs, name_id_pairs);
