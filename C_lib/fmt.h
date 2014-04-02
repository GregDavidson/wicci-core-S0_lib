/* File fmt.h - support for portable printf formats
 * J. Greg Davidson, December 2009
 */

#ifndef C_FMT_H
#define C_FMT_H

/* join and tag macros
	 - move to separate header??
	 - use vaiadic macro??
*/

#define C_JOIN1(x) x
#define C_JOIN2(x, y) x ## y
#define C_JOIN3(x, y, z) x ## y ## z
#define C_JOIN4(w, x, y, z) w ## x ## y ## z
#define C_JOIN5(v, w, x, y, z) v ## w ## x ## y ## z

#define C_JOIN_2(x, y) C_JOIN3(x, _,  y)
#define C_JOIN_3(x, y, z) C_JOIN5(x, _,  y, _, z)

/* tag_this */
#define TAG_THIS(NAME) C_JOIN_2(THIS_TAG,  NAME)
#define TagThis(Name) C_JOIN2(ThisTag, Name)
#define tag_this(name) C_JOIN_2(this_tag, name)

/* tag_last */

#define TAG_LAST(NAME) C_JOIN_2(LAST_TAG, NAME)
#define TagLast(Name) C_JOIN2(LastTag, Name)
#define tag_last(name) C_JOIN_2(last_tag, name)


/* We need to be able to construct printf formats
	 for our types which are portable and clear,
	 especially for use in debugging.
 * We will use these conventions:
 - Bare (unlabeled, unpadded) format macros are spelled <type>_FMT__
 - Snug (labeled, unpadded) format macros are spelled <type>_FMT_
 - Full (labelled, padded) format macros are spelled <type>_FMT
 - Casting macros (often needed for portability) are spelled <type>_VAL(<arg>)
 * For consistency of padding and labeling, build your <type>_FMT macro
	 using the provided FMT* macros.
 * Bottom Line: Clarity, Portability, Reliability!
 */

#define FMT_PAD(fmt) " " fmt
#define FMT_PAD2_(fmt1, fmt2) fmt1 " " fmt2
#define FMT_PAD2(fmt1, fmt2) FMT_PAD(FMT_PAD2_(fmt1, fmt2))
#define FMT_PAD3_(f1, f2, f3) f1 " " f2 " " f3
#define FMT_PAD3(f1, f2, f3) FMT_PAD( FMT_PAD3_(f1, f2, f3) )
#define FMT_PAD4_(f1, f2, f3,f4) FMT_PAD2_( FMT_PAD2_(f1, f2), FMT_PAD2_(f3,f4) )
#define FMT_PAD4(f1, f2, f3,f4) FMT_PAD( FMT_PAD4_(f1, f2, f3, f4) )
#define FMT_LF_(label, fmt) FMT_PAD2_(#label, fmt)
#define FMT_LF(label, fmt) FMT_PAD( FMT_LF_(label, fmt) )
#define FMT_lf_(label, fmt) #label "=" fmt
#define FMT_lf(label, fmt) FMT_PAD( FMT_lf_(label, fmt) )
#define  FMT_LF2_(label, fmt1, fmt2)  FMT_PAD3_(#label, fmt1, fmt2)
#define  FMT_LF2(label, fmt1, fmt2)  FMT_PAD(FMT_LF2_(label, fmt1, fmt2))
#define  FMT_LF3_(label, f1, f2, f3)  FMT_PAD4_(#label, f1, f2, f3)
#define  FMT_LF3(label, f1, f2, f3)  FMT_PAD( FMT_LF3_(label, f1, f2, f3) )

#define CAST_VAL(type, val) ( (type) (val) )


#if __STDC_VERSION__ >= 199901L

// size_t
#define C_SIZE_FMT__ "%zu"
#define C_SIZE_FMT_(label) FMT_LF_(label, C_SIZE_FMT__)
#define C_SIZE_FMT(label) FMT_LF(label, C_SIZE_FMT__)
#define C_SIZE_VAL(val) (val)

// ptrdiff_t
#define C_PTRDIFF_FMT__ "%zu"
#define C_PTRDIFF_FMT_(label) FMT_LF_(label, C_PTRDIFF_FMT__)
#define C_PTRDIFF_FMT(label) FMT_LF(label, C_PTRDIFF_FMT__)
#define C_PTRDIFF_VAL(val) (val)

#else

#include <stdint.h>
#include <inttypes.h>

/* size_t */
#define C_SIZE_FMT__ PRIuPTR
#define C_SIZE_FMT_(label) FMT_LF_(label, C_SIZE_FMT__)
#define C_SIZE_FMT(label) FMT_LF(label, C_SIZE_FMT__)
#define C_SIZE_VAL(val) CAST_VAL(uintptr_t, val)

/* ptrdiff_t */
#define C_PTRDIFF_FMT__ PRIdPTR
#define C_PTRDIFF_FMT_(label) FMT_LF_(label, C_PTRDIFF_FMT__)
#define C_PTRDIFF_FMT(label) FMT_LF(label, C_PTRDIFF_FMT__)
#define C_PTRDIFF_VAL(val) CAST_VAL(uintptr_t, val)

#endif

#define C_PTRDIFF2_VAL(x,y) C_PTRDIFF_VAL(CAST_VAL(void*, x)-CAST_VAL(void*, y))

#endif
