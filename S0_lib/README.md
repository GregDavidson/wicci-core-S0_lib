# Wicci Project Schema 0

## SQL Support Library

These facilities provide a low-level framework which would be useful for many projects.

In addition to a number of handy functions, you may be
particularly interested in the support for

* SQL Integral Testing &amp; Test-Driven Development
* SQL Metaprogramming

You might want to study these files in dependency order.

Here are the first files to study:

| Special File		| Description
|-----------------------|------------
| settings.sql		| included by all but brama.sql
| ../settings.sql	| included by settings.sql AND brama.sql
| Makefile		| manages the build process
| ../Makefile.wicci		| included by Makefile
| Makefile.depends	| automatically built from WICCI-SQL-FILES
| WICCI-SQL-FILES	| lists files in dependency order
| brama.sql		| prepares an empty Wicci database

