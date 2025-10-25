/* Copyright 2016-2024 The MathWorks, Inc. */

/* Used with Clang compiler only */

#ifndef __POLYSPACE__CLANG_H
#define __POLYSPACE__CLANG_H

/* Temporary definition of clang predefined macros. */
#ifndef __building_module
#define __building_module(X) 0
#endif
/* Handle all -Wxxx options as disabled. */
#ifndef __has_warning
#define __has_warning(X) 0
#endif

/*
 * Clang compiler macros.
 */

#ifndef __clang__
#define __clang__ 1
#endif /* __clang__ */

#ifndef __clang_major__
#define __clang_major__ 6
#endif /* __clang_major__ */

#ifndef __clang_minor__
#define __clang_minor__ 1
#endif /* __clang_minor__ */

#ifndef __clang_patchlevel__
#define __clang_patchlevel__ 0
#endif /* __clang_patchlevel__ */

#ifndef __clang_version__
#define __clang_version__ "6.1.0 (clang-602.0.53)"
#endif /* __clang_version__ */

#if !defined(__APPLE__)&&!defined(__CloudABI__)&&!defined(__FreeBSD__)&&!defined(__Fuchsia__) \
  &&!defined(__MINGW32__)&&!defined(__NetBSD__)&&!defined(__linux__)&&!defined(__sun__)&&!defined(_WIN32)
#define __linux__ 1
#endif

#ifndef __GNUC__
#define __GNUC__ 4
#endif /* __GNUC__ */

#ifndef __GNUG__
#define __GNUG__ 4
#endif /* __GNUG__ */

#ifndef __GNUC_MINOR__
#define __GNUC_MINOR__ 2
#endif /* __GNUC_MINOR__ */

#ifndef __GNUC_PATCHLEVEL__
#define __GNUC_PATCHLEVEL__ 1
#endif /* __GNUC_PATCHLEVEL__ */

#ifndef __GNUC_GNU_INLINE__
#define __GNUC_GNU_INLINE__ 1
#endif /* __GNUC_GNU_INLINE__ */


#ifndef __GXX_ABI_VERSION
#define __GXX_ABI_VERSION 1002
#endif /* __GXX_ABI_VERSION */

#ifndef __GXX_RTTI
#define __GXX_RTTI 1
#endif /* __GXX_RTTI */

#ifndef __GXX_WEAK__
#define __GXX_WEAK__ 1
#endif /* __GXX_WEAK__ */


/*
 * Architecture macros
 */
#if !defined(__MMX__) && !defined(__SSE2_MATH__) && !defined(__SSE2__) && !defined(__SSE3__) \
  && !defined(__SSE_MATH__) && !defined(__SSE__) && !defined(__SSP__) && !defined(__SSSE3__) \
  && !defined(__core2) && !defined(__core2__) && !defined(__tune_core2__) \
  && !defined(__ARM_NEON__) && !defined(__ARM_NEON)
#define __MMX__ 1
#define __SSE2_MATH__ 1
#define __SSE2__ 1
#define __SSE3__ 1
#define __SSE_MATH__ 1
#define __SSE__ 1
#define __SSP__ 1
#define __SSSE3__ 1
#define __core2 1
#define __core2__ 1
#define __tune_core2__ 1
#endif


#if defined(__VXWORKS__) || defined(__vxworks)
#ifdef __EDG__
#undef __EDG__
#endif
#endif


#ifdef __XTENSA__
#ifndef immediate
#define immediate int
#endif
#if !defined(__XTENSA_EL__) && !defined(__XTENSA_EB__)
#define __XTENSA_EL__ 1 // Default big endian, 3: little endian floating-point
#endif
#ifndef _TIE_xtbool
#define _TIE_xtbool int
#define _TIE_xtbool2 int
#define _TIE_xtbool4 int
#define _TIE_xtbool8 int
#define _TIE_xtbool16 int
#endif
#if defined __cplusplus && (__cplusplus < 201103L)
#define _HAS_NULLPTR_T 0
#endif
#endif


// Diab7 C++ system headers require that __EDG_TYPE_TRAITS_ENABLED is not defined
#if defined __DCC__ && (defined __arm__ || defined __aarch64__)
#undef __EDG_TYPE_TRAITS_ENABLED
#endif


/*
 * Utility macros
 */
#define __builtin_expect(e,k) (e)
#define __builtin_expect_with_probability(e,k,p) (e)

#ifndef __DEPRECATED
#define __DEPRECATED 1
#endif /* __DEPRECATED */

#ifndef __DYNAMIC__
#define __DYNAMIC__ 1
#endif /* __DYNAMIC__ */

#ifndef __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__
#define __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ 101000
#endif /* __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ */

#ifndef __EXCEPTIONS
#define __EXCEPTIONS 1
#endif /* __EXCEPTIONS */

#if !defined(__ELF__) && !defined(__MACH__) && !defined(WIN32) && !defined(_WIN32)
#define __ELF__ 1
#endif /* __ELF__ */

#ifndef __NO_INLINE__
#define __NO_INLINE__ 1
#endif /* __NO_INLINE__ */

#ifndef __NO_MATH_INLINES
#define __NO_MATH_INLINES 1
#endif /* __NO_MATH_INLINES */

#ifndef __PIC__
#define __PIC__ 2
#endif /* __PIC__ */

#ifndef __PRAGMA_REDEFINE_EXTNAME
#define __PRAGMA_REDEFINE_EXTNAME 1
#endif /* __PRAGMA_REDEFINE_EXTNAME */

#ifndef __STDC__
#define __STDC__ 1
#endif /* __STDC__ */

#ifndef __STDC_HOSTED__
#define __STDC_HOSTED__ 1
#endif /* __STDC_HOSTED__ */

#ifndef __STDC_UTF_16__
#define __STDC_UTF_16__ 1
#endif /* __STDC_UTF_16__ */

#ifndef __STDC_UTF_32__
#define __STDC_UTF_32__ 1
#endif /* __STDC_UTF_32__ */

#ifndef __USER_LABEL_PREFIX__
#define __USER_LABEL_PREFIX__ _
#endif /* __USER_LABEL_PREFIX__ */

#ifndef __VERSION__
#define __VERSION__ "4.2.1 Compatible Apple LLVM 6.1.0 (clang-602.0.53)"
#endif /* __VERSION__ */

#ifndef __llvm__
#define __llvm__ 1
#endif /* __llvm__ */

#ifndef __pic__
#define __pic__ 2
#endif /* __pic__ */

#ifndef __private_extern__
#define __private_extern__ extern
#endif /* __private_extern__ */

#ifndef __strong
#define __strong
#endif /* __strong */

#ifndef __unsafe_unretained
#define __unsafe_unretained
#endif /* __unsafe_unretained */

#ifndef __weak
#define __weak __attribute__((objc_gc(weak)))
#endif /* __weak */


/* Undefined as the clang blocks feature is not supported */
#ifdef __BLOCKS__
#undef __BLOCKS__
#endif

#ifndef __block
#define __block __attribute__((__blocks__(byref)))
#endif /* __block */






#ifndef __CHAR16_TYPE__
#define __CHAR16_TYPE__ unsigned short
#endif /* __CHAR16_TYPE__ */

#ifndef __CHAR32_TYPE__
#define __CHAR32_TYPE__ unsigned int
#endif /* __CHAR32_TYPE__ */

#ifndef __CHAR_BIT__
#define __CHAR_BIT__ 8
#endif /* __CHAR_BIT__ */

#ifndef __CONSTANT_CFSTRINGS__
#define __CONSTANT_CFSTRINGS__ 1
#endif /* __CONSTANT_CFSTRINGS__ */

#ifndef __FLT_DENORM_MIN__
#define __FLT_DENORM_MIN__ 1.40129846e-45F
#endif /* __FLT_DENORM_MIN__ */

#ifndef __DBL_DENORM_MIN__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_DENORM_MIN__ __FLT_DENORM_MIN__
#else
#define __DBL_DENORM_MIN__ 4.9406564584124654e-324
#endif
#endif /* __DBL_DENORM_MIN__ */

#ifndef __DBL_DIG__
#define __DBL_DIG__ 15
#endif /* __DBL_DIG__ */

#ifndef __FLT_EPSILON__
#define __FLT_EPSILON__ 1.19209290e-7F
#endif /* __FLT_EPSILON__ */

#ifndef __DBL_EPSILON__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_EPSILON__ __FLT_EPSILON__
#else
#define __DBL_EPSILON__ 2.2204460492503131e-16
#endif
#endif /* __DBL_EPSILON__ */

#ifndef __FLT_HAS_DENORM__
#define __FLT_HAS_DENORM__ 1
#endif /* __FLT_HAS_DENORM__ */

#ifndef __DBL_HAS_DENORM__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_HAS_DENORM__ __FLT_HAS_DENORM__
#else
#define __DBL_HAS_DENORM__ 1
#endif
#endif /* __DBL_HAS_DENORM__ */

#ifndef __FLT_HAS_INFINITY__
#define __FLT_HAS_INFINITY__ 1
#endif /* __FLT_HAS_INFINITY__ */

#ifndef __DBL_HAS_INFINITY__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_HAS_INFINITY__ __FLT_HAS_INFINITY__
#else
#define __DBL_HAS_INFINITY__ 1
#endif
#endif /* __DBL_HAS_INFINITY__ */

#ifndef __FLT_HAS_QUIET_NAN__
#define __FLT_HAS_QUIET_NAN__ 1
#endif /* __FLT_HAS_QUIET_NAN__ */

#ifndef __DBL_HAS_QUIET_NAN__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_HAS_QUIET_NAN__ __FLT_HAS_QUIET_NAN__
#else
#define __DBL_HAS_QUIET_NAN__ 1
#endif
#endif /* __DBL_HAS_QUIET_NAN__ */

#ifndef __FLT_MANT_DIG__
#define __FLT_MANT_DIG__ 24
#endif /* __FLT_MANT_DIG__ */

#ifndef __DBL_MANT_DIG__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_MANT_DIG__ __FLT_MANT_DIG__
#else
#define __DBL_MANT_DIG__ 53
#endif
#endif /* __DBL_MANT_DIG__ */

#ifndef __FLT_MAX_10_EXP__
#define __FLT_MAX_10_EXP__ 38
#endif /* __FLT_MAX_10_EXP__ */

#ifndef __DBL_MAX_10_EXP__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_MAX_10_EXP__ __FLT_MAX_10_EXP__
#else
#define __DBL_MAX_10_EXP__ 308
#endif
#endif /* __DBL_MAX_10_EXP__ */

#ifndef __FLT_MAX_EXP__
#define __FLT_MAX_EXP__ 128
#endif /* __FLT_MAX_EXP__ */

#ifndef __DBL_MAX_EXP__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_MAX_EXP__ __FLT_MAX_EXP__
#else
#define __DBL_MAX_EXP__ 1024
#endif
#endif /* __DBL_MAX_EXP__ */

#ifndef __FLT_MAX__
#define __FLT_MAX__ 3.40282347e+38F
#endif /* __FLT_MAX__ */

#ifndef __DBL_MAX__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_MAX__ __FLT_MAX__
#else
#define __DBL_MAX__ 1.7976931348623157e+308
#endif
#endif /* __DBL_MAX__ */

#ifndef __FLT_MIN_10_EXP__
#define __FLT_MIN_10_EXP__ (-37)
#endif /* __FLT_MIN_10_EXP__ */

#ifndef __DBL_MIN_10_EXP__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_MIN_10_EXP__ __FLT_MIN_10_EXP__
#else
#define __DBL_MIN_10_EXP__ (-307)
#endif
#endif /* __DBL_MIN_10_EXP__ */

#ifndef __FLT_MIN_EXP__
#define __FLT_MIN_EXP__ (-125)
#endif /* __FLT_MIN_EXP__ */

#ifndef __DBL_MIN_EXP__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_MIN_EXP__ __FLT_MIN_EXP__
#else
#define __DBL_MIN_EXP__ (-1021)
#endif
#endif /* __DBL_MIN_EXP__ */

#ifndef __FLT_MIN__
#define __FLT_MIN__ 1.17549435e-38F
#endif /* __FLT_MIN__ */

#ifndef __DBL_MIN__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_MIN__ __FLT_MIN__
#else
#define __DBL_MIN__ 2.2250738585072014e-308
#endif
#endif /* __DBL_MIN__ */

#ifndef __DECIMAL_DIG__
#define __DECIMAL_DIG__ 21
#endif /* __DECIMAL_DIG__ */

#ifndef __FINITE_MATH_ONLY__
#define __FINITE_MATH_ONLY__ 0
#endif /* __FINITE_MATH_ONLY__ */

#ifndef __FLT_DIG__
#define __FLT_DIG__ 6
#endif /* __FLT_DIG__ */

#ifndef __FLT_EVAL_METHOD__
#ifdef __PST_64BIT_TARGET__
#define __FLT_EVAL_METHOD__ 0
#else
#define __FLT_EVAL_METHOD__ 2
#endif
#endif /* __FLT_EVAL_METHOD__ */

#ifndef __FLT_RADIX__
#define __FLT_RADIX__ 2
#endif /* __FLT_RADIX__ */


#ifndef __GCC_HAVE_SYNC_COMPARE_AND_SWAP_1
#define __GCC_HAVE_SYNC_COMPARE_AND_SWAP_1 1
#endif /* __GCC_HAVE_SYNC_COMPARE_AND_SWAP_1 */

#ifndef __GCC_HAVE_SYNC_COMPARE_AND_SWAP_16
#define __GCC_HAVE_SYNC_COMPARE_AND_SWAP_16 1
#endif /* __GCC_HAVE_SYNC_COMPARE_AND_SWAP_16 */

#ifndef __GCC_HAVE_SYNC_COMPARE_AND_SWAP_2
#define __GCC_HAVE_SYNC_COMPARE_AND_SWAP_2 1
#endif /* __GCC_HAVE_SYNC_COMPARE_AND_SWAP_2 */

#ifndef __GCC_HAVE_SYNC_COMPARE_AND_SWAP_4
#define __GCC_HAVE_SYNC_COMPARE_AND_SWAP_4 1
#endif /* __GCC_HAVE_SYNC_COMPARE_AND_SWAP_4 */

#ifndef __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8
#define __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8 1
#endif /* __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8 */

#ifndef __INT16_C_SUFFIX__
#define __INT16_C_SUFFIX__
#endif /* __INT16_C_SUFFIX__ */

#ifndef __INT16_FMTd__
#define __INT16_FMTd__ "hd"
#endif /* __INT16_FMTd__ */

#ifndef __INT16_FMTi__
#define __INT16_FMTi__ "hi"
#endif /* __INT16_FMTi__ */

#ifndef __INT16_MAX__
#define __INT16_MAX__ 32767
#endif /* __INT16_MAX__ */

#ifndef __INT16_TYPE__
#define __INT16_TYPE__ short
#endif /* __INT16_TYPE__ */

#ifndef __INT32_C_SUFFIX__
#define __INT32_C_SUFFIX__
#endif /* __INT32_C_SUFFIX__ */

#ifndef __INT32_FMTd__
#define __INT32_FMTd__ "d"
#endif /* __INT32_FMTd__ */

#ifndef __INT32_FMTi__
#define __INT32_FMTi__ "i"
#endif /* __INT32_FMTi__ */

#ifndef __INT32_MAX__
#define __INT32_MAX__ 2147483647
#endif /* __INT32_MAX__ */

#ifndef __INT32_TYPE__
#define __INT32_TYPE__ int
#endif /* __INT32_TYPE__ */

#ifndef __INT64_C_SUFFIX__
#define __INT64_C_SUFFIX__ LL
#endif /* __INT64_C_SUFFIX__ */

#ifndef __INT64_FMTd__
#define __INT64_FMTd__ "lld"
#endif /* __INT64_FMTd__ */

#ifndef __INT64_FMTi__
#define __INT64_FMTi__ "lli"
#endif /* __INT64_FMTi__ */

#ifndef __INT64_MAX__
#define __INT64_MAX__ 9223372036854775807LL
#endif /* __INT64_MAX__ */

#ifndef __INT64_TYPE__
#define __INT64_TYPE__ long long int
#endif /* __INT64_TYPE__ */

#ifndef __INT8_C_SUFFIX__
#define __INT8_C_SUFFIX__
#endif /* __INT8_C_SUFFIX__ */

#ifndef __INT8_FMTd__
#define __INT8_FMTd__ "hhd"
#endif /* __INT8_FMTd__ */

#ifndef __INT8_FMTi__
#define __INT8_FMTi__ "hhi"
#endif /* __INT8_FMTi__ */

#ifndef __INT8_MAX__
#define __INT8_MAX__ 127
#endif /* __INT8_MAX__ */

#ifndef __INT8_TYPE__
#define __INT8_TYPE__ signed char
#endif /* __INT8_TYPE__ */

#ifndef __INTMAX_C_SUFFIX__
#define __INTMAX_C_SUFFIX__ L
#endif /* __INTMAX_C_SUFFIX__ */

#ifndef __INTMAX_FMTd__
#define __INTMAX_FMTd__ "ld"
#endif /* __INTMAX_FMTd__ */

#ifndef __INTMAX_FMTi__
#define __INTMAX_FMTi__ "li"
#endif /* __INTMAX_FMTi__ */

#ifndef __INTMAX_MAX__
#define __INTMAX_MAX__ 9223372036854775807L
#endif /* __INTMAX_MAX__ */

#ifndef __INTMAX_TYPE__
#ifdef __PST_64BIT_TARGET__
#define __INTMAX_TYPE__ long int
#else
#define __INTMAX_TYPE__ long long int
#endif
#endif /* __INTMAX_TYPE__ */

#ifndef __INTMAX_WIDTH__
#define __INTMAX_WIDTH__ 64
#endif /* __INTMAX_WIDTH__ */

#ifndef __INTPTR_FMTd__
#define __INTPTR_FMTd__ "ld"
#endif /* __INTPTR_FMTd__ */

#ifndef __INTPTR_FMTi__
#define __INTPTR_FMTi__ "li"
#endif /* __INTPTR_FMTi__ */

#ifndef __INTPTR_MAX__
#define __INTPTR_MAX__ 9223372036854775807L
#endif /* __INTPTR_MAX__ */

#ifndef __INTPTR_TYPE__
#define __INTPTR_TYPE__ long int
#endif /* __INTPTR_TYPE__ */

#ifndef __INTPTR_WIDTH__
#define __INTPTR_WIDTH__ 64
#endif /* __INTPTR_WIDTH__ */

#ifndef __INT_FAST16_FMTd__
#define __INT_FAST16_FMTd__ "hd"
#endif /* __INT_FAST16_FMTd__ */

#ifndef __INT_FAST16_FMTi__
#define __INT_FAST16_FMTi__ "hi"
#endif /* __INT_FAST16_FMTi__ */

#ifndef __INT_FAST16_MAX__
#define __INT_FAST16_MAX__ 32767
#endif /* __INT_FAST16_MAX__ */

#ifndef __INT_FAST16_TYPE__
#define __INT_FAST16_TYPE__ short
#endif /* __INT_FAST16_TYPE__ */

#ifndef __INT_FAST32_FMTd__
#define __INT_FAST32_FMTd__ "d"
#endif /* __INT_FAST32_FMTd__ */

#ifndef __INT_FAST32_FMTi__
#define __INT_FAST32_FMTi__ "i"
#endif /* __INT_FAST32_FMTi__ */

#ifndef __INT_FAST32_MAX__
#define __INT_FAST32_MAX__ 2147483647
#endif /* __INT_FAST32_MAX__ */

#ifndef __INT_FAST32_TYPE__
#ifdef __PST_64BIT_TARGET__
#define __INT_FAST32_TYPE__ long int
#else
#define __INT_FAST32_TYPE__ int
#endif
#endif /* __INT_FAST32_TYPE__ */

#ifndef __INT_FAST64_FMTd__
#define __INT_FAST64_FMTd__ "ld"
#endif /* __INT_FAST64_FMTd__ */

#ifndef __INT_FAST64_FMTi__
#define __INT_FAST64_FMTi__ "li"
#endif /* __INT_FAST64_FMTi__ */

#ifndef __INT_FAST64_MAX__
#define __INT_FAST64_MAX__ 9223372036854775807L
#endif /* __INT_FAST64_MAX__ */

#ifndef __INT_FAST64_TYPE__
#ifdef __PST_64BIT_TARGET__
#define __INT_FAST64_TYPE__ long int
#else
#define __INT_FAST64_TYPE__ long long int
#endif
#endif /* __INT_FAST64_TYPE__ */

#ifndef __INT_FAST8_FMTd__
#define __INT_FAST8_FMTd__ "hhd"
#endif /* __INT_FAST8_FMTd__ */

#ifndef __INT_FAST8_FMTi__
#define __INT_FAST8_FMTi__ "hhi"
#endif /* __INT_FAST8_FMTi__ */

#ifndef __INT_FAST8_MAX__
#define __INT_FAST8_MAX__ 127
#endif /* __INT_FAST8_MAX__ */

#ifndef __INT_FAST8_TYPE__
#define __INT_FAST8_TYPE__ signed char
#endif /* __INT_FAST8_TYPE__ */

#ifndef __INT_LEAST16_FMTd__
#define __INT_LEAST16_FMTd__ "hd"
#endif /* __INT_LEAST16_FMTd__ */

#ifndef __INT_LEAST16_FMTi__
#define __INT_LEAST16_FMTi__ "hi"
#endif /* __INT_LEAST16_FMTi__ */

#ifndef __INT_LEAST16_MAX__
#define __INT_LEAST16_MAX__ 32767
#endif /* __INT_LEAST16_MAX__ */

#ifndef __INT_LEAST16_TYPE__
#define __INT_LEAST16_TYPE__ short
#endif /* __INT_LEAST16_TYPE__ */

#ifndef __INT_LEAST32_FMTd__
#define __INT_LEAST32_FMTd__ "d"
#endif /* __INT_LEAST32_FMTd__ */

#ifndef __INT_LEAST32_FMTi__
#define __INT_LEAST32_FMTi__ "i"
#endif /* __INT_LEAST32_FMTi__ */

#ifndef __INT_LEAST32_MAX__
#define __INT_LEAST32_MAX__ 2147483647
#endif /* __INT_LEAST32_MAX__ */

#ifndef __INT_LEAST32_TYPE__
#define __INT_LEAST32_TYPE__ int
#endif /* __INT_LEAST32_TYPE__ */

#ifndef __INT_LEAST64_FMTd__
#define __INT_LEAST64_FMTd__ "ld"
#endif /* __INT_LEAST64_FMTd__ */

#ifndef __INT_LEAST64_FMTi__
#define __INT_LEAST64_FMTi__ "li"
#endif /* __INT_LEAST64_FMTi__ */

#ifndef __INT_LEAST64_MAX__
#define __INT_LEAST64_MAX__ 9223372036854775807L
#endif /* __INT_LEAST64_MAX__ */

#ifndef __INT_LEAST64_TYPE__
#ifdef __PST_64BIT_TARGET__
#define __INT_LEAST64_TYPE__ long int
#else
#define __INT_LEAST64_TYPE__ long long int
#endif
#endif /* __INT_LEAST64_TYPE__ */

#ifndef __INT_LEAST8_FMTd__
#define __INT_LEAST8_FMTd__ "hhd"
#endif /* __INT_LEAST8_FMTd__ */

#ifndef __INT_LEAST8_FMTi__
#define __INT_LEAST8_FMTi__ "hhi"
#endif /* __INT_LEAST8_FMTi__ */

#ifndef __INT_LEAST8_MAX__
#define __INT_LEAST8_MAX__ 127
#endif /* __INT_LEAST8_MAX__ */

#ifndef __INT_LEAST8_TYPE__
#define __INT_LEAST8_TYPE__ signed char
#endif /* __INT_LEAST8_TYPE__ */

#ifndef __INT_MAX__
#define __INT_MAX__ 2147483647
#endif /* __INT_MAX__ */

#ifndef __LDBL_DENORM_MIN__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_DENORM_MIN__ __FLT_DENORM_MIN__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_DENORM_MIN__ __DBL_DENORM_MIN__
#else
#define __LDBL_DENORM_MIN__ 3.64519953188247460253e-4951L
#endif
#endif /* __LDBL_DENORM_MIN__ */

#ifndef __LDBL_DIG__
#define __LDBL_DIG__ 18
#endif /* __LDBL_DIG__ */

#ifndef __LDBL_EPSILON__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_EPSILON__ __FLT_EPSILON__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_EPSILON__ __DBL_EPSILON__
#else
#define __LDBL_EPSILON__ 1.08420217248550443401e-19L
#endif
#endif /* __LDBL_EPSILON__ */

#ifndef __LDBL_HAS_DENORM__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_HAS_DENORM__ __FLT_HAS_DENORM__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_HAS_DENORM__ __DBL_HAS_DENORM__
#else
#define __LDBL_HAS_DENORM__ 1
#endif
#endif

#ifndef __LDBL_HAS_INFINITY__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_HAS_INFINITY__ __FLT_HAS_INFINITY__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_HAS_INFINITY__ __DBL_HAS_INFINITY__
#else
#define __LDBL_HAS_INFINITY__ 1
#endif
#endif /* __LDBL_HAS_INFINITY__ */

#ifndef __LDBL_HAS_QUIET_NAN__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_HAS_QUIET_NAN__ __FLT_HAS_QUIET_NAN__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_HAS_QUIET_NAN__ __DBL_HAS_QUIET_NAN__
#else
#define __LDBL_HAS_QUIET_NAN__ 1
#endif
#endif /* __LDBL_HAS_QUIET_NAN__ */

#ifndef __LDBL_MANT_DIG__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_MANT_DIG__ __FLT_MANT_DIG__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_MANT_DIG__ __DBL_MANT_DIG__
#else
#define __LDBL_MANT_DIG__ 64
#endif
#endif

#ifndef __LDBL_MAX_10_EXP__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_MAX_10_EXP__ __FLT_MAX_10_EXP__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_MAX_10_EXP__ __DBL_MAX_10_EXP__
#else
#define __LDBL_MAX_10_EXP__ 4932
#endif
#endif /* __LDBL_MAX_10_EXP__ */

#ifndef __LDBL_MAX_EXP__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_MAX_EXP__ __FLT_MAX_EXP__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_MAX_EXP__ __DBL_MAX_EXP__
#else
#define __LDBL_MAX_EXP__ 16384
#endif
#endif /* __LDBL_MAX_EXP__ */

#ifndef __LDBL_MAX__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_MAX__ __FLT_MAX__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_MAX__ __DBL_MAX__
#else
#define __LDBL_MAX__ 1.18973149535723176502e+4932L
#endif
#endif /* __LDBL_MAX__ */

#ifndef __LDBL_MIN_10_EXP__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_MIN_10_EXP__ __FLT_MIN_10_EXP__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_MIN_10_EXP__ __DBL_MIN_10_EXP__
#else
#define __LDBL_MIN_10_EXP__ (-4931)
#endif
#endif

#ifndef __LDBL_MIN_EXP__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_MIN_EXP__ __FLT_MIN_EXP__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_MIN_EXP__ __DBL_MIN_EXP__
#else
#define __LDBL_MIN_EXP__ (-16381)
#endif
#endif /* __LDBL_MIN_EXP__ */

#ifndef __LDBL_MIN__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_MIN__ __FLT_MIN__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_MIN__ __DBL_MIN__
#else
#define __LDBL_MIN__ 3.36210314311209350626e-4932L
#endif
#endif /* __LDBL_MIN__ */

#ifndef __LITTLE_ENDIAN__
#define __LITTLE_ENDIAN__ 1
#endif /* __LITTLE_ENDIAN__ */

#ifndef __LONG_LONG_MAX__
#define __LONG_LONG_MAX__ 9223372036854775807LL
#endif /* __LONG_LONG_MAX__ */

#ifndef __LONG_MAX__
#define __LONG_MAX__ 9223372036854775807L
#endif /* __LONG_MAX__ */

#if (__SIZEOF_INT__ == 4 && __SIZEOF_LONG__ == 8 && __SIZEOF_POINTER__ == 8)
#ifndef __LP64__
#define __LP64__ 1
#endif /* __LP64__ */
#ifndef _LP64
#define _LP64 1
#endif /* _LP64 */
#endif

#ifndef __POINTER_WIDTH__
#ifdef __PST_64BIT_TARGET__
#define __POINTER_WIDTH__ 64
#else
#define __POINTER_WIDTH__ 32
#endif
#endif /* __POINTER_WIDTH__ */

#ifndef __PTRDIFF_FMTd__
#define __PTRDIFF_FMTd__ "ld"
#endif /* __PTRDIFF_FMTd__ */

#ifndef __PTRDIFF_FMTi__
#define __PTRDIFF_FMTi__ "li"
#endif /* __PTRDIFF_FMTi__ */

#ifndef __PTRDIFF_MAX__
#define __PTRDIFF_MAX__ 9223372036854775807L
#endif /* __PTRDIFF_MAX__ */

#ifndef __PTRDIFF_TYPE__
#define __PTRDIFF_TYPE__ long int
#endif /* __PTRDIFF_TYPE__ */

#ifndef __PTRDIFF_WIDTH__
#define __PTRDIFF_WIDTH__ 64
#endif /* __PTRDIFF_WIDTH__ */

#ifndef __REGISTER_PREFIX__
#define __REGISTER_PREFIX__
#endif /* __REGISTER_PREFIX__ */

#ifndef __SCHAR_MAX__
#define __SCHAR_MAX__ 127
#endif /* __SCHAR_MAX__ */

#ifndef __SHRT_MAX__
#define __SHRT_MAX__ 32767
#endif /* __SHRT_MAX__ */

#ifndef __SIZEOF_DOUBLE__
#define __SIZEOF_DOUBLE__ 8
#endif /* __SIZEOF_DOUBLE__ */

#ifndef __SIZEOF_FLOAT__
#define __SIZEOF_FLOAT__ 4
#endif /* __SIZEOF_FLOAT__ */

#if (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 4))
#if __SIZEOF_LONG__ >= 8 && defined(__SIZEOF_INT128__)
#define __SIZEOF_INT128__ 16
#endif /* __SIZEOF_INT128__ */
#endif

#ifndef __SIZEOF_INT__
#define __SIZEOF_INT__ 4
#endif /* __SIZEOF_INT__ */

#ifndef __SIZEOF_LONG_DOUBLE__
#ifdef __PST_64BIT_TARGET__
#define __SIZEOF_LONG_DOUBLE__ 16
#else
#define __SIZEOF_LONG_DOUBLE__ 12
#endif
#endif /* __SIZEOF_LONG_DOUBLE__ */

#ifndef __SIZEOF_LONG_LONG__
#define __SIZEOF_LONG_LONG__ 8
#endif /* __SIZEOF_LONG_LONG__ */

#ifndef __SIZEOF_LONG__
#ifdef __PST_64BIT_TARGET__
#define __SIZEOF_LONG__ 8
#else
#define __SIZEOF_LONG__ 4
#endif
#endif /* __SIZEOF_LONG__ */

#ifndef __SIZEOF_POINTER__
#ifdef __PST_64BIT_TARGET__
#define __SIZEOF_POINTER__ 8
#else
#define __SIZEOF_POINTER__ 4
#endif
#endif /* __SIZEOF_POINTER__ */

#ifndef __SIZEOF_PTRDIFF_T__
#ifdef __PST_64BIT_TARGET__
#define __SIZEOF_PTRDIFF_T__ 8
#else
#define __SIZEOF_PTRDIFF_T__ 4
#endif
#endif /* __SIZEOF_PTRDIFF_T__ */

#ifndef __SIZEOF_SHORT__
#define __SIZEOF_SHORT__ 2
#endif /* __SIZEOF_SHORT__ */

#ifndef __SIZEOF_WCHAR_T__
#define __SIZEOF_WCHAR_T__ 4
#endif /* __SIZEOF_WCHAR_T__ */

#ifndef __SIZEOF_WINT_T__
#define __SIZEOF_WINT_T__ 4
#endif /* __SIZEOF_WINT_T__ */

#ifndef __SIZE_FMTX__
#define __SIZE_FMTX__ "lX"
#endif /* __SIZE_FMTX__ */

#ifndef __SIZE_FMTo__
#define __SIZE_FMTo__ "lo"
#endif /* __SIZE_FMTo__ */

#ifndef __SIZE_FMTu__
#define __SIZE_FMTu__ "lu"
#endif /* __SIZE_FMTu__ */

#ifndef __SIZE_FMTx__
#define __SIZE_FMTx__ "lx"
#endif /* __SIZE_FMTx__ */

#ifndef __SIZE_MAX__
#define __SIZE_MAX__ 18446744073709551615UL
#endif /* __SIZE_MAX__ */

#ifndef __SIZE_TYPE__
#define __SIZE_TYPE__ long unsigned int
#endif /* __SIZE_TYPE__ */

#ifndef __SIZE_WIDTH__
#define __SIZE_WIDTH__ 64
#endif /* __SIZE_WIDTH__ */

#ifndef __UINT16_C_SUFFIX__
#define __UINT16_C_SUFFIX__
#endif /* __UINT16_C_SUFFIX__ */

#ifndef __UINT16_FMTX__
#define __UINT16_FMTX__ "hX"
#endif /* __UINT16_FMTX__ */

#ifndef __UINT16_FMTo__
#define __UINT16_FMTo__ "ho"
#endif /* __UINT16_FMTo__ */

#ifndef __UINT16_FMTu__
#define __UINT16_FMTu__ "hu"
#endif /* __UINT16_FMTu__ */

#ifndef __UINT16_FMTx__
#define __UINT16_FMTx__ "hx"
#endif /* __UINT16_FMTx__ */

#ifndef __UINT16_MAX__
#define __UINT16_MAX__ 65535
#endif /* __UINT16_MAX__ */

#ifndef __UINT16_TYPE__
#define __UINT16_TYPE__ unsigned short
#endif /* __UINT16_TYPE__ */

#ifndef __UINT32_C_SUFFIX__
#define __UINT32_C_SUFFIX__ U
#endif /* __UINT32_C_SUFFIX__ */

#ifndef __UINT32_FMTX__
#define __UINT32_FMTX__ "X"
#endif /* __UINT32_FMTX__ */

#ifndef __UINT32_FMTo__
#define __UINT32_FMTo__ "o"
#endif /* __UINT32_FMTo__ */

#ifndef __UINT32_FMTu__
#define __UINT32_FMTu__ "u"
#endif /* __UINT32_FMTu__ */

#ifndef __UINT32_FMTx__
#define __UINT32_FMTx__ "x"
#endif /* __UINT32_FMTx__ */

#ifndef __UINT32_MAX__
#define __UINT32_MAX__ 4294967295U
#endif /* __UINT32_MAX__ */

#ifndef __UINT32_TYPE__
#define __UINT32_TYPE__ unsigned int
#endif /* __UINT32_TYPE__ */

#ifndef __UINT64_C_SUFFIX__
#define __UINT64_C_SUFFIX__ ULL
#endif /* __UINT64_C_SUFFIX__ */

#ifndef __UINT64_FMTX__
#define __UINT64_FMTX__ "llX"
#endif /* __UINT64_FMTX__ */

#ifndef __UINT64_FMTo__
#define __UINT64_FMTo__ "llo"
#endif /* __UINT64_FMTo__ */

#ifndef __UINT64_FMTu__
#define __UINT64_FMTu__ "llu"
#endif /* __UINT64_FMTu__ */

#ifndef __UINT64_FMTx__
#define __UINT64_FMTx__ "llx"
#endif /* __UINT64_FMTx__ */

#ifndef __UINT64_MAX__
#define __UINT64_MAX__ 18446744073709551615ULL
#endif /* __UINT64_MAX__ */

#ifndef __UINT64_TYPE__
#define __UINT64_TYPE__ long long unsigned int
#endif /* __UINT64_TYPE__ */

#ifndef __UINT8_C_SUFFIX__
#define __UINT8_C_SUFFIX__
#endif /* __UINT8_C_SUFFIX__ */

#ifndef __UINT8_FMTX__
#define __UINT8_FMTX__ "hhX"
#endif /* __UINT8_FMTX__ */

#ifndef __UINT8_FMTo__
#define __UINT8_FMTo__ "hho"
#endif /* __UINT8_FMTo__ */

#ifndef __UINT8_FMTu__
#define __UINT8_FMTu__ "hhu"
#endif /* __UINT8_FMTu__ */

#ifndef __UINT8_FMTx__
#define __UINT8_FMTx__ "hhx"
#endif /* __UINT8_FMTx__ */

#ifndef __UINT8_MAX__
#define __UINT8_MAX__ 255
#endif /* __UINT8_MAX__ */

#ifndef __UINT8_TYPE__
#define __UINT8_TYPE__ unsigned char
#endif /* __UINT8_TYPE__ */

#ifndef __UINTMAX_C_SUFFIX__
#define __UINTMAX_C_SUFFIX__ UL
#endif /* __UINTMAX_C_SUFFIX__ */

#ifndef __UINTMAX_FMTX__
#define __UINTMAX_FMTX__ "lX"
#endif /* __UINTMAX_FMTX__ */

#ifndef __UINTMAX_FMTo__
#define __UINTMAX_FMTo__ "lo"
#endif /* __UINTMAX_FMTo__ */

#ifndef __UINTMAX_FMTu__
#define __UINTMAX_FMTu__ "lu"
#endif /* __UINTMAX_FMTu__ */

#ifndef __UINTMAX_FMTx__
#define __UINTMAX_FMTx__ "lx"
#endif /* __UINTMAX_FMTx__ */

#ifndef __UINTMAX_MAX__
#define __UINTMAX_MAX__ 18446744073709551615UL
#endif /* __UINTMAX_MAX__ */

#ifndef __UINTMAX_TYPE__
#ifdef __PST_64BIT_TARGET__
#define __UINTMAX_TYPE__ long unsigned int
#else
#define __UINTMAX_TYPE__ long long unsigned int
#endif
#endif /* __UINTMAX_TYPE__ */

#ifndef __UINTMAX_WIDTH__
#define __UINTMAX_WIDTH__ 64
#endif /* __UINTMAX_WIDTH__ */

#ifndef __UINTPTR_FMTX__
#define __UINTPTR_FMTX__ "lX"
#endif /* __UINTPTR_FMTX__ */

#ifndef __UINTPTR_FMTo__
#define __UINTPTR_FMTo__ "lo"
#endif /* __UINTPTR_FMTo__ */

#ifndef __UINTPTR_FMTu__
#define __UINTPTR_FMTu__ "lu"
#endif /* __UINTPTR_FMTu__ */

#ifndef __UINTPTR_FMTx__
#define __UINTPTR_FMTx__ "lx"
#endif /* __UINTPTR_FMTx__ */

#ifndef __UINTPTR_MAX__
#define __UINTPTR_MAX__ 18446744073709551615UL
#endif /* __UINTPTR_MAX__ */

#ifndef __UINTPTR_TYPE__
#define __UINTPTR_TYPE__ long unsigned int
#endif /* __UINTPTR_TYPE__ */

#ifndef __UINTPTR_WIDTH__
#define __UINTPTR_WIDTH__ 64
#endif /* __UINTPTR_WIDTH__ */

#ifndef __UINT_FAST16_FMTX__
#define __UINT_FAST16_FMTX__ "hX"
#endif /* __UINT_FAST16_FMTX__ */

#ifndef __UINT_FAST16_FMTo__
#define __UINT_FAST16_FMTo__ "ho"
#endif /* __UINT_FAST16_FMTo__ */

#ifndef __UINT_FAST16_FMTu__
#define __UINT_FAST16_FMTu__ "hu"
#endif /* __UINT_FAST16_FMTu__ */

#ifndef __UINT_FAST16_FMTx__
#define __UINT_FAST16_FMTx__ "hx"
#endif /* __UINT_FAST16_FMTx__ */

#ifndef __UINT_FAST16_MAX__
#define __UINT_FAST16_MAX__ 65535
#endif /* __UINT_FAST16_MAX__ */

#ifndef __UINT_FAST16_TYPE__
#define __UINT_FAST16_TYPE__ unsigned short
#endif /* __UINT_FAST16_TYPE__ */

#ifndef __UINT_FAST32_FMTX__
#define __UINT_FAST32_FMTX__ "X"
#endif /* __UINT_FAST32_FMTX__ */

#ifndef __UINT_FAST32_FMTo__
#define __UINT_FAST32_FMTo__ "o"
#endif /* __UINT_FAST32_FMTo__ */

#ifndef __UINT_FAST32_FMTu__
#define __UINT_FAST32_FMTu__ "u"
#endif /* __UINT_FAST32_FMTu__ */

#ifndef __UINT_FAST32_FMTx__
#define __UINT_FAST32_FMTx__ "x"
#endif /* __UINT_FAST32_FMTx__ */

#ifndef __UINT_FAST32_MAX__
#define __UINT_FAST32_MAX__ 4294967295U
#endif /* __UINT_FAST32_MAX__ */

#ifndef __UINT_FAST32_TYPE__
#define __UINT_FAST32_TYPE__ unsigned int
#endif /* __UINT_FAST32_TYPE__ */

#ifndef __UINT_FAST64_FMTX__
#define __UINT_FAST64_FMTX__ "lX"
#endif /* __UINT_FAST64_FMTX__ */

#ifndef __UINT_FAST64_FMTo__
#define __UINT_FAST64_FMTo__ "lo"
#endif /* __UINT_FAST64_FMTo__ */

#ifndef __UINT_FAST64_FMTu__
#define __UINT_FAST64_FMTu__ "lu"
#endif /* __UINT_FAST64_FMTu__ */

#ifndef __UINT_FAST64_FMTx__
#define __UINT_FAST64_FMTx__ "lx"
#endif /* __UINT_FAST64_FMTx__ */

#ifndef __UINT_FAST64_MAX__
#define __UINT_FAST64_MAX__ 18446744073709551615UL
#endif /* __UINT_FAST64_MAX__ */

#ifndef __UINT_FAST64_TYPE__
#ifdef __PST_64BIT_TARGET__
#define __UINT_FAST64_TYPE__ long unsigned int
#else
#define __UINT_FAST64_TYPE__ long long unsigned int
#endif
#endif /* __UINT_FAST64_TYPE__ */

#ifndef __UINT_FAST8_FMTX__
#define __UINT_FAST8_FMTX__ "hhX"
#endif /* __UINT_FAST8_FMTX__ */

#ifndef __UINT_FAST8_FMTo__
#define __UINT_FAST8_FMTo__ "hho"
#endif /* __UINT_FAST8_FMTo__ */

#ifndef __UINT_FAST8_FMTu__
#define __UINT_FAST8_FMTu__ "hhu"
#endif /* __UINT_FAST8_FMTu__ */

#ifndef __UINT_FAST8_FMTx__
#define __UINT_FAST8_FMTx__ "hhx"
#endif /* __UINT_FAST8_FMTx__ */

#ifndef __UINT_FAST8_MAX__
#define __UINT_FAST8_MAX__ 255
#endif /* __UINT_FAST8_MAX__ */

#ifndef __UINT_FAST8_TYPE__
#define __UINT_FAST8_TYPE__ unsigned char
#endif /* __UINT_FAST8_TYPE__ */

#ifndef __UINT_LEAST16_FMTX__
#define __UINT_LEAST16_FMTX__ "hX"
#endif /* __UINT_LEAST16_FMTX__ */

#ifndef __UINT_LEAST16_FMTo__
#define __UINT_LEAST16_FMTo__ "ho"
#endif /* __UINT_LEAST16_FMTo__ */

#ifndef __UINT_LEAST16_FMTu__
#define __UINT_LEAST16_FMTu__ "hu"
#endif /* __UINT_LEAST16_FMTu__ */

#ifndef __UINT_LEAST16_FMTx__
#define __UINT_LEAST16_FMTx__ "hx"
#endif /* __UINT_LEAST16_FMTx__ */

#ifndef __UINT_LEAST16_MAX__
#define __UINT_LEAST16_MAX__ 65535
#endif /* __UINT_LEAST16_MAX__ */

#ifndef __UINT_LEAST16_TYPE__
#define __UINT_LEAST16_TYPE__ unsigned short
#endif /* __UINT_LEAST16_TYPE__ */

#ifndef __UINT_LEAST32_FMTX__
#define __UINT_LEAST32_FMTX__ "X"
#endif /* __UINT_LEAST32_FMTX__ */

#ifndef __UINT_LEAST32_FMTo__
#define __UINT_LEAST32_FMTo__ "o"
#endif /* __UINT_LEAST32_FMTo__ */

#ifndef __UINT_LEAST32_FMTu__
#define __UINT_LEAST32_FMTu__ "u"
#endif /* __UINT_LEAST32_FMTu__ */

#ifndef __UINT_LEAST32_FMTx__
#define __UINT_LEAST32_FMTx__ "x"
#endif /* __UINT_LEAST32_FMTx__ */

#ifndef __UINT_LEAST32_MAX__
#define __UINT_LEAST32_MAX__ 4294967295U
#endif /* __UINT_LEAST32_MAX__ */

#ifndef __UINT_LEAST32_TYPE__
#define __UINT_LEAST32_TYPE__ unsigned int
#endif /* __UINT_LEAST32_TYPE__ */

#ifndef __UINT_LEAST64_FMTX__
#define __UINT_LEAST64_FMTX__ "lX"
#endif /* __UINT_LEAST64_FMTX__ */

#ifndef __UINT_LEAST64_FMTo__
#define __UINT_LEAST64_FMTo__ "lo"
#endif /* __UINT_LEAST64_FMTo__ */

#ifndef __UINT_LEAST64_FMTu__
#define __UINT_LEAST64_FMTu__ "lu"
#endif /* __UINT_LEAST64_FMTu__ */

#ifndef __UINT_LEAST64_FMTx__
#define __UINT_LEAST64_FMTx__ "lx"
#endif /* __UINT_LEAST64_FMTx__ */

#ifndef __UINT_LEAST64_MAX__
#define __UINT_LEAST64_MAX__ 18446744073709551615UL
#endif /* __UINT_LEAST64_MAX__ */

#ifndef __UINT_LEAST64_TYPE__
#ifdef __PST_64BIT_TARGET__
#define __UINT_LEAST64_TYPE__ long unsigned int
#else
#define __UINT_LEAST64_TYPE__ long long unsigned int
#endif
#endif /* __UINT_LEAST64_TYPE__ */

#ifndef __UINT_LEAST8_FMTX__
#define __UINT_LEAST8_FMTX__ "hhX"
#endif /* __UINT_LEAST8_FMTX__ */

#ifndef __UINT_LEAST8_FMTo__
#define __UINT_LEAST8_FMTo__ "hho"
#endif /* __UINT_LEAST8_FMTo__ */

#ifndef __UINT_LEAST8_FMTu__
#define __UINT_LEAST8_FMTu__ "hhu"
#endif /* __UINT_LEAST8_FMTu__ */

#ifndef __UINT_LEAST8_FMTx__
#define __UINT_LEAST8_FMTx__ "hhx"
#endif /* __UINT_LEAST8_FMTx__ */

#ifndef __UINT_LEAST8_MAX__
#define __UINT_LEAST8_MAX__ 255
#endif /* __UINT_LEAST8_MAX__ */

#ifndef __UINT_LEAST8_TYPE__
#define __UINT_LEAST8_TYPE__ unsigned char
#endif /* __UINT_LEAST8_TYPE__ */

#ifndef __WCHAR_MAX__
#define __WCHAR_MAX__ 2147483647
#endif /* __WCHAR_MAX__ */

#ifndef __WCHAR_TYPE__
#define __WCHAR_TYPE__ int
#endif /* __WCHAR_TYPE__ */

#ifndef __WCHAR_WIDTH__
#define __WCHAR_WIDTH__ 32
#endif /* __WCHAR_WIDTH__ */

#ifndef __WINT_TYPE__
#define __WINT_TYPE__ int
#endif /* __WINT_TYPE__ */

#ifndef __WINT_WIDTH__
#define __WINT_WIDTH__ 32
#endif /* __WINT_WIDTH__ */


/*
 * Endianness macros
 */
#if !defined(__ORDER_LITTLE_ENDIAN__) && !defined(__ORDER_BIG_ENDIAN__)
  && !defined(__ORDER_PDP_ENDIAN__) && !defined(__BYTE_ORDER__) && !defined(__FLOAT_WORD_ORDER__)
#define __ORDER_LITTLE_ENDIAN__ 1234
#define __ORDER_BIG_ENDIAN__ 4321
#define __ORDER_PDP_ENDIAN__ 3412
#define __BYTE_ORDER__ __ORDER_LITTLE_ENDIAN__
#define __FLOAT_WORD_ORDER__ __ORDER_LITTLE_ENDIAN__
#endif


/*
 * Atomic-related macros
 */

#if !defined(__ATOMIC_RELAXED) && !defined(__ATOMIC_CONSUME) && !defined(__ATOMIC_ACQUIRE) \
  && !defined(__ATOMIC_RELEASE) && !defined(__ATOMIC_ACQ_REL) && !defined(__ATOMIC_SEQ_CST) \
  && !defined(__GCC_ATOMIC_TEST_AND_SET_TRUEVAL) && !defined(__GCC_ATOMIC_BOOL_LOCK_FREE) \
  && !defined(__GCC_ATOMIC_CHAR_LOCK_FREE) && !defined(__GCC_ATOMIC_SHORT_LOCK_FREE) \
  && !defined(__GCC_ATOMIC_INT_LOCK_FREE) && !defined(__GCC_ATOMIC_LONG_LOCK_FREE) \
  && !defined(__GCC_ATOMIC_LLONG_LOCK_FREE) && !defined(__GCC_ATOMIC_CHAR16_T_LOCK_FREE) \
  && !defined(__GCC_ATOMIC_CHAR32_T_LOCK_FREE) && !defined(__GCC_ATOMIC_WCHAR_T_LOCK_FREE) \
  && !defined(__GCC_ATOMIC_POINTER_LOCK_FREE) && !defined(__SIG_ATOMIC_MAX__) \
  && !defined(__SIG_ATOMIC_WIDTH__)
#define __ATOMIC_RELAXED 0
#define __ATOMIC_CONSUME 1
#define __ATOMIC_ACQUIRE 2
#define __ATOMIC_RELEASE 3
#define __ATOMIC_ACQ_REL 4
#define __ATOMIC_SEQ_CST 5
#define __GCC_ATOMIC_TEST_AND_SET_TRUEVAL 1
#define __GCC_ATOMIC_BOOL_LOCK_FREE 2
#define __GCC_ATOMIC_CHAR_LOCK_FREE 2
#define __GCC_ATOMIC_SHORT_LOCK_FREE 2
#define __GCC_ATOMIC_INT_LOCK_FREE 2
#define __GCC_ATOMIC_LONG_LOCK_FREE 2
#define __GCC_ATOMIC_LLONG_LOCK_FREE 2
#define __GCC_ATOMIC_CHAR16_T_LOCK_FREE 2
#define __GCC_ATOMIC_CHAR32_T_LOCK_FREE 2
#define __GCC_ATOMIC_WCHAR_T_LOCK_FREE 2
#define __GCC_ATOMIC_POINTER_LOCK_FREE 2
#define __SIG_ATOMIC_MAX__  0x7fffffff
#define __SIG_ATOMIC_WIDTH__ 32
#endif

#include "../tmw_builtins/tmw_builtins.h"

#endif /* __POLYSPACE__CLANG_H */

/* LocalWords:  endian
 */
