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
# ifndef BOOST_PREPROCESSOR_ITERATION_ITERATE_HPP
# define BOOST_PREPROCESSOR_ITERATION_ITERATE_HPP
#
# include <boost/preprocessor/arithmetic/dec.hpp>
# include <boost/preprocessor/arithmetic/inc.hpp>
# include <boost/preprocessor/array/elem.hpp>
# include <boost/preprocessor/array/size.hpp>
# include <boost/preprocessor/cat.hpp>
# include <boost/preprocessor/slot/slot.hpp>
# include <boost/preprocessor/tuple/elem.hpp>
#
# /* BOOST_PP_ITERATION_DEPTH */
#
# define BOOST_PP_ITERATION_DEPTH() 0
#
# /* BOOST_PP_ITERATION */
#
# define BOOST_PP_ITERATION() BOOST_PP_CAT(BOOST_PP_ITERATION_, BOOST_PP_ITERATION_DEPTH())
#
# /* BOOST_PP_ITERATION_START && BOOST_PP_ITERATION_FINISH */
#
# define BOOST_PP_ITERATION_START() BOOST_PP_CAT(BOOST_PP_ITERATION_START_, BOOST_PP_ITERATION_DEPTH())
# define BOOST_PP_ITERATION_FINISH() BOOST_PP_CAT(BOOST_PP_ITERATION_FINISH_, BOOST_PP_ITERATION_DEPTH())
#
# /* BOOST_PP_ITERATION_FLAGS */
#
# define BOOST_PP_ITERATION_FLAGS() (BOOST_PP_CAT(BOOST_PP_ITERATION_FLAGS_, BOOST_PP_ITERATION_DEPTH())())
#
# /* BOOST_PP_FRAME_ITERATION */
#
# define BOOST_PP_FRAME_ITERATION(i) BOOST_PP_CAT(BOOST_PP_ITERATION_, i)
#
# /* BOOST_PP_FRAME_START && BOOST_PP_FRAME_FINISH */
#
# define BOOST_PP_FRAME_START(i) BOOST_PP_CAT(BOOST_PP_ITERATION_START_, i)
# define BOOST_PP_FRAME_FINISH(i) BOOST_PP_CAT(BOOST_PP_ITERATION_FINISH_, i)
#
# /* BOOST_PP_FRAME_FLAGS */
#
# define BOOST_PP_FRAME_FLAGS(i) (BOOST_PP_CAT(BOOST_PP_ITERATION_FLAGS_, i)())
#
# /* BOOST_PP_RELATIVE_ITERATION */
#
# define BOOST_PP_RELATIVE_ITERATION(i) BOOST_PP_CAT(BOOST_PP_RELATIVE_, i)(BOOST_PP_ITERATION_)
#
# define BOOST_PP_RELATIVE_0(m) BOOST_PP_CAT(m, BOOST_PP_ITERATION_DEPTH())
# define BOOST_PP_RELATIVE_1(m) BOOST_PP_CAT(m, BOOST_PP_DEC(BOOST_PP_ITERATION_DEPTH()))
# define BOOST_PP_RELATIVE_2(m) BOOST_PP_CAT(m, BOOST_PP_DEC(BOOST_PP_DEC(BOOST_PP_ITERATION_DEPTH())))
# define BOOST_PP_RELATIVE_3(m) BOOST_PP_CAT(m, BOOST_PP_DEC(BOOST_PP_DEC(BOOST_PP_DEC(BOOST_PP_ITERATION_DEPTH()))))
# define BOOST_PP_RELATIVE_4(m) BOOST_PP_CAT(m, BOOST_PP_DEC(BOOST_PP_DEC(BOOST_PP_DEC(BOOST_PP_DEC(BOOST_PP_ITERATION_DEPTH())))))
#
# /* BOOST_PP_RELATIVE_START && BOOST_PP_RELATIVE_FINISH */
#
# define BOOST_PP_RELATIVE_START(i) BOOST_PP_CAT(BOOST_PP_RELATIVE_, i)(BOOST_PP_ITERATION_START_)
# define BOOST_PP_RELATIVE_FINISH(i) BOOST_PP_CAT(BOOST_PP_RELATIVE_, i)(BOOST_PP_ITERATION_FINISH_)
#
# /* BOOST_PP_RELATIVE_FLAGS */
#
# define BOOST_PP_RELATIVE_FLAGS(i) (BOOST_PP_CAT(BOOST_PP_RELATIVE_, i)(BOOST_PP_ITERATION_FLAGS_)())
#
# /* BOOST_PP_ITERATE */
#
# define BOOST_PP_ITERATE() BOOST_PP_CAT(BOOST_PP_ITERATE_, BOOST_PP_INC(BOOST_PP_ITERATION_DEPTH()))
#
# define BOOST_PP_ITERATE_1 <boost/preprocessor/iteration/detail/iter/forward1.hpp>
# define BOOST_PP_ITERATE_2 <boost/preprocessor/iteration/detail/iter/forward2.hpp>
# define BOOST_PP_ITERATE_3 <boost/preprocessor/iteration/detail/iter/forward3.hpp>
# define BOOST_PP_ITERATE_4 <boost/preprocessor/iteration/detail/iter/forward4.hpp>
# define BOOST_PP_ITERATE_5 <boost/preprocessor/iteration/detail/iter/forward5.hpp>
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
