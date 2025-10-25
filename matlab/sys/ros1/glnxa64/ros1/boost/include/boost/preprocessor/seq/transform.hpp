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
# ifndef BOOST_PREPROCESSOR_SEQ_TRANSFORM_HPP
# define BOOST_PREPROCESSOR_SEQ_TRANSFORM_HPP
#
# include <boost/preprocessor/config/config.hpp>
# include <boost/preprocessor/seq/fold_left.hpp>
# include <boost/preprocessor/seq/seq.hpp>
# include <boost/preprocessor/tuple/elem.hpp>
# include <boost/preprocessor/tuple/rem.hpp>
#
# /* BOOST_PP_SEQ_TRANSFORM */
#
# if ~BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_EDG()
#    define BOOST_PP_SEQ_TRANSFORM(op, data, seq) BOOST_PP_SEQ_TAIL(BOOST_PP_TUPLE_ELEM(3, 2, BOOST_PP_SEQ_FOLD_LEFT(BOOST_PP_SEQ_TRANSFORM_O, (op, data, (nil)), seq)))
# else
#    define BOOST_PP_SEQ_TRANSFORM(op, data, seq) BOOST_PP_SEQ_TRANSFORM_I(op, data, seq)
#    define BOOST_PP_SEQ_TRANSFORM_I(op, data, seq) BOOST_PP_SEQ_TAIL(BOOST_PP_TUPLE_ELEM(3, 2, BOOST_PP_SEQ_FOLD_LEFT(BOOST_PP_SEQ_TRANSFORM_O, (op, data, (nil)), seq)))
# endif
#
# if BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_STRICT()
#    define BOOST_PP_SEQ_TRANSFORM_O(s, state, elem) BOOST_PP_SEQ_TRANSFORM_O_IM(s, BOOST_PP_TUPLE_REM_3 state, elem)
#    define BOOST_PP_SEQ_TRANSFORM_O_IM(s, im, elem) BOOST_PP_SEQ_TRANSFORM_O_I(s, im, elem)
# else
#    define BOOST_PP_SEQ_TRANSFORM_O(s, state, elem) BOOST_PP_SEQ_TRANSFORM_O_I(s, BOOST_PP_TUPLE_ELEM(3, 0, state), BOOST_PP_TUPLE_ELEM(3, 1, state), BOOST_PP_TUPLE_ELEM(3, 2, state), elem)
# endif
#
# define BOOST_PP_SEQ_TRANSFORM_O_I(s, op, data, res, elem) (op, data, res (op(s, data, elem)))
#
# /* BOOST_PP_SEQ_TRANSFORM_S */
#
# if ~BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_EDG()
#    define BOOST_PP_SEQ_TRANSFORM_S(s, op, data, seq) BOOST_PP_SEQ_TAIL(BOOST_PP_TUPLE_ELEM(3, 2, BOOST_PP_SEQ_FOLD_LEFT_ ## s(BOOST_PP_SEQ_TRANSFORM_O, (op, data, (nil)), seq)))
# else
#    define BOOST_PP_SEQ_TRANSFORM_S(s, op, data, seq) BOOST_PP_SEQ_TRANSFORM_S_I(s, op, data, seq)
#    define BOOST_PP_SEQ_TRANSFORM_S_I(s, op, data, seq) BOOST_PP_SEQ_TAIL(BOOST_PP_TUPLE_ELEM(3, 2, BOOST_PP_SEQ_FOLD_LEFT_ ## s(BOOST_PP_SEQ_TRANSFORM_O, (op, data, (nil)), seq)))
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
