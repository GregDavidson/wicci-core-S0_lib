CREATE TYPE arg_modes AS ENUM (
	'arg_modes_in_',
	'arg_modes_out_',
	'arg_modes_inout_'
);

CREATE TABLE meta_vals (
	name_ text NOT NULL,
	type_ regtype NOT NULL,
	default_ text,
	mode_ arg_modes
);

SELECT ROW('code', 'integer', '', 'arg_modes_out_')::meta_vals;

SELECT x.name_, x.type_, x.default_, x.mode_
FROM CAST(
	ROW('code', 'integer', '', 'arg_modes_out_') AS meta_vals
) x;
-- no bug!
