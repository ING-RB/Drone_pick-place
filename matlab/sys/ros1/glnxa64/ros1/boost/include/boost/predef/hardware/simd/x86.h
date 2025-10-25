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

#ifndef BOOST_PREDEF_HARDWARE_SIMD_X86_H
#define BOOST_PREDEF_HARDWARE_SIMD_X86_H

#include <boost/predef/version_number.h>
#include <boost/predef/hardware/simd/x86/versions.h>

/* tag::reference[]
= `BOOST_HW_SIMD_X86`

The SIMD extension for x86 (*if detected*).
Version number depends on the most recent detected extension.

[options="header"]
|===
| {predef_symbol} | {predef_version}

| `+__SSE__+` | {predef_detection}
| `+_M_X64+` | {predef_detection}
| `_M_IX86_FP >= 1` | {predef_detection}

| `+__SSE2__+` | {predef_detection}
| `+_M_X64+` | {predef_detection}
| `_M_IX86_FP >= 2` | {predef_detection}

| `+__SSE3__+` | {predef_detection}

| `+__SSSE3__+` | {predef_detection}

| `+__SSE4_1__+` | {predef_detection}

| `+__SSE4_2__+` | {predef_detection}

| `+__AVX__+` | {predef_detection}

| `+__FMA__+` | {predef_detection}

| `+__AVX2__+` | {predef_detection}
|===

[options="header"]
|===
| {predef_symbol} | {predef_version}

| `+__SSE__+` | BOOST_HW_SIMD_X86_SSE_VERSION
| `+_M_X64+` | BOOST_HW_SIMD_X86_SSE_VERSION
| `_M_IX86_FP >= 1` | BOOST_HW_SIMD_X86_SSE_VERSION

| `+__SSE2__+` | BOOST_HW_SIMD_X86_SSE2_VERSION
| `+_M_X64+` | BOOST_HW_SIMD_X86_SSE2_VERSION
| `_M_IX86_FP >= 2` | BOOST_HW_SIMD_X86_SSE2_VERSION

| `+__SSE3__+` | BOOST_HW_SIMD_X86_SSE3_VERSION

| `+__SSSE3__+` | BOOST_HW_SIMD_X86_SSSE3_VERSION

| `+__SSE4_1__+` | BOOST_HW_SIMD_X86_SSE4_1_VERSION

| `+__SSE4_2__+` | BOOST_HW_SIMD_X86_SSE4_2_VERSION

| `+__AVX__+` | BOOST_HW_SIMD_X86_AVX_VERSION

| `+__FMA__+` | BOOST_HW_SIMD_X86_FMA3_VERSION

| `+__AVX2__+` | BOOST_HW_SIMD_X86_AVX2_VERSION
|===

*/ // end::reference[]

#define BOOST_HW_SIMD_X86 BOOST_VERSION_NUMBER_NOT_AVAILABLE

#undef BOOST_HW_SIMD_X86
#if !defined(BOOST_HW_SIMD_X86) && defined(__MIC__)
#   define BOOST_HW_SIMD_X86 BOOST_HW_SIMD_X86_MIC_VERSION
#endif
#if !defined(BOOST_HW_SIMD_X86) && defined(__AVX2__)
#   define BOOST_HW_SIMD_X86 BOOST_HW_SIMD_X86_AVX2_VERSION
#endif
#if !defined(BOOST_HW_SIMD_X86) && defined(__AVX__)
#   define BOOST_HW_SIMD_X86 BOOST_HW_SIMD_X86_AVX_VERSION
#endif
#if !defined(BOOST_HW_SIMD_X86) && defined(__FMA__)
#   define BOOST_HW_SIMD_X86 BOOST_HW_SIMD_X86_FMA_VERSION
#endif
#if !defined(BOOST_HW_SIMD_X86) && defined(__SSE4_2__)
#   define BOOST_HW_SIMD_X86 BOOST_HW_SIMD_X86_SSE4_2_VERSION
#endif
#if !defined(BOOST_HW_SIMD_X86) && defined(__SSE4_1__)
#   define BOOST_HW_SIMD_X86 BOOST_HW_SIMD_X86_SSE4_1_VERSION
#endif
#if !defined(BOOST_HW_SIMD_X86) && defined(__SSSE3__)
#   define BOOST_HW_SIMD_X86 BOOST_HW_SIMD_X86_SSSE3_VERSION
#endif
#if !defined(BOOST_HW_SIMD_X86) && defined(__SSE3__)
#   define BOOST_HW_SIMD_X86 BOOST_HW_SIMD_X86_SSE3_VERSION
#endif
#if !defined(BOOST_HW_SIMD_X86) && (defined(__SSE2__) || defined(_M_X64) || (defined(_M_IX86_FP) && _M_IX86_FP >= 2))
#   define BOOST_HW_SIMD_X86 BOOST_HW_SIMD_X86_SSE2_VERSION
#endif
#if !defined(BOOST_HW_SIMD_X86) && (defined(__SSE__) || defined(_M_X64) || (defined(_M_IX86_FP) && _M_IX86_FP >= 1))
#   define BOOST_HW_SIMD_X86 BOOST_HW_SIMD_X86_SSE_VERSION
#endif
#if !defined(BOOST_HW_SIMD_X86) && defined(__MMX__)
#   define BOOST_HW_SIMD_X86 BOOST_HW_SIMD_X86_MMX_VERSION
#endif

#if !defined(BOOST_HW_SIMD_X86)
#   define BOOST_HW_SIMD_X86 BOOST_VERSION_NUMBER_NOT_AVAILABLE
#else
#   define BOOST_HW_SIMD_X86_AVAILABLE
#endif

#define BOOST_HW_SIMD_X86_NAME "x86 SIMD"

#endif

#include <boost/predef/detail/test.h>
BOOST_PREDEF_DECLARE_TEST(BOOST_HW_SIMD_X86, BOOST_HW_SIMD_X86_NAME)

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
