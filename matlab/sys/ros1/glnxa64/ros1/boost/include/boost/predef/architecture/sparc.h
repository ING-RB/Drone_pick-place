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

#ifndef BOOST_PREDEF_ARCHITECTURE_SPARC_H
#define BOOST_PREDEF_ARCHITECTURE_SPARC_H

#include <boost/predef/version_number.h>
#include <boost/predef/make.h>

/* tag::reference[]
= `BOOST_ARCH_SPARC`

http://en.wikipedia.org/wiki/SPARC[SPARC] architecture.

[options="header"]
|===
| {predef_symbol} | {predef_version}

| `+__sparc__+` | {predef_detection}
| `+__sparc+` | {predef_detection}

| `+__sparcv9+` | 9.0.0
| `+__sparc_v9__+` | 9.0.0
| `+__sparcv8+` | 8.0.0
| `+__sparc_v8__+` | 8.0.0
|===
*/ // end::reference[]

#define BOOST_ARCH_SPARC BOOST_VERSION_NUMBER_NOT_AVAILABLE

#if defined(__sparc__) || defined(__sparc)
#   undef BOOST_ARCH_SPARC
#   if !defined(BOOST_ARCH_SPARC) && (defined(__sparcv9) || defined(__sparc_v9__))
#       define BOOST_ARCH_SPARC BOOST_VERSION_NUMBER(9,0,0)
#   endif
#   if !defined(BOOST_ARCH_SPARC) && (defined(__sparcv8) || defined(__sparc_v8__))
#       define BOOST_ARCH_SPARC BOOST_VERSION_NUMBER(8,0,0)
#   endif
#   if !defined(BOOST_ARCH_SPARC)
#       define BOOST_ARCH_SPARC BOOST_VERSION_NUMBER_AVAILABLE
#   endif
#endif

#if BOOST_ARCH_SPARC
#   define BOOST_ARCH_SPARC_AVAILABLE
#endif

#if BOOST_ARCH_SPARC
#   if BOOST_ARCH_SPARC >= BOOST_VERSION_NUMBER(9,0,0)
#       undef BOOST_ARCH_WORD_BITS_64
#       define BOOST_ARCH_WORD_BITS_64 BOOST_VERSION_NUMBER_AVAILABLE
#   else
#       undef BOOST_ARCH_WORD_BITS_32
#       define BOOST_ARCH_WORD_BITS_32 BOOST_VERSION_NUMBER_AVAILABLE
#   endif
#endif

#define BOOST_ARCH_SPARC_NAME "SPARC"

#endif

#include <boost/predef/detail/test.h>
BOOST_PREDEF_DECLARE_TEST(BOOST_ARCH_SPARC,BOOST_ARCH_SPARC_NAME)

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
