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
# ifndef BOOST_PREPROCESSOR_SEQ_FOR_EACH_I_HPP
# define BOOST_PREPROCESSOR_SEQ_FOR_EACH_I_HPP
#
# include <boost/preprocessor/arithmetic/dec.hpp>
# include <boost/preprocessor/arithmetic/inc.hpp>
# include <boost/preprocessor/config/config.hpp>
# include <boost/preprocessor/control/if.hpp>
# include <boost/preprocessor/control/iif.hpp>
# include <boost/preprocessor/repetition/for.hpp>
# include <boost/preprocessor/seq/seq.hpp>
# include <boost/preprocessor/seq/size.hpp>
# include <boost/preprocessor/seq/detail/is_empty.hpp>
# include <boost/preprocessor/tuple/elem.hpp>
# include <boost/preprocessor/tuple/rem.hpp>
#
# /* BOOST_PP_SEQ_FOR_EACH_I */
#
# if ~BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_EDG()
#    define BOOST_PP_SEQ_FOR_EACH_I(macro, data, seq) BOOST_PP_SEQ_FOR_EACH_I_DETAIL_CHECK(macro, data, seq)
# else
#    define BOOST_PP_SEQ_FOR_EACH_I(macro, data, seq) BOOST_PP_SEQ_FOR_EACH_I_I(macro, data, seq)
#    define BOOST_PP_SEQ_FOR_EACH_I_I(macro, data, seq) BOOST_PP_SEQ_FOR_EACH_I_DETAIL_CHECK(macro, data, seq)
# endif
#
#    define BOOST_PP_SEQ_FOR_EACH_I_DETAIL_CHECK_EXEC(macro, data, seq) BOOST_PP_FOR((macro, data, seq, 0, BOOST_PP_SEQ_SIZE(seq)), BOOST_PP_SEQ_FOR_EACH_I_P, BOOST_PP_SEQ_FOR_EACH_I_O, BOOST_PP_SEQ_FOR_EACH_I_M)
#    define BOOST_PP_SEQ_FOR_EACH_I_DETAIL_CHECK_EMPTY(macro, data, seq)
#
#    define BOOST_PP_SEQ_FOR_EACH_I_DETAIL_CHECK(macro, data, seq) \
        BOOST_PP_IIF \
            ( \
            BOOST_PP_SEQ_DETAIL_IS_NOT_EMPTY(seq), \
            BOOST_PP_SEQ_FOR_EACH_I_DETAIL_CHECK_EXEC, \
            BOOST_PP_SEQ_FOR_EACH_I_DETAIL_CHECK_EMPTY \
            ) \
        (macro, data, seq) \
/**/
#
# define BOOST_PP_SEQ_FOR_EACH_I_P(r, x) BOOST_PP_TUPLE_ELEM(5, 4, x)
#
# if BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_STRICT()
#    define BOOST_PP_SEQ_FOR_EACH_I_O(r, x) BOOST_PP_SEQ_FOR_EACH_I_O_I x
# else
#    define BOOST_PP_SEQ_FOR_EACH_I_O(r, x) BOOST_PP_SEQ_FOR_EACH_I_O_I(BOOST_PP_TUPLE_ELEM(5, 0, x), BOOST_PP_TUPLE_ELEM(5, 1, x), BOOST_PP_TUPLE_ELEM(5, 2, x), BOOST_PP_TUPLE_ELEM(5, 3, x), BOOST_PP_TUPLE_ELEM(5, 4, x))
# endif
#
# define BOOST_PP_SEQ_FOR_EACH_I_O_I(macro, data, seq, i, sz) \
    BOOST_PP_SEQ_FOR_EACH_I_O_I_DEC(macro, data, seq, i, BOOST_PP_DEC(sz)) \
/**/
# define BOOST_PP_SEQ_FOR_EACH_I_O_I_DEC(macro, data, seq, i, sz) \
    ( \
    macro, \
    data, \
    BOOST_PP_IF \
        ( \
        sz, \
        BOOST_PP_SEQ_FOR_EACH_I_O_I_TAIL, \
        BOOST_PP_SEQ_FOR_EACH_I_O_I_NIL \
        ) \
    (seq), \
    BOOST_PP_INC(i), \
    sz \
    ) \
/**/
# define BOOST_PP_SEQ_FOR_EACH_I_O_I_TAIL(seq) BOOST_PP_SEQ_TAIL(seq)
# define BOOST_PP_SEQ_FOR_EACH_I_O_I_NIL(seq) BOOST_PP_NIL
#
# if BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_STRICT()
#    define BOOST_PP_SEQ_FOR_EACH_I_M(r, x) BOOST_PP_SEQ_FOR_EACH_I_M_IM(r, BOOST_PP_TUPLE_REM_5 x)
#    define BOOST_PP_SEQ_FOR_EACH_I_M_IM(r, im) BOOST_PP_SEQ_FOR_EACH_I_M_I(r, im)
# else
#    define BOOST_PP_SEQ_FOR_EACH_I_M(r, x) BOOST_PP_SEQ_FOR_EACH_I_M_I(r, BOOST_PP_TUPLE_ELEM(5, 0, x), BOOST_PP_TUPLE_ELEM(5, 1, x), BOOST_PP_TUPLE_ELEM(5, 2, x), BOOST_PP_TUPLE_ELEM(5, 3, x), BOOST_PP_TUPLE_ELEM(5, 4, x))
# endif
#
# define BOOST_PP_SEQ_FOR_EACH_I_M_I(r, macro, data, seq, i, sz) macro(r, data, i, BOOST_PP_SEQ_HEAD(seq))
#
# /* BOOST_PP_SEQ_FOR_EACH_I_R */
#
# if ~BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_EDG()
#    define BOOST_PP_SEQ_FOR_EACH_I_R(r, macro, data, seq) BOOST_PP_SEQ_FOR_EACH_I_R_DETAIL_CHECK(r, macro, data, seq)
# else
#    define BOOST_PP_SEQ_FOR_EACH_I_R(r, macro, data, seq) BOOST_PP_SEQ_FOR_EACH_I_R_I(r, macro, data, seq)
#    define BOOST_PP_SEQ_FOR_EACH_I_R_I(r, macro, data, seq) BOOST_PP_SEQ_FOR_EACH_I_R_DETAIL_CHECK(r, macro, data, seq)
# endif
#
#    define BOOST_PP_SEQ_FOR_EACH_I_R_DETAIL_CHECK_EXEC(r, macro, data, seq) BOOST_PP_FOR_ ## r((macro, data, seq, 0, BOOST_PP_SEQ_SIZE(seq)), BOOST_PP_SEQ_FOR_EACH_I_P, BOOST_PP_SEQ_FOR_EACH_I_O, BOOST_PP_SEQ_FOR_EACH_I_M)
#    define BOOST_PP_SEQ_FOR_EACH_I_R_DETAIL_CHECK_EMPTY(r, macro, data, seq)
#
#    define BOOST_PP_SEQ_FOR_EACH_I_R_DETAIL_CHECK(r, macro, data, seq) \
        BOOST_PP_IIF \
            ( \
            BOOST_PP_SEQ_DETAIL_IS_NOT_EMPTY(seq), \
            BOOST_PP_SEQ_FOR_EACH_I_R_DETAIL_CHECK_EXEC, \
            BOOST_PP_SEQ_FOR_EACH_I_R_DETAIL_CHECK_EMPTY \
            ) \
        (r, macro, data, seq) \
/**/
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
