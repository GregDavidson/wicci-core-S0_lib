/* File array.h - helpful array miscellanea
 * J. Greg Davidson, April 1999, June 2006
 */

#ifndef C_ARRAY_H
#define C_ARRAY_H

/* Goals:
 *	Clarity, Consistency, Reliability
 *
 * Pronunciation:
 *	RA = array, RAn = array and
 */

#define RA_LEN(array) ( sizeof(array) / sizeof(array[0]) )
#define RA_END(array) ( (array) + RA_LEN(array) )
#define RAnEND(array) (array) , RA_END(array)
#define RAnLEN(array) (array) , RA_LEN(array)
#define LENnRA(array) RA_LEN(array) , (array)
#define RA_FOR(ptr, array) \
	for ( (ptr) = (array) ; (ptr) < RA_END(array) ; (ptr)++ )


#if 0

/* Examples: */

		char my_array[100], *cp;
		RA_FOR(cp, my_array)
				doit(*cp);
		cin.getline( RAnLEN(my_array) );	/* getline gets 2 arguments */
		fill ( RAnEND(my_array), (StrPtr) 0 );	/* fill gets 3 arguments */

#endif

#endif
