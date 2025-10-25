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
#  *     (C) Copyright Edward Diener 2014,2019.
#  *     Distributed under the Boost Software License, Version 1.0. (See
#  *     accompanying file LICENSE_1_0.txt or copy at
#  *     http://www.boost.org/LICENSE_1_0.txt)
#  *                                                                          *
#  ************************************************************************** */
#
# /* See http://www.boost.org for most recent version. */
#
# ifndef BOOST_PREPROCESSOR_FACILITIES_IS_EMPTY_VARIADIC_HPP
# define BOOST_PREPROCESSOR_FACILITIES_IS_EMPTY_VARIADIC_HPP
#
# include <boost/preprocessor/config/config.hpp>
# include <boost/preprocessor/punctuation/is_begin_parens.hpp>
# include <boost/preprocessor/facilities/detail/is_empty.hpp>
#
#if BOOST_PP_VARIADICS_MSVC && _MSC_VER <= 1400
#
#define BOOST_PP_IS_EMPTY(param) \
    BOOST_PP_DETAIL_IS_EMPTY_IIF \
      ( \
      BOOST_PP_IS_BEGIN_PARENS \
        ( \
        param \
        ) \
      ) \
      ( \
      BOOST_PP_IS_EMPTY_ZERO, \
      BOOST_PP_DETAIL_IS_EMPTY_PROCESS \
      ) \
    (param) \
/**/
#define BOOST_PP_IS_EMPTY_ZERO(param) 0
# else
# if defined(__cplusplus) && __cplusplus > 201703L
# include <boost/preprocessor/variadic/has_opt.hpp>
#define BOOST_PP_IS_EMPTY(...) \
    BOOST_PP_DETAIL_IS_EMPTY_IIF \
      ( \
      BOOST_PP_VARIADIC_HAS_OPT() \
      ) \
      ( \
      BOOST_PP_IS_EMPTY_OPT, \
      BOOST_PP_IS_EMPTY_NO_OPT \
      ) \
    (__VA_ARGS__) \
/**/
#define BOOST_PP_IS_EMPTY_FUNCTION2(...) \
    __VA_OPT__(0,) 1 \
/**/
#define BOOST_PP_IS_EMPTY_FUNCTION(...) \
    BOOST_PP_IS_EMPTY_FUNCTION2(__VA_ARGS__) \
/**/
#define BOOST_PP_IS_EMPTY_OPT(...) \
    BOOST_PP_VARIADIC_HAS_OPT_ELEM0(BOOST_PP_IS_EMPTY_FUNCTION(__VA_ARGS__),) \
/**/
# else
#define BOOST_PP_IS_EMPTY(...) \
    BOOST_PP_IS_EMPTY_NO_OPT(__VA_ARGS__) \
/**/
# endif /* defined(__cplusplus) && __cplusplus > 201703L */
#define BOOST_PP_IS_EMPTY_NO_OPT(...) \
    BOOST_PP_DETAIL_IS_EMPTY_IIF \
      ( \
      BOOST_PP_IS_BEGIN_PARENS \
        ( \
        __VA_ARGS__ \
        ) \
      ) \
      ( \
      BOOST_PP_IS_EMPTY_ZERO, \
      BOOST_PP_DETAIL_IS_EMPTY_PROCESS \
      ) \
    (__VA_ARGS__) \
/**/
#define BOOST_PP_IS_EMPTY_ZERO(...) 0
# endif /* BOOST_PP_VARIADICS_MSVC && _MSC_VER <= 1400 */
# endif /* BOOST_PREPROCESSOR_FACILITIES_IS_EMPTY_VARIADIC_HPP */

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
