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

//  (C) Copyright Matt Borland 2021.
//  Use, modification and distribution are subject to the
//  Boost Software License, Version 1.0. (See accompanying file
//  LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
//
// We deliberately use assert in here:
//
// boost-no-inspect

#ifndef BOOST_MATH_TOOLS_ASSERT_HPP
#define BOOST_MATH_TOOLS_ASSERT_HPP

#include <boost/math/tools/is_standalone.hpp>

#ifndef BOOST_MATH_STANDALONE

#include <boost/assert.hpp>
#include <boost/static_assert.hpp>
#define BOOST_MATH_ASSERT(expr) BOOST_ASSERT(expr)
#define BOOST_MATH_ASSERT_MSG(expr, msg) BOOST_ASSERT_MSG(expr, msg)
#define BOOST_MATH_STATIC_ASSERT(expr) BOOST_STATIC_ASSERT(expr)
#define BOOST_MATH_STATIC_ASSERT_MSG(expr, msg) BOOST_STATIC_ASSERT_MSG(expr, msg)

#else // Standalone mode - use cassert

#include <cassert>
#define BOOST_MATH_ASSERT(expr) assert(expr)
#define BOOST_MATH_ASSERT_MSG(expr, msg) assert((expr)&&(msg))
#define BOOST_MATH_STATIC_ASSERT(expr) static_assert(expr, #expr " failed")
#define BOOST_MATH_STATIC_ASSERT_MSG(expr, msg) static_assert(expr, msg)

#endif

#endif // BOOST_MATH_TOOLS_ASSERT_HPP

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
