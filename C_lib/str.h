/* File str.h - clarify '\0'-terminated strings.
 * J. Greg Davidson, April 1999, June 2006
 */

#ifndef C_STR_H
#define C_STR_H

/* Goals:
 * Distinguish '\0'-terminated strings from other char arrays and pointers
 * Distinguish NULL-terminated string vectors
 * Encourage non-modifiable (const) types
 * Distinguish use of modifiable string types
 * Bottom Line: Clarity, Consistency, Reliability!
*/

/* Note:
	(1) These definitions don't depend on each other
	(2) In case of identifier conflicts, you can either
		#define C_STR_PREFIX_REQUIRED
			or wrap an individual conflicting definition with
						an omit macro (as with Str below).

CStr		traditional C pointer to '\0' terminated string 
StrBuf		modifiable string buffer 
StrBufPtr	modifiable ptr into a StrBuf
StrPtr		modifiable ptr into '\0' terminated char array 
Str		'\0' terminated char array 
StrVec		NULL terminated array of strings 
Strs		const ptr into StrVec
StrVecPtr	modifiable ptr into StrVec
TmpStrPtr	pointer to temporary string

StrOrElse(s1, s2)	s1 if non-null, s2 otherwise
StrOrQ(sp)		StrOrElse(sp, "?")
StrPFOrQ(p,field)		StrOrElse(sp->field, "?")
StrPFFOrQ(p,f1, f2)		StrOrElse(sp->f1->f2, "?")
*/

// First define these things with longer "formal" names:

typedef char *UtilCStr;typedef char UtilStrBuf[];
typedef char *UtilStrBufPtr;
typedef const char *UtilStrPtr;
typedef const char UtilCStrBuf[];
typedef const char *const UtilStr;
typedef const char *const UtilStrVec[];
typedef const char *const *const UtilStrs;
typedef const char *const *UtilStrVecPtr;
typedef const char *UtilTmpStrPtr;
static inline UtilStrPtr UtilStrOrElse(UtilStrPtr s1, UtilStrPtr s2) {
	return s1 ? s1 : s2;
}
static inline UtilStrPtr UtilStrOrQ(UtilStrPtr sp) {
	return UtilStrOrElse(sp, "?");
}

#ifndef C_STR_PREFIX_REQUIRED

// Now give them shorter "informal" names:

typedef UtilCStr cstring;
typedef UtilStrBuf StrBuf;
typedef UtilStrBufPtr StrBufPtr;
typedef UtilStrPtr StrPtr;
#ifndef C_STR_OMIT_Str // in case of name conflict
		typedef UtilStr Str;
#endif
typedef UtilStrVec StrVec;
typedef UtilStrs Strs;
typedef UtilStrVecPtr StrVecPtr;
typedef UtilTmpStrPtr TmpStrPtr;
static inline UtilStrPtr StrOrElse(UtilStrPtr s1, UtilStrPtr s2) {
	return UtilStrOrElse(s1,s2);
}
static inline UtilStrPtr StrOrQ(UtilStrPtr sp) { return UtilStrOrQ(sp); }

#define PtrFieldOr0(ptr, field) ((ptr) ? (ptr)->field : 0)
#define Ptr2FieldsOr0(ptr, f1, f2) PtrFieldOr0(PtrFieldOr0(ptr, f1), f2)
#define StrPFOrQ(ptr, field) StrOrQ( PtrFieldOr0((ptr), field) )
#define StrPFFOrQ(ptr, f1, f2) StrOrQ( Ptr2FieldsOr0((ptr), f1, f2) )

#endif

#endif
