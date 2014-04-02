/* Module Tag Management Header - undefines any last-tags

 ** Copyright

	Copyright (c) 2010 J. Greg Davidson.
	You may use this software under the terms of the
	GNU AFFERO GENERAL PUBLIC LICENSE
	as specified in the file LICENSE.md included with this distribution.
	All other use requires my permission in writing.
*/

/* see "this-tag.h" */

#ifdef LAST_TAG
	#undef LAST_TAG
#endif

#ifdef LastTag
	#undef LastTag
#endif

#ifdef last_tag
	#undef last_tag
#endif
