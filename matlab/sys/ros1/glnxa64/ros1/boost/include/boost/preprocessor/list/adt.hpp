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
#  *
#  * See http://www.boost.org for most recent version.
#  */
#
# /* Revised by Paul Mensonides (2002) */
#
# ifndef BOOST_PREPROCESSOR_LIST_ADT_HPP
# define BOOST_PREPROCESSOR_LIST_ADT_HPP
#
# include <boost/preprocessor/config/config.hpp>
# include <boost/preprocessor/detail/is_binary.hpp>
# include <boost/preprocessor/logical/compl.hpp>
# include <boost/preprocessor/tuple/eat.hpp>
#
# /* BOOST_PP_LIST_CONS */
#
# define BOOST_PP_LIST_CONS(head, tail) (head, tail)
#
# /* BOOST_PP_LIST_NIL */
#
# define BOOST_PP_LIST_NIL BOOST_PP_NIL
#
# /* BOOST_PP_LIST_FIRST */
#
# define BOOST_PP_LIST_FIRST(list) BOOST_PP_LIST_FIRST_D(list)
#
# if ~BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_MWCC()
#    define BOOST_PP_LIST_FIRST_D(list) BOOST_PP_LIST_FIRST_I list
# else
#    define BOOST_PP_LIST_FIRST_D(list) BOOST_PP_LIST_FIRST_I ## list
# endif
#
# define BOOST_PP_LIST_FIRST_I(head, tail) head
#
# /* BOOST_PP_LIST_REST */
#
# define BOOST_PP_LIST_REST(list) BOOST_PP_LIST_REST_D(list)
#
# if ~BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_MWCC()
#    define BOOST_PP_LIST_REST_D(list) BOOST_PP_LIST_REST_I list
# else
#    define BOOST_PP_LIST_REST_D(list) BOOST_PP_LIST_REST_I ## list
# endif
#
# define BOOST_PP_LIST_REST_I(head, tail) tail
#
# /* BOOST_PP_LIST_IS_CONS */
#
# if BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_BCC()
#    define BOOST_PP_LIST_IS_CONS(list) BOOST_PP_LIST_IS_CONS_D(list)
#    define BOOST_PP_LIST_IS_CONS_D(list) BOOST_PP_LIST_IS_CONS_ ## list
#    define BOOST_PP_LIST_IS_CONS_(head, tail) 1
#    define BOOST_PP_LIST_IS_CONS_BOOST_PP_NIL 0
# else
#    define BOOST_PP_LIST_IS_CONS(list) BOOST_PP_IS_BINARY(list)
# endif
#
# /* BOOST_PP_LIST_IS_NIL */
#
# if ~BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_BCC()
#    define BOOST_PP_LIST_IS_NIL(list) BOOST_PP_COMPL(BOOST_PP_IS_BINARY(list))
# else
#    define BOOST_PP_LIST_IS_NIL(list) BOOST_PP_COMPL(BOOST_PP_LIST_IS_CONS(list))
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
