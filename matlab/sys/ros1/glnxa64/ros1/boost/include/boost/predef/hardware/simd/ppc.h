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
Copyright Charly Chevalier 2015
Copyright Joel Falcou 2015
Distributed under the Boost Software License, Version 1.0.
(See accompanying file LICENSE_1_0.txt or copy at
http://www.boost.org/LICENSE_1_0.txt)
*/

#ifndef BOOST_PREDEF_HARDWARE_SIMD_PPC_H
#define BOOST_PREDEF_HARDWARE_SIMD_PPC_H

#include <boost/predef/version_number.h>
#include <boost/predef/hardware/simd/ppc/versions.h>

/* tag::reference[]
= `BOOST_HW_SIMD_PPC`

The SIMD extension for PowerPC (*if detected*).
Version number depends on the most recent detected extension.

[options="header"]
|===
| {predef_symbol} | {predef_version}

| `+__VECTOR4DOUBLE__+` | {predef_detection}

| `+__ALTIVEC__+` | {predef_detection}
| `+__VEC__+` | {predef_detection}

| `+__VSX__+` | {predef_detection}
|===

[options="header"]
|===
| {predef_symbol} | {predef_version}

| `+__VECTOR4DOUBLE__+` | BOOST_HW_SIMD_PPC_QPX_VERSION

| `+__ALTIVEC__+` | BOOST_HW_SIMD_PPC_VMX_VERSION
| `+__VEC__+` | BOOST_HW_SIMD_PPC_VMX_VERSION

| `+__VSX__+` | BOOST_HW_SIMD_PPC_VSX_VERSION
|===

*/ // end::reference[]

#define BOOST_HW_SIMD_PPC BOOST_VERSION_NUMBER_NOT_AVAILABLE

#undef BOOST_HW_SIMD_PPC
#if !defined(BOOST_HW_SIMD_PPC) && defined(__VECTOR4DOUBLE__)
#   define BOOST_HW_SIMD_PPC BOOST_HW_SIMD_PPC_QPX_VERSION
#endif
#if !defined(BOOST_HW_SIMD_PPC) && defined(__VSX__)
#   define BOOST_HW_SIMD_PPC BOOST_HW_SIMD_PPC_VSX_VERSION
#endif
#if !defined(BOOST_HW_SIMD_PPC) && (defined(__ALTIVEC__) || defined(__VEC__))
#   define BOOST_HW_SIMD_PPC BOOST_HW_SIMD_PPC_VMX_VERSION
#endif

#if !defined(BOOST_HW_SIMD_PPC)
#   define BOOST_HW_SIMD_PPC BOOST_VERSION_NUMBER_NOT_AVAILABLE
#else
#   define BOOST_HW_SIMD_PPC_AVAILABLE
#endif

#define BOOST_HW_SIMD_PPC_NAME "PPC SIMD"

#endif

#include <boost/predef/detail/test.h>
BOOST_PREDEF_DECLARE_TEST(BOOST_HW_SIMD_PPC, BOOST_HW_SIMD_PPC_NAME)

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
