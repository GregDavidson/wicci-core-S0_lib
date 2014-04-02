# Directory: ~/.Wicci/Core/C_lib

## Generic C support code used by the Wicci

| File	| Description
|------|----------------
| WICCI-C-FILES	| list of *.[hc] files used by the Wicci
| array.h	| some helpful array macros
| fmt.h	| portable printf format code support
| str.h	| some helpful string types and inline functions
| this-tag.h	| defines module tagging macros
| last-tag.h	| undefines module tagging macros

## Generic C support code NOT currently used by the Wicci

|File	| Description
|------|----------------
| dwim.h	| some techniques to consider using, not currently in use
| maybe-inline.h	| make datatypes fast AND private, alpha status

Some files providing debugging support have been moved to
S1_refs so that they can be controlled from PostgreSQL.
