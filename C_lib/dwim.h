// Ideas from
// http://ozlabs.org/~rusty/index.cgi/tech/2008-03-30.html

	/*
	 * min()/max() macros that also do
	 * strict type-checking.. See the
	 * "unnecessary" pointer comparison.
	 */
	#define min(x,y) ({ \
		typeof(x) _x = (x);	\
		typeof(y) _y = (y);	\
		(void) (&_x == &_y);	\
		_x < _y ? _x : _y; })

Since a common error in C is to compare signed vs unsigned types and expect a signed result, this macro insists that both types be identical. 


the GCC "__attribute__((warn_unused_result))" can be used to promote this usage to a warning. 


C convention for argument order seems to have evolved down to three ordered rules:

   1. Context argument(s) go first. A context is something the user will do a series of different things to; a handle.
   2. Associated arguments are adjacent. An array and its length go together, as does a timestamp and its granularity. If you could see yourself making a structure out of some of the args, they should go together.
   3. Details go as late as possible. Flags for the function go at the end. Pointer and length pairs are passed in that order.


