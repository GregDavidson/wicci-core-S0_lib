/* Module Tag Management Header - undefines any this-tags

 ** Copyright

	Copyright (c) 2010 J. Greg Davidson.
	You may use this software under the terms of the
	GNU AFFERO GENERAL PUBLIC LICENSE
	as specified in the file LICENSE.md included with this distribution.
	All other use requires my permission in writing.
*/

#ifdef THIS_TAG
	#undef THIS_TAG
#endif

#ifdef ThisTag
	#undef ThisTag
#endif

#ifdef this_tag
	#undef this_tag
#endif

#if 0	// Documentation

// Module header file "module_name.h"

#ifndef MODULE_NAME_H
#define MODULE_NAME_H

// include regular headers here

#include "this-tag.h"
#define THIS_TAG MODULE_NAME
#define ThisTag ModuleName
#define this_tag module_name

// include tag-dependent headers here

// other header code here

// Just before end:

#ifndef MODULE_NAME_C
#include "last-tag.h"
#define LAST_TAG MODULE_NAME
#define LastTag ModuleName
#define last_tag module_name
#endif

#endif	// MODULE_H

// Module implementation file "module_name.c"

// include regular headers, then:

#define MODULE_NAME_C_FILE
#include "module_name.h"

// include tag-dependent headers here, e.g.
#include "debug.h"

// that's it!

/* What does this practice buy you?

	 In all header and implementation files you get:

	THIS_TAG, ThisTag, this_tag	-- handy tags for current module
	LAST_TAG, LastTag, last_tag	-- handy tags for previous module

	 which you can use alone or along with

	TAG_THIS(Name)	THIS_TAG prefixing Name
	TagThis(Name)	ThisTag prefixing Name
	tag_this(Name)	this_tag prefixing Name

	TAG_LAST(Name)	LAST_TAG prefixing Name
	TagLast(Name)	LastTag prefixing Name
	tag_last(Name)	last_tag prefixing Name
 */

#endif
