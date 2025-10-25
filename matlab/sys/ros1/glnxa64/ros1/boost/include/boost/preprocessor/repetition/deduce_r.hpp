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
# /* Revised by Edward Diener (2020) */
#
# /* See http://www.boost.org for most recent version. */
#
# ifndef BOOST_PREPROCESSOR_REPETITION_DEDUCE_R_HPP
# define BOOST_PREPROCESSOR_REPETITION_DEDUCE_R_HPP
#
# include <boost/preprocessor/config/config.hpp>
#
# if ~BOOST_PP_CONFIG_FLAGS() & BOOST_PP_CONFIG_STRICT()
#
# include <boost/preprocessor/detail/auto_rec.hpp>
# include <boost/preprocessor/repetition/for.hpp>
#
# /* BOOST_PP_DEDUCE_R */
#
# define BOOST_PP_DEDUCE_R() BOOST_PP_AUTO_REC(BOOST_PP_FOR_P, 256)
#
# else
#
# /* BOOST_PP_DEDUCE_R */
#
# include <boost/preprocessor/arithmetic/dec.hpp>
# include <boost/preprocessor/detail/auto_rec.hpp>
# include <boost/preprocessor/repetition/for.hpp>
# include <boost/preprocessor/config/limits.hpp>
#
# if BOOST_PP_LIMIT_FOR == 256
# define BOOST_PP_DEDUCE_R() BOOST_PP_DEC(BOOST_PP_AUTO_REC(BOOST_PP_FOR_P, 256))
# elif BOOST_PP_LIMIT_FOR == 512
# define BOOST_PP_DEDUCE_R() BOOST_PP_DEC(BOOST_PP_AUTO_REC(BOOST_PP_FOR_P, 512))
# elif BOOST_PP_LIMIT_FOR == 1024
# define BOOST_PP_DEDUCE_R() BOOST_PP_DEC(BOOST_PP_AUTO_REC(BOOST_PP_FOR_P, 1024))
# else
# error Incorrect value for the BOOST_PP_LIMIT_FOR limit
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
