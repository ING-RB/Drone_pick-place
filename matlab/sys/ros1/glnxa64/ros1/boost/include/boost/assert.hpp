#if !defined(MW_ENABLE_BOOST_WARNINGS)
#  if defined(__GNUC__)
#    pragma GCC system_header
#  elif defined(_MSC_VER)
     /* The matching "pop" is in header_suffix.h */
#    pragma warning(push, 1)
       /*
        * These suppressions are only here because of the apparent compiler bug:
        * g782945
        *
        * If the bug didn't exist, these warnings would be suppressed solely by
        * the warning(push) above.  The state of the warnings prior to the
        * warning(push) above will be restored by the warning(pop) in the suffix
        * header.
        *
        * Other suppressions may need to be added as more Boost headers are used
        * and other bogus warnings are uncovered.
        */
#      pragma warning(disable: 4003)
#      pragma warning(disable: 4141)
#      pragma warning(disable: 4244)
#      pragma warning(disable: 4702)
#      pragma warning(disable: 4714)
       /* End g782945 workarounds. */
#  endif
#endif

#if !defined(MW_DISABLE_BOOST_DEFAULT_VISIBILITY)
#  if defined(__GNUC__)
#    if (__GNUC__ == 4 && __GNUC_MINOR__ >= 1) || (__GNUC__ > 4)
       /* The matching "pop" is in header_suffix.h */
#      pragma GCC visibility push (default)
#    endif
#  endif
#endif

//
//  boost/assert.hpp - BOOST_ASSERT(expr)
//                     BOOST_ASSERT_MSG(expr, msg)
//                     BOOST_VERIFY(expr)
//                     BOOST_VERIFY_MSG(expr, msg)
//                     BOOST_ASSERT_IS_VOID
//
//  Copyright (c) 2001, 2002 Peter Dimov and Multi Media Ltd.
//  Copyright (c) 2007, 2014 Peter Dimov
//  Copyright (c) Beman Dawes 2011
//  Copyright (c) 2015 Ion Gaztanaga
//
//  Distributed under the Boost Software License, Version 1.0.
//  See accompanying file LICENSE_1_0.txt or copy at
//  http://www.boost.org/LICENSE_1_0.txt
//
//  Note: There are no include guards. This is intentional.
//
//  See http://www.boost.org/libs/assert/assert.html for documentation.
//

//
// Stop inspect complaining about use of 'assert':
//
// boostinspect:naassert_macro
//

//
// BOOST_ASSERT, BOOST_ASSERT_MSG, BOOST_ASSERT_IS_VOID
//

#undef BOOST_ASSERT
#undef BOOST_ASSERT_MSG
#undef BOOST_ASSERT_IS_VOID

#if defined(BOOST_DISABLE_ASSERTS) || ( defined(BOOST_ENABLE_ASSERT_DEBUG_HANDLER) && defined(NDEBUG) )

# define BOOST_ASSERT(expr) ((void)0)
# define BOOST_ASSERT_MSG(expr, msg) ((void)0)
# define BOOST_ASSERT_IS_VOID

#elif defined(BOOST_ENABLE_ASSERT_HANDLER) || ( defined(BOOST_ENABLE_ASSERT_DEBUG_HANDLER) && !defined(NDEBUG) )

#include <boost/config.hpp> // for BOOST_LIKELY
#include <boost/current_function.hpp>

namespace mwboost {} namespace boost = mwboost; namespace mwboost
{
    void assertion_failed(char const * expr, char const * function, char const * file, long line); // user defined
    void assertion_failed_msg(char const * expr, char const * msg, char const * function, char const * file, long line); // user defined
} // namespace mwboost

#define BOOST_ASSERT(expr) (BOOST_LIKELY(!!(expr))? ((void)0): ::mwboost::assertion_failed(#expr, BOOST_CURRENT_FUNCTION, __FILE__, __LINE__))
#define BOOST_ASSERT_MSG(expr, msg) (BOOST_LIKELY(!!(expr))? ((void)0): ::mwboost::assertion_failed_msg(#expr, msg, BOOST_CURRENT_FUNCTION, __FILE__, __LINE__))

#else

# include <assert.h> // .h to support old libraries w/o <cassert> - effect is the same

# define BOOST_ASSERT(expr) assert(expr)
# define BOOST_ASSERT_MSG(expr, msg) assert((expr)&&(msg))
#if defined(NDEBUG)
# define BOOST_ASSERT_IS_VOID
#endif

#endif

//
// BOOST_VERIFY, BOOST_VERIFY_MSG
//

#undef BOOST_VERIFY
#undef BOOST_VERIFY_MSG

#if defined(BOOST_DISABLE_ASSERTS) || ( !defined(BOOST_ENABLE_ASSERT_HANDLER) && defined(NDEBUG) )

# define BOOST_VERIFY(expr) ((void)(expr))
# define BOOST_VERIFY_MSG(expr, msg) ((void)(expr))

#else

# define BOOST_VERIFY(expr) BOOST_ASSERT(expr)
# define BOOST_VERIFY_MSG(expr, msg) BOOST_ASSERT_MSG(expr,msg)

#endif

#if !defined(MW_DISABLE_BOOST_DEFAULT_VISIBILITY)
#  if defined(__GNUC__)
#    if (__GNUC__ == 4 && __GNUC_MINOR__ >= 1) || (__GNUC__ > 4)
       /* The matching "push" is in header_prefix.h */
#      pragma GCC visibility pop
#    endif
#  endif
#endif

#if !defined(MW_ENABLE_BOOST_WARNINGS)
#  if defined(_MSC_VER)
     /* The matching "push" is in header_prefix.h */
#    pragma warning(pop)
#  endif
#endif
