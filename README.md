# Wicci Project Core & Key Materials

See the
[Wicci Project Page](https://gregdavidson.github.io/wicci-core-S0_lib/)
for an overview and index of the whole project and its 12
constituent repositories.

## Features of the Wicci System

The Wicci System consists of PostgreSQL extensions providing:

* Metaprogramming for Generics and Boilerplate elimination
* Strongly Typed References with Generalization
* Dispatching of Operator Functions to Method Functions
* Monotonic Classes and NULL-mitigation
* Immutable Documents supporting Multiple, Collaborative Views
* An extensible Web-Server implemented *in the database*
* Support for Business Logic *in the database*
* And more!

## What's a Wicci System again and what's with the name?

The Wicci System is an Extended Relational Database System
with Web interface which supports putting more or even all
of a project's business logic *in the database*.

The Wicci System is currently implemented as PostgreSQL
extensions although it could be ported to work with other
RDBMSs.

The original Wicci System was designed as a platform to
allow building much better community Wiki systems.  The
Wicci system is an excellent platform for Wikis and an
unlimited range of other database-oriented applications and
services which need to support

* documents with multiple views
* forks and joins
* community collaboration
* etc.

The word *Wicci* is a pun on *Wiki*, pronounced like *witchy*.

Possible Acronyms:

* Web Interface to Collaborative Community Intelligence
* Web Intelligent Collaborative Communication Infrastructure

These diagrams may help clarify these descriptions:

* [Wicci Diagrams](http://ngender.net/wicci/diagram)

## Key Directories

| TOP-DIRECTORY	| SUB-DIRECTORY	|	DESCRIPTION
|--------------------------|---------------------------|----------
| Shim		| Wicci-Shim-Rust	| relays HTTP traffic between browsers & database
| XFiles	|					| web documents: HTML, CSS, JS, SVG, etc
| Make		| wicci1		| database build artifacts
| Tools		|					| utility Shell Scripts
| Doc		|					| project documentation
| Core		|					| C and (mostly) SQL sources
|				| C_lib			| C language support library
| 				| S0_lib		| SQL language support library
| 				| S1_refs		| Server Programming eXtensions including
|				| 					| Refs = Tagged/Typed Object References
| 				| S2_core		| Ref Types for Unique Names and Environment Contexts
| 				| S3_more	| Ref Types for Arrays, Texts & Scalars
| 				| S4_doc		| Ref Types for Hierarchical Documents
| 				| S5_xml		| Ref Types for URIs, XML and HTML
| 				| S6_http		| Ref Types for HTTP
| 				| S7_wicci	| the Wicci Server Model and HTTPD

The S[0-7]_* directory names are also the names of SQL Schemas.

## Directory: ~/.Wicci/Core: Some Key Files

|FILE						| DESCRIPTION
|--------------------------|----------
|README					| this file
|Makefile					| coordinates lower-level makefiles
|Makefile.wicci			| included by all wicci makefiles
|WICCI-CORE-DIRS	| list of core source directories
|WICCI-SQL-DIRS		| list of core SQL source directories
|WICCI-SOME-DIRS	| subset of WICCI-SQL-DIRS for `make rebuild-some'
|TAGS						| emacs TAGS file of all .c, .h, .sql files in Core
|TAGS-c					| emacs TAGS file of all .c, .h files in Core
|TAGS-sql					| emacs TAGS file .sql files in Core
|settings.sql				| included at beginning of all wicci .sql files
|settings+sizes.sql	| includes settings.sql + data structure sizes

## Non-Core: Key Sibling Directories and Files:

|	FILE or DIRECTORY	| DESCRIPTION
|------------------------------|----------
|..									| Wicci Project Directory
|../Tools/bin					| Wicci utility programs (mostly scripts)
|../Tools/lib/wicci.sh		| source to create Wicci environment
|../Tools/bin/go-wicci		| source to start hacking on the Wicci
|../Make/DB-NAME/refs-sizes.sql	| data structure sizes

## Out-Of-Tree References:

|FILE or DIRECTORY			| DESCRIPTION
|-----------------------|----------
| /Shared/Lib/SQL/Util/SQL	| Some utilities shared with other projects
| ~/.Wicci			| A symlink to the Wicci Project Directory
| /usr/local/SW/pgsql		| A symlink to the local PostgreSQL
| tomboy notes			| Older notes to mine for gold

To build the full Wicci you must check out the 10 key projects and
arrange them accordingly:

	$ find * -name .git
	Core/.git
	Core/S1_refs/.git
	Core/S2_core/.git
	Core/S3_more/.git
	Core/S4_doc/.git
	Core/S5_xml/.git
	Core/S6_http/.git
	Core/S7_wicci/.git
	Doc/PublishedDocs/.git (optional)
	Shim/Wicci-Shim-Rust/.git
	Tools/.git

Other projects may only need a subset of these materials.
The higher-numbered Schemas depend on the lower-numbered
Schemas, so if, e.g., you want the functionality of S4_doc,
you will need Core (which contains C_lib and S0_lib),
S1_refs, S2_core and S3_more.
