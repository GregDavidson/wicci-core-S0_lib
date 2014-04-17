# Wicci Project Core

## A pun on Wiki, pronounced like Witchy

Possible Acronyms:

Web Interface to Collaborative Community Intelligence

## Directory: ~/.Wicci/Core
Contains: Source files for Wicci Core within PostgreSQL

### Core Directory Files:

|FILE			| DESCRIPTION
|-----------------------|----------
|README			| this file
|Makefile		| coordinates lower-level makefiles
|Makefile.wicci		| included by all wicci makefiles
|WICCI-CORE-DIRS	| list of core source directories
|WICCI-SQL-DIRS		| list of core SQL source directories
|WICCI-SOME-DIRS	| subset of WICCI-SQL-DIRS for `make rebuild-some'
|TAGS			| emacs TAGS file of all .c, .h, .sql files in Core
|TAGS-c			| emacs TAGS file of all .c, .h files in Core
|TAGS-sql		| emacs TAGS file .sql files in Core
|settings.sql		| included at beginning of all wicci .sql files
|settings+sizes.sql	| includes settings.sql + data structure sizes

### Source subdirectories:

|DIRECTORY	| DESCRIPTION
|---------------|----------
|C_lib/		| C language support library
|S0_lib/	| SQL language support library
|S1_refs/	| Server Programming eXtensions including
|               | Refs = Tagged/Typed Object References
|S2_core/	| Ref Types for Unique Names and Environment Contexts
|S3_more/	| Ref Types for Arrays, Texts & Scalars
|S4_doc/	| Ref Types for Hierarchical Documents
|S5_xml/	| Ref Types for URIs, XML and HTML
|S6_http/	| Ref Types for HyperText
|S7_wicci/	| the Wicci Server Model
|XFiles/	| miscellaneous files by type

### Important Sibling Directories and Files:

|FILE or DIRECTORY		| DESCRIPTION
|-------------------------------|----------
|..				| Wicci Project Directory
|../Tools/bin			| Wicci utility programs (mostly scripts)
|../Tools/lib/wicci.sh		| source to create Wicci environment
|../Tools/bin/go-wicci		| source to start hacking on the Wicci
|../Make/DB-NAME/refs-sizes.sql	| data structure sizes


The S?_* directory names are also the names of SQL Schemas.

### More Source subdirectories:

|Directory		| DESCRIPTION
|-----------------------|----------
|Test/	| Miscellanea for Testing
|Shim/	| a thin httpd reverse proxy, front-end for the Wicci

### External references:

|FILE or DIRECTORY			| DESCRIPTION
|-----------------------|----------
| /Shared/Lib/SQL/Util/SQL	| Some utilities shared with other projects
| ~/.Wicci			| A symlink to the Wicci Project Directory
| /usr/local/pgsql		| A symlink to the local PostgreSQL
| tomboy notes			| Older notes to mine for gold
