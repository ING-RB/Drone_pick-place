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
Copyright Rene Rivera 2008-2015
Distributed under the Boost Software License, Version 1.0.
(See accompanying file LICENSE_1_0.txt or copy at
http://www.boost.org/LICENSE_1_0.txt)
*/

#ifndef BOOST_PREDEF_OS_QNXNTO_H
#define BOOST_PREDEF_OS_QNXNTO_H

#include <boost/predef/version_number.h>
#include <boost/predef/make.h>

/* tag::reference[]
= `BOOST_OS_QNX`

http://en.wikipedia.org/wiki/QNX[QNX] operating system.
Version number available as major, and minor if possible. And
version 4 is specifically detected.

[options="header"]
|===
| {predef_symbol} | {predef_version}

| `+__QNX__+` | {predef_detection}
| `+__QNXNTO__+` | {predef_detection}

| `+_NTO_VERSION+` | V.R.0
| `+__QNX__+` | 4.0.0
|===
*/ // end::reference[]

#define BOOST_OS_QNX BOOST_VERSION_NUMBER_NOT_AVAILABLE

#if !defined(BOOST_PREDEF_DETAIL_OS_DETECTED) && ( \
    defined(__QNX__) || defined(__QNXNTO__) \
    )
#   undef BOOST_OS_QNX
#   if !defined(BOOST_OS_QNX) && defined(_NTO_VERSION)
#       define BOOST_OS_QNX BOOST_PREDEF_MAKE_10_VVRR(_NTO_VERSION)
#   endif
#   if !defined(BOOST_OS_QNX) && defined(__QNX__)
#       define BOOST_OS_QNX BOOST_VERSION_NUMBER(4,0,0)
#   endif
#   if !defined(BOOST_OS_QNX)
#       define BOOST_OS_QNX BOOST_VERSION_NUMBER_AVAILABLE
#   endif
#endif

#if BOOST_OS_QNX
#   define BOOST_OS_QNX_AVAILABLE
#   include <boost/predef/detail/os_detected.h>
#endif

#define BOOST_OS_QNX_NAME "QNX"

#endif

#include <boost/predef/detail/test.h>
BOOST_PREDEF_DECLARE_TEST(BOOST_OS_QNX,BOOST_OS_QNX_NAME)

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
