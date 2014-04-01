-- * Header  -*-Mode: sql;-*-

\cd
\cd .Wicci/Core/S0_lib
\i ../settings.sql

SELECT set_schema_path('s0_lib', 'public');

SELECT ensure_schema_ready();
