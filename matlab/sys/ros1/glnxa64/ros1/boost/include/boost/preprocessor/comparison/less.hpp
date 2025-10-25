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

# /* Copyright (C) 2001
#  * Housemarque Oy
#  * http://www.housemarque.com
#  *
#  * Distributed under the Boost Software License, Version 1.0. (See
#  * accompanying file LICENSE_1_0.txt or copy at
#  * http://www.boost.org/LICENSE_1_0.txt)
#  */
#
# /* Revised by Paul Mensonides (2002) */
#
# /* See http://www.boost.org for most recent version. */
#
# ifndef BOOST_PREPROCESSOR_COMPARISON_LESS_HPP
# define BOOST_PREPROCESSOR_COMPARISON_LESS_HPP
#
# include <boost/preprocessor/comparison/less_equal.hpp>
# include <boost/preprocessor/comparison/not_equal.hpp>
# include <boost/preprocessor/config/config.hpp>
# include <boost/preprocessor/control/iif.hpp>
# include <boost/preprocessor/logical/bitand.hpp>
# include <boost/preprocessor/tuple/eat.hpp>
#
# /* BOOST_PP_LESS */
#
# if BOOST_PP_CONFIG_FLAGS() & (BOOST_PP_CONFIG_MWCC() | BOOST_PP_CONFIG_DMC())
#    define BOOST_PP_LESS(x, y) BOOST_PP_BITAND(BOOST_PP_NOT_EQUAL(x, y), BOOST_PP_LESS_EQUAL(x, y))
# elif ~BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_EDG()
#    define BOOST_PP_LESS(x, y) BOOST_PP_IIF(BOOST_PP_NOT_EQUAL(x, y), BOOST_PP_LESS_EQUAL, 0 BOOST_PP_TUPLE_EAT_2)(x, y)
# else
#    define BOOST_PP_LESS(x, y) BOOST_PP_LESS_I(x, y)
#    define BOOST_PP_LESS_I(x, y) BOOST_PP_IIF(BOOST_PP_NOT_EQUAL(x, y), BOOST_PP_LESS_EQUAL, 0 BOOST_PP_TUPLE_EAT_2)(x, y)
# endif
#
# /* BOOST_PP_LESS_D */
#
# if BOOST_PP_CONFIG_FLAGS() & (BOOST_PP_CONFIG_MWCC() | BOOST_PP_CONFIG_DMC())
#    define BOOST_PP_LESS_D(d, x, y) BOOST_PP_BITAND(BOOST_PP_NOT_EQUAL(x, y), BOOST_PP_LESS_EQUAL_D(d, x, y))
# elif ~BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_EDG()
#    define BOOST_PP_LESS_D(d, x, y) BOOST_PP_IIF(BOOST_PP_NOT_EQUAL(x, y), BOOST_PP_LESS_EQUAL_D, 0 BOOST_PP_TUPLE_EAT_3)(d, x, y)
# else
#    define BOOST_PP_LESS_D(d, x, y) BOOST_PP_LESS_D_I(d, x, y)
#    define BOOST_PP_LESS_D_I(d, x, y) BOOST_PP_IIF(BOOST_PP_NOT_EQUAL(x, y), BOOST_PP_LESS_EQUAL_D, 0 BOOST_PP_TUPLE_EAT_3)(d, x, y)
# endif
#
# endif

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
