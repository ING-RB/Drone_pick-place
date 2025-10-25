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

#ifndef BOOST_PREDEF_ARCHITECTURE_SUPERH_H
#define BOOST_PREDEF_ARCHITECTURE_SUPERH_H

#include <boost/predef/version_number.h>
#include <boost/predef/make.h>

/* tag::reference[]
= `BOOST_ARCH_SH`

http://en.wikipedia.org/wiki/SuperH[SuperH] architecture:
If available versions [1-5] are specifically detected.

[options="header"]
|===
| {predef_symbol} | {predef_version}

| `+__sh__+` | {predef_detection}

| `+__SH5__+` | 5.0.0
| `+__SH4__+` | 4.0.0
| `+__sh3__+` | 3.0.0
| `+__SH3__+` | 3.0.0
| `+__sh2__+` | 2.0.0
| `+__sh1__+` | 1.0.0
|===
*/ // end::reference[]

#define BOOST_ARCH_SH BOOST_VERSION_NUMBER_NOT_AVAILABLE

#if defined(__sh__)
#   undef BOOST_ARCH_SH
#   if !defined(BOOST_ARCH_SH) && (defined(__SH5__))
#       define BOOST_ARCH_SH BOOST_VERSION_NUMBER(5,0,0)
#   endif
#   if !defined(BOOST_ARCH_SH) && (defined(__SH4__))
#       define BOOST_ARCH_SH BOOST_VERSION_NUMBER(4,0,0)
#   endif
#   if !defined(BOOST_ARCH_SH) && (defined(__sh3__) || defined(__SH3__))
#       define BOOST_ARCH_SH BOOST_VERSION_NUMBER(3,0,0)
#   endif
#   if !defined(BOOST_ARCH_SH) && (defined(__sh2__))
#       define BOOST_ARCH_SH BOOST_VERSION_NUMBER(2,0,0)
#   endif
#   if !defined(BOOST_ARCH_SH) && (defined(__sh1__))
#       define BOOST_ARCH_SH BOOST_VERSION_NUMBER(1,0,0)
#   endif
#   if !defined(BOOST_ARCH_SH)
#       define BOOST_ARCH_SH BOOST_VERSION_NUMBER_AVAILABLE
#   endif
#endif

#if BOOST_ARCH_SH
#   define BOOST_ARCH_SH_AVAILABLE
#endif

#if BOOST_ARCH_SH
#   if BOOST_ARCH_SH >= BOOST_VERSION_NUMBER(5,0,0)
#       undef BOOST_ARCH_WORD_BITS_64
#       define BOOST_ARCH_WORD_BITS_64 BOOST_VERSION_NUMBER_AVAILABLE
#   elif BOOST_ARCH_SH >= BOOST_VERSION_NUMBER(3,0,0)
#       undef BOOST_ARCH_WORD_BITS_32
#       define BOOST_ARCH_WORD_BITS_32 BOOST_VERSION_NUMBER_AVAILABLE
#   else
#       undef BOOST_ARCH_WORD_BITS_16
#       define BOOST_ARCH_WORD_BITS_16 BOOST_VERSION_NUMBER_AVAILABLE
#   endif
#endif

#define BOOST_ARCH_SH_NAME "SuperH"

#endif

#include <boost/predef/detail/test.h>
BOOST_PREDEF_DECLARE_TEST(BOOST_ARCH_SH,BOOST_ARCH_SH_NAME)

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
