/* File maybe-inline.h - reconciling inline with private
 * Copyright (c) J. Greg Davidson, All rights reserved.
 * Monday 16 August 2010
 */

/*
	This is a new C development technique in
	the process of development and refinement.
 */

/* Foo is a data type.
   We wish the implementation of Foo
   to be both private and fast.
   When inline_foo is defined, Foo will be fast.
   As long as in some compiles we do NOT define
   inline_foo, then Foo will be private.
 */

#if 0				// from foo.c
#define FOO_C
#include "foo.h"
#endif

#if 0				// example foo header

#ifndef FOO_H
#define FOO_H

typedef struct foo_private *Foo;

#ifdef INLINE_FOO
#define FOO_INLINE inline
#endif

#if !( defined(INLINE_FOO) && defined(FOO_C) )
struct foo_private {
	char buf[100];
	char *buf_ptr;
};
#endif

#if !( defined(INLINE_FOO) && defined(FOO_C) )
	FOO_INLINE void foo_reset(void) { buf_ptr = buf; }
#endif

#if !( defined(INLINE_FOO) && defined(FOO_C) )
FOO_INLINE char foo_push(char c) {
	return buf_ptr == buf + sizeof buf ? 0 : *buf_ptr++ = c;
}
#endif

#if !( defined(INLINE_FOO) && defined(FOO_C) )
FOO_INLINE char foo_pop(void) {
	return buf_ptr > buf ? 0 : *--buf_ptr;
}
#endif

#endif	// ifndef FOO_H

#endif	// example foo header
