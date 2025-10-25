#if !defined(MW_ENABLE_BOOST_WARNINGS)
#  if defined(__GNUC__)
#    pragma GCC system_header
#  elif defined(_MSC_VER)
     /* The matching "pop" is in header_suffix.h */
#    pragma warning(push, 1)
       /*
        * These suppressions are only here because of the apparent compiler bug:
        * http://komodo.mathworks.com/main/gecko?Action=view&Record=g782945
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

/*
 * Copyright (C) 2017 James E. King III
 *
 * Distributed under the Boost Software License, Version 1.0.
 * (See accompanying file LICENSE_1_0.txt or copy at
 *   http://www.boost.org/LICENSE_1_0.txt)
 */

#ifndef BOOST_PREDEF_LIBRARY_C_CLOUDABI_H
#define BOOST_PREDEF_LIBRARY_C_CLOUDABI_H

#include <boost/predef/version_number.h>
#include <boost/predef/make.h>

#include <boost/predef/library/c/_prefix.h>

#if defined(__CloudABI__)
#include <stddef.h>
#endif

/* tag::reference[]
= `BOOST_LIB_C_CLOUDABI`

https://github.com/NuxiNL/cloudlibc[cloudlibc] - CloudABI's standard C library.
Version number available as major, and minor.

[options="header"]
|===
| {predef_symbol} | {predef_version}

| `+__cloudlibc__+` | {predef_detection}

| `+__cloudlibc_major__+`, `+__cloudlibc_minor__+` | V.R.0
|===
*/ // end::reference[]

#define BOOST_LIB_C_CLOUDABI BOOST_VERSION_NUMBER_NOT_AVAILABLE

#if defined(__cloudlibc__)
#   undef BOOST_LIB_C_CLOUDABI
#   define BOOST_LIB_C_CLOUDABI \
            BOOST_VERSION_NUMBER(__cloudlibc_major__,__cloudlibc_minor__,0)
#endif

#if BOOST_LIB_C_CLOUDABI
#   define BOOST_LIB_C_CLOUDABI_AVAILABLE
#endif

#define BOOST_LIB_C_CLOUDABI_NAME "cloudlibc"

#endif

#include <boost/predef/detail/test.h>
BOOST_PREDEF_DECLARE_TEST(BOOST_LIB_C_CLOUDABI,BOOST_LIB_C_CLOUDABI_NAME)

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
