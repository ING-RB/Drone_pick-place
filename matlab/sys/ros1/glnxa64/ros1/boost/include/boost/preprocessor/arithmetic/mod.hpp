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
# /* Revised by Edward Diener (2020) */
#
# /* See http://www.boost.org for most recent version. */
#
# ifndef BOOST_PREPROCESSOR_ARITHMETIC_MOD_HPP
# define BOOST_PREPROCESSOR_ARITHMETIC_MOD_HPP
#
# include <boost/preprocessor/config/config.hpp>
#
# if ~BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_STRICT()
#
# include <boost/preprocessor/arithmetic/detail/div_base.hpp>
# include <boost/preprocessor/tuple/elem.hpp>
#
# /* BOOST_PP_MOD */
#
# if ~BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_EDG()
#    define BOOST_PP_MOD(x, y) BOOST_PP_TUPLE_ELEM(3, 1, BOOST_PP_DIV_BASE(x, y))
# else
#    define BOOST_PP_MOD(x, y) BOOST_PP_MOD_I(x, y)
#    define BOOST_PP_MOD_I(x, y) BOOST_PP_TUPLE_ELEM(3, 1, BOOST_PP_DIV_BASE(x, y))
# endif
#
# /* BOOST_PP_MOD_D */
#
# if ~BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_EDG()
#    define BOOST_PP_MOD_D(d, x, y) BOOST_PP_TUPLE_ELEM(3, 1, BOOST_PP_DIV_BASE_D(d, x, y))
# else
#    define BOOST_PP_MOD_D(d, x, y) BOOST_PP_MOD_D_I(d, x, y)
#    define BOOST_PP_MOD_D_I(d, x, y) BOOST_PP_TUPLE_ELEM(3, 1, BOOST_PP_DIV_BASE_D(d, x, y))
# endif
#
# else
#
# include <boost/preprocessor/arithmetic/detail/div_base.hpp>
# include <boost/preprocessor/control/iif.hpp>
# include <boost/preprocessor/facilities/identity.hpp>
# include <boost/preprocessor/tuple/elem.hpp>
# include <boost/preprocessor/arithmetic/detail/is_1_number.hpp>
#
# /* BOOST_PP_MOD */
#
#    define BOOST_PP_MOD(x, y) BOOST_PP_IIF(BOOST_PP_DETAIL_IS_1_NUMBER(y),BOOST_PP_IDENTITY_N(0,2),BOOST_PP_MOD_DO)(x,y)
#
# if ~BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_EDG()
#    define BOOST_PP_MOD_DO(x, y) BOOST_PP_TUPLE_ELEM(3, 1, BOOST_PP_DIV_BASE(x, y))
# else
#    define BOOST_PP_MOD_DO(x, y) BOOST_PP_MOD_I(x, y)
#    define BOOST_PP_MOD_I(x, y) BOOST_PP_TUPLE_ELEM(3, 1, BOOST_PP_DIV_BASE(x, y))
# endif
#
# /* BOOST_PP_MOD_D */
#
#    define BOOST_PP_MOD_D(d, x, y) BOOST_PP_IIF(BOOST_PP_DETAIL_IS_1_NUMBER(y),BOOST_PP_IDENTITY_N(0,3),BOOST_PP_MOD_DO_D)(d,x,y)
#
# if ~BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_EDG()
#    define BOOST_PP_MOD_DO_D(d, x, y) BOOST_PP_TUPLE_ELEM(3, 1, BOOST_PP_DIV_BASE_D(d, x, y))
# else
#    define BOOST_PP_MOD_DO_D(d, x, y) BOOST_PP_MOD_D_I(d, x, y)
#    define BOOST_PP_MOD_D_I(d, x, y) BOOST_PP_TUPLE_ELEM(3, 1, BOOST_PP_DIV_BASE_D(d, x, y))
# endif
#
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
