# Wicci Project Core

## Core and Schema 0 of the Wicci System

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

The Wicci System is an Extended Relational Database System with Web interface which
supports putting more or even all of a project's business logic *in the database*.

The Wicci System is currently implemented as PostgreSQL extensions although it could be ported to work with other RDBMSs.

The original Wicci System was designed as a platform to allow building much better community Wiki systems.
The Wicci system is an excellent platform for Wikis and an unlimited range of other database-oriented applications and services which need to support

* documents with multiple views
* forks and joins
* community collaboration
* etc.

The word *Wicci* is a pun on *Wiki*, pronounced like *witchy*.

Possible Acronyms:

* Web Interface to Collaborative Community Intelligence

These diagrams may help clarify these descriptions:

* [Wicci Diagrams](http://ngender.net/wicci/diagram)

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

This Git repository contains two of the required 11 parts required
to build and install the Wicci System.  All but two of the parts are
now on GitHub.  Still missing are

* TOols - he Wicci support scripts, including scripts for correctly building and installing PostgreSQL
* The Shim - the key Reverse Proxy Server which relays HTTP requests to the database
