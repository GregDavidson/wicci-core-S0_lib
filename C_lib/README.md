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


debug.h: debugging support with some PostgreSQL features
debug-log.h: logging support with some PostgreSQL features
debug-log.c : owns FILE *debug_log_
debug-test: tests debug, debug-log w/o PostgreSQL
debug-test.log: output of debug-test
debug-test.log.good: expected output of debug-test

Note that there is a level-loop between the debugging code
here and supposedly later levels:
	debug.h uses FUNCTION_DEFINE from Spx/spx.h
	debug-log.h uses JoinCalls from TRef/tref.h
