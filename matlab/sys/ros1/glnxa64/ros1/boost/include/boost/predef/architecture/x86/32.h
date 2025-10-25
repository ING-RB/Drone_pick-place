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

#ifndef BOOST_PREDEF_ARCHITECTURE_X86_32_H
#define BOOST_PREDEF_ARCHITECTURE_X86_32_H

#include <boost/predef/version_number.h>
#include <boost/predef/make.h>

/* tag::reference[]
= `BOOST_ARCH_X86_32`

http://en.wikipedia.org/wiki/X86[Intel x86] architecture:
If available versions [3-6] are specifically detected.

[options="header"]
|===
| {predef_symbol} | {predef_version}

| `i386` | {predef_detection}
| `+__i386__+` | {predef_detection}
| `+__i486__+` | {predef_detection}
| `+__i586__+` | {predef_detection}
| `+__i686__+` | {predef_detection}
| `+__i386+` | {predef_detection}
| `+_M_IX86+` | {predef_detection}
| `+_X86_+` | {predef_detection}
| `+__THW_INTEL__+` | {predef_detection}
| `+__I86__+` | {predef_detection}
| `+__INTEL__+` | {predef_detection}

| `+__I86__+` | V.0.0
| `+_M_IX86+` | V.0.0
| `+__i686__+` | 6.0.0
| `+__i586__+` | 5.0.0
| `+__i486__+` | 4.0.0
| `+__i386__+` | 3.0.0
|===
*/ // end::reference[]

#define BOOST_ARCH_X86_32 BOOST_VERSION_NUMBER_NOT_AVAILABLE

#if defined(i386) || defined(__i386__) || \
    defined(__i486__) || defined(__i586__) || \
    defined(__i686__) || defined(__i386) || \
    defined(_M_IX86) || defined(_X86_) || \
    defined(__THW_INTEL__) || defined(__I86__) || \
    defined(__INTEL__)
#   undef BOOST_ARCH_X86_32
#   if !defined(BOOST_ARCH_X86_32) && defined(__I86__)
#       define BOOST_ARCH_X86_32 BOOST_VERSION_NUMBER(__I86__,0,0)
#   endif
#   if !defined(BOOST_ARCH_X86_32) && defined(_M_IX86)
#       define BOOST_ARCH_X86_32 BOOST_PREDEF_MAKE_10_VV00(_M_IX86)
#   endif
#   if !defined(BOOST_ARCH_X86_32) && defined(__i686__)
#       define BOOST_ARCH_X86_32 BOOST_VERSION_NUMBER(6,0,0)
#   endif
#   if !defined(BOOST_ARCH_X86_32) && defined(__i586__)
#       define BOOST_ARCH_X86_32 BOOST_VERSION_NUMBER(5,0,0)
#   endif
#   if !defined(BOOST_ARCH_X86_32) && defined(__i486__)
#       define BOOST_ARCH_X86_32 BOOST_VERSION_NUMBER(4,0,0)
#   endif
#   if !defined(BOOST_ARCH_X86_32) && defined(__i386__)
#       define BOOST_ARCH_X86_32 BOOST_VERSION_NUMBER(3,0,0)
#   endif
#   if !defined(BOOST_ARCH_X86_32)
#       define BOOST_ARCH_X86_32 BOOST_VERSION_NUMBER_AVAILABLE
#   endif
#endif

#if BOOST_ARCH_X86_32
#   define BOOST_ARCH_X86_32_AVAILABLE
#endif

#if BOOST_ARCH_X86_32
#   undef BOOST_ARCH_WORD_BITS_32
#   define BOOST_ARCH_WORD_BITS_32 BOOST_VERSION_NUMBER_AVAILABLE
#endif

#define BOOST_ARCH_X86_32_NAME "Intel x86-32"

#include <boost/predef/architecture/x86.h>

#endif

#include <boost/predef/detail/test.h>
BOOST_PREDEF_DECLARE_TEST(BOOST_ARCH_X86_32,BOOST_ARCH_X86_32_NAME)

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
