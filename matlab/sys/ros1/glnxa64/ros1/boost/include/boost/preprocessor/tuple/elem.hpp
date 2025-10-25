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
# /* Revised by Paul Mensonides (2002-2011) */
# /* Revised by Edward Diener (2011,2014,2020) */
#
# /* See http://www.boost.org for most recent version. */
#
# ifndef BOOST_PREPROCESSOR_TUPLE_ELEM_HPP
# define BOOST_PREPROCESSOR_TUPLE_ELEM_HPP
#
# include <boost/preprocessor/cat.hpp>
# include <boost/preprocessor/config/config.hpp>
# include <boost/preprocessor/facilities/expand.hpp>
# include <boost/preprocessor/facilities/overload.hpp>
# include <boost/preprocessor/tuple/rem.hpp>
# include <boost/preprocessor/variadic/elem.hpp>
# include <boost/preprocessor/tuple/detail/is_single_return.hpp>
#
# if BOOST_PP_VARIADICS_MSVC
#     define BOOST_PP_TUPLE_ELEM(...) BOOST_PP_TUPLE_ELEM_I(BOOST_PP_OVERLOAD(BOOST_PP_TUPLE_ELEM_O_, __VA_ARGS__), (__VA_ARGS__))
#     define BOOST_PP_TUPLE_ELEM_I(m, args) BOOST_PP_TUPLE_ELEM_II(m, args)
#     define BOOST_PP_TUPLE_ELEM_II(m, args) BOOST_PP_CAT(m ## args,)
/*
  Use BOOST_PP_REM_CAT if it is a single element tuple ( which might be empty )
  else use BOOST_PP_REM. This fixes a VC++ problem with an empty tuple and BOOST_PP_TUPLE_ELEM
  functionality. See tuple_elem_bug_test.cxx.
*/
#     define BOOST_PP_TUPLE_ELEM_O_2(n, tuple) \
         BOOST_PP_VARIADIC_ELEM(n, BOOST_PP_EXPAND(BOOST_PP_TUPLE_IS_SINGLE_RETURN(BOOST_PP_REM_CAT,BOOST_PP_REM,tuple) tuple)) \
         /**/
# else
#     define BOOST_PP_TUPLE_ELEM(...) BOOST_PP_OVERLOAD(BOOST_PP_TUPLE_ELEM_O_, __VA_ARGS__)(__VA_ARGS__)
#     define BOOST_PP_TUPLE_ELEM_O_2(n, tuple) BOOST_PP_VARIADIC_ELEM(n, BOOST_PP_REM tuple)
# endif
# define BOOST_PP_TUPLE_ELEM_O_3(size, n, tuple) BOOST_PP_TUPLE_ELEM_O_2(n, tuple)
#
# /* directly used elsewhere in Boost... */
#
# define BOOST_PP_TUPLE_ELEM_1_0(a) a
#
# define BOOST_PP_TUPLE_ELEM_2_0(a, b) a
# define BOOST_PP_TUPLE_ELEM_2_1(a, b) b
#
# define BOOST_PP_TUPLE_ELEM_3_0(a, b, c) a
# define BOOST_PP_TUPLE_ELEM_3_1(a, b, c) b
# define BOOST_PP_TUPLE_ELEM_3_2(a, b, c) c
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
