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


// Copyright (C) 2009-2012 Lorenzo Caminiti
// Distributed under the Boost Software License, Version 1.0
// (see accompanying file LICENSE_1_0.txt or a copy at
// http://www.boost.org/LICENSE_1_0.txt)
// Home at http://www.boost.org/libs/utility/identity_type

/** @file
Wrap type expressions with round parenthesis so they can be passed to macros
even if they contain commas.
*/

#ifndef BOOST_IDENTITY_TYPE_HPP_
#define BOOST_IDENTITY_TYPE_HPP_

#include <boost/type_traits/function_traits.hpp>

/**
@brief This macro allows to wrap the specified type expression within extra
round parenthesis so the type can be passed as a single macro parameter even if
it contains commas (not already wrapped within round parenthesis).

@Params
@Param{parenthesized_type,
The type expression to be passed as macro parameter wrapped by a single set
of round parenthesis <c>(...)</c>.
This type expression can contain an arbitrary number of commas.
}
@EndParams

This macro works on any C++03 compiler (it does not use variadic macros).

This macro must be prefixed by <c>typename</c> when used within templates.
Note that the compiler will not be able to automatically determine function
template parameters when they are wrapped with this macro (these parameters
need to be explicitly specified when calling the function template).

On some compilers (like GCC), using this macro on abstract types requires to
add and remove a reference to the specified type.
*/
#define BOOST_IDENTITY_TYPE(parenthesized_type) \
    /* must NOT prefix this with `::` to work with parenthesized syntax */ \
    mwboost::function_traits< void parenthesized_type >::arg1_type

#endif // #include guard


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
