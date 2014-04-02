/* Module Tag Management Header

 ** Copyright

  Copyright (c) 2010 J. Greg Davidson.
  You may use this software under the terms of the
  GNU AFFERO GENERAL PUBLIC LICENSE
  as specified in the file LICENSE.md included with this distribution.
  All other use requires my permission in writing.
*/

/* see "this-tag.h" */

/* THIS */

#ifdef TAG_THIS
	#undef TAG_THIS
#endif
#ifdef THIS_TAG
	#define TAG_THIS(NAME) C_JOIN_2(THIS_TAG,  NAME)
#endif

#ifdef TagThis
	#undef TagThis
#endif
#ifdef ThisTag
	#define TagThis(Name) C_JOIN2(ThisTag, Name)
#endif

#ifdef tag_this
	#undef tag_this
#endif
#ifdef this_tag
	#define tag_this(name) C_JOIN_2(this_tag, name)
#endif

/* LAST */

#ifdef TAG_LAST
	#undef TAG_LAST
#endif
#ifdef LAST_TAG
	#define TAG_LAST(NAME) C_JOIN_2(LAST_TAG, NAME)
#endif

#ifdef TagLast
	#undef TagLast
#endif
#ifdef LastTag
	#define TagLast(Name) C_JOIN2(LastTag, Name)
#endif

#ifdef tag_last
	#undef tag_last
#endif
#ifdef last_tag
	#define tag_last(name) C_JOIN_2(last_tag, name)
#endif
