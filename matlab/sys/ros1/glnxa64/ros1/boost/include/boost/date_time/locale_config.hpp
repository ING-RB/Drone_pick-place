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

#ifndef DATE_TIME_LOCALE_CONFIG_HPP___
#define DATE_TIME_LOCALE_CONFIG_HPP___

/* Copyright (c) 2002-2020 CrystalClear Software, Inc.
 * Use, modification and distribution is subject to the
 * Boost Software License, Version 1.0. (See accompanying
 * file LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
 * Author: Jeff Garland
 * $Date$
 */

// This file configures whether the library will support locales and hence
// iostream based i/o.  Even if a compiler has some support for locales,
// any failure to be compatible gets the compiler on the exclusion list.
//
// At the moment this is defined for MSVC 6 and any compiler that
// defines BOOST_NO_STD_LOCALE (gcc 2.95.x)

#include "boost/config.hpp" //sets BOOST_NO_STD_LOCALE
#include "boost/config/workaround.hpp"

//This file basically becomes a noop if locales are not properly supported
#if (defined(BOOST_NO_STD_LOCALE)  \
 || (BOOST_WORKAROUND( BOOST_MSVC, < 1300)) \
 || (BOOST_WORKAROUND( BOOST_BORLANDC, BOOST_TESTED_AT( 0x581 )) ) \
 || (BOOST_WORKAROUND( BOOST_XLCPP_ZOS, BOOST_TESTED_AT( 0x42010000 )) ) /* <cctype> "shadows" the locale enabled overloads from <locale> */ \
 )
#define BOOST_DATE_TIME_NO_LOCALE
#endif


#endif


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
