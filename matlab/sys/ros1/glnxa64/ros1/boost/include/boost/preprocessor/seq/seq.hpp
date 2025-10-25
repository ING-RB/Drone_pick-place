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

# /* **************************************************************************
#  *                                                                          *
#  *     (C) Copyright Paul Mensonides 2002.
#  *     Distributed under the Boost Software License, Version 1.0. (See
#  *     accompanying file LICENSE_1_0.txt or copy at
#  *     http://www.boost.org/LICENSE_1_0.txt)
#  *                                                                          *
#  ************************************************************************** */
#
# /* See http://www.boost.org for most recent version. */
#
# ifndef BOOST_PREPROCESSOR_SEQ_SEQ_HPP
# define BOOST_PREPROCESSOR_SEQ_SEQ_HPP
#
# include <boost/preprocessor/config/config.hpp>
# include <boost/preprocessor/seq/elem.hpp>
#
# /* BOOST_PP_SEQ_HEAD */
#
# define BOOST_PP_SEQ_HEAD(seq) BOOST_PP_SEQ_ELEM(0, seq)
#
# /* BOOST_PP_SEQ_TAIL */
#
# if BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_MWCC()
#    define BOOST_PP_SEQ_TAIL(seq) BOOST_PP_SEQ_TAIL_1((seq))
#    define BOOST_PP_SEQ_TAIL_1(par) BOOST_PP_SEQ_TAIL_2 ## par
#    define BOOST_PP_SEQ_TAIL_2(seq) BOOST_PP_SEQ_TAIL_I ## seq
# elif BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_MSVC()
#    define BOOST_PP_SEQ_TAIL(seq) BOOST_PP_SEQ_TAIL_ID(BOOST_PP_SEQ_TAIL_I seq)
#    define BOOST_PP_SEQ_TAIL_ID(id) id
# elif BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_EDG()
#    define BOOST_PP_SEQ_TAIL(seq) BOOST_PP_SEQ_TAIL_D(seq)
#    define BOOST_PP_SEQ_TAIL_D(seq) BOOST_PP_SEQ_TAIL_I seq
# else
#    define BOOST_PP_SEQ_TAIL(seq) BOOST_PP_SEQ_TAIL_I seq
# endif
#
# define BOOST_PP_SEQ_TAIL_I(x)
#
# /* BOOST_PP_SEQ_NIL */
#
# define BOOST_PP_SEQ_NIL(x) (x)
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
