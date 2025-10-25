/* Copyright 2016-2024 The MathWorks, Inc. */

/* Used with GCC compiler only */

#ifndef __POLYSPACE__GCC_H
#define __POLYSPACE__GCC_H

/*
 * GNU Compiler macros
 */
#ifndef __GNUC__
#define __GNUC__ 5
#endif /* __GNUC__ */

#ifndef __GNUC_MINOR__
#define __GNUC_MINOR__ 1
#endif /* __GNUC_MINOR__ */

#ifndef __GNUC_PATCHLEVEL__
#define __GNUC_PATCHLEVEL__ 0
#endif /* __GNUC_PATCHLEVEL__ */

#ifndef __GXX_ABI_VERSION
#define __GXX_ABI_VERSION 1008
#endif /* __GXX_ABI_VERSION */

#ifndef __VERSION__
#define __VERSION__ "5.1.0"
#endif /* __VERSION__ */

#if (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 4))
#if __SIZEOF_LONG__ >= 8 && defined(__SIZEOF_INT128__)
#ifndef __GLIBCXX_TYPE_INT_N_0
#define __GLIBCXX_TYPE_INT_N_0 __int128
#endif /* __GLIBCXX_TYPE_INT_N_0 */
#endif
#endif

#if (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 4)) && __SIZEOF_LONG__ >= 8 && !defined(__SIZEOF_INT128__)
#define __SIZEOF_INT128__ 16
#endif /* __SIZEOF_INT128__ */

#if (__GNUC__ > 6 ) && !defined __cplusplus
#define _Float32 float
#define _Float64 double
#define _Float128 long double
#define _Float32x float
#define _Float64x double
#define _Float128x long double
#endif

#if (__SIZEOF_INT__ == 4 && __SIZEOF_LONG__ == 8 && __SIZEOF_POINTER__ == 8)
#ifndef __LP64__
#define __LP64__ 1
#endif /* __LP64__ */
#ifndef _LP64
#define _LP64 1
#endif /* _LP64 */
#endif

/* Disable use of SIMD intrinsics by "boost/uuid/uuid.hpp" in Code Prover */
#if !defined(PST_ALLOW_BOOST_UUID_SIMD) && !defined(PST_BUG_FINDER) && (!defined(__GNUC__) || (__GNUC__ >= 5))
#define BOOST_UUID_NO_SIMD
#endif /* PST_ALLOW_BOOST_UUID_SIMD */


/*
 * Macros to mimic cygwin and mingw gcc flavors.
 */
#ifndef PST_GCC_WITHOUT_MICROSOFT_KEYWORDS
#ifndef __declspec
#define __declspec(X) __attribute__((X))
#endif
#ifndef _fastcall
#define _fastcall __attribute__((fastcall))
#endif
#ifndef __fastcall
#define __fastcall __attribute__((fastcall))
#endif
#ifndef _thiscall
#define _thiscall __attribute__((thiscall))
#endif
#ifndef __thiscall
#define __thiscall __attribute__((thiscall))
#endif
#ifndef _cdecl
#define _cdecl __attribute__((cdecl))
#endif
#ifndef __cdecl
#define __cdecl __attribute__((cdecl))
#endif
#ifndef _stdcall
#define _stdcall __attribute__((stdcall))
#endif
#ifndef __stdcall
#define __stdcall __attribute__((stdcall))
#endif
#endif /* PST_GCC_WITHOUT_MICROSOFT_KEYWORDS */


/*
 * Microchip XC16 Compiler Macros
 */
#if defined __XC16__ || defined XC16
#define __eds__
#define __external__
#define __pack_upper_byte
#define __pmp__
#define __prog__
#define __psv__
#endif /* __XC16__ */


/*
 * Microchip XC32 PIC32 Compiler Macros and predefined intrinsics
 */
#if defined __GNUC__ && defined __XC32 && defined __mips__
#undef __EDG__
#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */
unsigned int __builtin_mfc0(unsigned int, unsigned int);
void __builtin_mtc0(unsigned int, unsigned int, unsigned int);
unsigned int __builtin_bcc0(unsigned int, unsigned int, unsigned int);
unsigned int __builtin_mxc0(unsigned int, unsigned int, unsigned int);
unsigned int __builtin_bsc0(unsigned int, unsigned int, unsigned int);
unsigned int __builtin_bcsc0(unsigned int, unsigned int, unsigned int, unsigned int);
int __builtin_clz(unsigned int);
int __builtin_ctz(unsigned int);
#ifdef __cplusplus
}
#endif /* __cplusplus */
#endif /* __GNUC__ && __XC32 */


/*
 * Target-dependent macros internally defined by Polyspace.
 * The following macro definitions are useful only if the internal values have
 * been manually undefined by the user.
 */

#ifndef __CHAR_BIT__
#define __CHAR_BIT__ 8
#endif /* __CHAR_BIT__ */

#ifndef __SIZEOF_SHORT__
#define __SIZEOF_SHORT__ 2
#endif /* __SIZEOF_SHORT__ */

/* Number of bytes of the C data types */
#ifndef __SIZEOF_INT__
#define __SIZEOF_INT__ 4
#endif /* __SIZEOF_INT__ */

#ifndef __INT_MAX__
#define __INT_MAX__ 0x7fffffff
#endif /* __INT_MAX__ */

#ifndef __SIZEOF_LONG__
#define __SIZEOF_LONG__ 4
#endif /* __SIZEOF_LONG__ */

#ifndef __SIZEOF_LONG_LONG__
#define __SIZEOF_LONG_LONG__ 8
#endif /* __SIZEOF_LONG_LONG__ */

#ifndef __SIZEOF_POINTER__
#define __SIZEOF_POINTER__ 8
#endif /* __SIZEOF_POINTER__ */

#ifndef __SIZEOF_SIZE_T__
#define __SIZEOF_SIZE_T__ 8
#endif /* __SIZEOF_SIZE_T__ */

#ifndef __SIZEOF_WCHAR_T__
#define __SIZEOF_WCHAR_T__ 4
#endif /* __SIZEOF_WCHAR_T__ */

#ifndef __SIZEOF_WINT_T__
#define __SIZEOF_WINT_T__ 4
#endif /* __SIZEOF_WINT_T__ */

#ifndef __SIZEOF_PTRDIFF_T__
#define __SIZEOF_PTRDIFF_T__ sizeof(__EDG_PTRDIFF_TYPE__) //TODO
#endif /* __SIZEOF_PTRDIFF_T__ */

#ifndef __SIZE_MAX__
#define __SIZE_MAX__ 0xffffffffffffffffUL //TODO __SIZEOF_SIZE_T__?
#endif /* __SIZE_MAX__ */

#ifndef __INTMAX_TYPE__
#ifdef __PST_64BIT_TARGET__
#define __INTMAX_TYPE__ long int
#else
#define __INTMAX_TYPE__ long long int
#endif
#endif /* __INTMAX_TYPE__ */

#ifndef __INTMAX_MAX__
#define __INTMAX_MAX__ 0x7fffffffffffffffL //TODO
#endif /* __INTMAX_MAX__ */

#ifndef __UINTMAX_TYPE__
#ifdef __PST_64BIT_TARGET__
#define __UINTMAX_TYPE__ long unsigned int
#else
#define __UINTMAX_TYPE__ long long unsigned int
#endif
#endif /* __UINTMAX_TYPE__ */

#ifndef __UINTMAX_MAX__ //TODO
#define __UINTMAX_MAX__ 0xffffffffffffffffUL
#endif /* __UINTMAX_MAX__ */

// Not defined as it sometimes does not exist on GCC.
//#ifndef __CHAR16_TYPE__
//#define __CHAR16_TYPE__ short unsigned int
//#endif /* __CHAR16_TYPE__ */

#ifndef __WINT_TYPE__
#define __WINT_TYPE__ unsigned int
#endif /* __WINT_TYPE__ */

#ifndef __WINT_MIN__
#define __WINT_MIN__ 0U
#endif /* __WINT_MIN__ */

#ifndef __WINT_MAX__
#define __WINT_MAX__ 0xffffffffU
#endif /* __WINT_MAX__ */

#ifndef __WCHAR_TYPE__
#define __WCHAR_TYPE__ int
#endif /* __WCHAR_TYPE__ */

#ifndef __WCHAR_MIN__
#define __WCHAR_MIN__ (-__WCHAR_MAX__ - 1)
#endif /* __WCHAR_MIN__ */

#ifndef __WCHAR_MAX__
#define __WCHAR_MAX__ 0x7fffffff
#endif /* __WCHAR_MAX__ */

// Not defined as it sometimes does not exist on GCC.
//#ifndef __CHAR32_TYPE__
//#define __CHAR32_TYPE__ __UINT32_TYPE__
//#endif /* __CHAR32_TYPE__ */

#ifndef __INTPTR_TYPE__
#define __INTPTR_TYPE__ __EDG_PTRDIFF_TYPE__
#endif /* __INTPTR_TYPE__ */

#ifndef __UINTPTR_TYPE__
#define __UINTPTR_TYPE__ unsigned __EDG_PTRDIFF_TYPE__
#endif /* __UINTPTR_TYPE__ */

#ifndef __UINTPTR_MAX__
#define __UINTPTR_MAX__ 0xffffffffffffffffUL
#endif /* __UINTPTR_MAX__ */

#ifndef __PTRDIFF_TYPE__
#define __PTRDIFF_TYPE__ __EDG_PTRDIFF_TYPE__
#endif /* __PTRDIFF_TYPE__ */

#ifndef __INTPTR_MAX__
#define __INTPTR_MAX__ 0x7fffffffffffffffL
#endif /* __INTPTR_MAX__ */

// __LONG_MAX__ prefed'ed by Polyspace
//#ifndef __LONG_MAX__
//#define __LONG_MAX__ 0x7fffffffffffffffL
//#endif /* __LONG_MAX__ */

#ifndef __SIZE_TYPE__
#define __SIZE_TYPE__ long unsigned int
#endif /* __SIZE_TYPE__ */

#ifndef __PTRDIFF_MAX__
#define __PTRDIFF_MAX__ 0x7fffffffffffffffL
#endif /* __PTRDIFF_MAX__ */

#ifndef __LONG_LONG_MAX__
#define __LONG_LONG_MAX__ 0x7fffffffffffffffLL
#endif /* __LONG_LONG_MAX__ */

#ifndef __SHRT_MAX__
#define __SHRT_MAX__ 0x7fff
#endif /* __SHRT_MAX__ */

#ifndef __SCHAR_MAX__
#define __SCHAR_MAX__ 0x7f
#endif /* __SCHAR_MAX__ */


/*
 * For stdint.h/limits.h
 */

#ifndef __INT8_TYPE__
#define __INT8_TYPE__ signed char
#endif /* __INT8_TYPE__ */

#ifndef __INT8_MAX__
#define __INT8_MAX__ 0x7f
#endif /* __INT8_MAX__ */

#ifndef __INT_FAST8_TYPE__
#define __INT_FAST8_TYPE__ signed char
#endif /* __INT_FAST8_TYPE__ */

#ifndef __INT_FAST8_MAX__
#define __INT_FAST8_MAX__ 0x7f
#endif /* __INT_FAST8_MAX__ */

#ifndef __INT_LEAST8_TYPE__
#define __INT_LEAST8_TYPE__ signed char
#endif /* __INT_LEAST8_TYPE__ */

#ifndef __INT_LEAST8_MAX__
#define __INT_LEAST8_MAX__ 0x7f
#endif /* __INT_LEAST8_MAX__ */

#ifndef __UINT8_TYPE__
#define __UINT8_TYPE__ unsigned char
#endif /* __UINT8_TYPE__ */

#ifndef __UINT8_MAX__
#define __UINT8_MAX__ 0xff
#endif /* __UINT8_MAX__ */

#ifndef __UINT_FAST8_TYPE__
#define __UINT_FAST8_TYPE__ unsigned char
#endif /* __UINT_FAST8_TYPE__ */

#ifndef __UINT_FAST8_MAX__
#define __UINT_FAST8_MAX__ 0xff
#endif /* __UINT_FAST8_MAX__ */

#ifndef __UINT_LEAST8_TYPE__
#define __UINT_LEAST8_TYPE__ unsigned char
#endif /* __UINT_LEAST8_TYPE__ */

#ifndef __UINT_LEAST8_MAX__
#define __UINT_LEAST8_MAX__ 0xff
#endif /* __UINT_LEAST8_MAX__ */

#ifndef __INT16_TYPE__
#define __INT16_TYPE__ short int
#endif /* __INT16_TYPE__ */

#ifndef __INT16_MAX__
#define __INT16_MAX__ 0x7fff
#endif /* __INT16_MAX__ */

#ifndef __INT_FAST16_TYPE__
#ifdef __PST_64BIT_TARGET__
#define __INT_FAST16_TYPE__ long int
#else
#define __INT_FAST16_TYPE__ int
#endif
#endif /* __INT_FAST16_TYPE__ */

#ifndef __INT_FAST16_MAX__
#ifdef __PST_64BIT_TARGET__
#define __INT_FAST16_MAX__ 0x7fffffffffffffffL
#else
#define __INT_FAST16_MAX__ __INT32_MAX__
#endif
#endif /* __INT_FAST16_MAX__ */

#ifndef __INT_LEAST16_TYPE__
#define __INT_LEAST16_TYPE__ short int
#endif /* __INT_LEAST16_TYPE__ */

#ifndef __INT_LEAST16_MAX__
#define __INT_LEAST16_MAX__ 0x7fff
#endif /* __INT_LEAST16_MAX__ */

#ifndef __UINT16_TYPE__
#define __UINT16_TYPE__ short unsigned int
#endif /* __UINT16_TYPE__ */

#ifndef __UINT16_MAX__
#define __UINT16_MAX__ 0xffff
#endif /* __UINT16_MAX__ */

#ifndef __UINT_FAST16_TYPE__
#ifdef __PST_64BIT_TARGET__
#define __UINT_FAST16_TYPE__ long unsigned int
#else
#define __UINT_FAST16_TYPE__ unsigned int
#endif
#endif /* __UINT_FAST16_TYPE__ */

#ifndef __UINT_FAST16_MAX__
#ifdef __PST_64BIT_TARGET__
#define __UINT_FAST16_MAX__ 0xffffffffffffffffUL
#else
#define __UINT_FAST16_MAX__ __UINT32_MAX__
#endif
#endif /* __UINT_FAST16_MAX__ */

#ifndef __UINT_LEAST16_TYPE__
#define __UINT_LEAST16_TYPE__ short unsigned int
#endif /* __UINT_LEAST16_TYPE__ */

#ifndef __UINT_LEAST16_MAX__
#define __UINT_LEAST16_MAX__ 0xffff
#endif /* __UINT_LEAST16_MAX__ */

#ifndef __INT32_TYPE__
#define __INT32_TYPE__ __PST_INT32_TYPE__
#endif /* __INT32_TYPE__ */

#ifndef __INT32_MAX__
#define __INT32_MAX__ 0x7fffffff
#endif /* __INT32_MAX__ */

#ifndef __INT_FAST32_TYPE__
#ifdef __PST_64BIT_TARGET__
#define __INT_FAST32_TYPE__ long int
#else
#define __INT_FAST32_TYPE__ __INT32_TYPE__
#endif
#endif /* __INT_FAST32_TYPE__ */

#ifndef __INT_FAST32_MAX__
#ifdef __PST_64BIT_TARGET__
#define __INT_FAST32_MAX__ 0x7fffffffffffffffL
#else
#define __INT_FAST32_MAX__ __INT32_MAX__
#endif
#endif /* __INT_FAST32_MAX__ */

#ifndef __INT_LEAST32_TYPE__
#define __INT_LEAST32_TYPE__ __INT32_TYPE__
#endif /* __INT_LEAST32_TYPE__ */

#ifndef __INT_LEAST32_MAX__
#define __INT_LEAST32_MAX__ 0x7fffffff /* __INT32_MAX__ */
#endif /* __INT_LEAST32_MAX__ */


#ifndef __UINT32_TYPE__
#define __UINT32_TYPE__ unsigned int //TODO
#endif /* __UINT32_TYPE__ */

#ifndef __UINT32_MAX__
#define __UINT32_MAX__ 0xffffffffU
#endif /* __UINT32_MAX__ */

#ifndef __UINT_FAST32_TYPE__
#ifdef __PST_64BIT_TARGET__
#define __UINT_FAST32_TYPE__ long unsigned int
#else
#define __UINT_FAST32_TYPE__ unsigned int
#endif
#endif /* __UINT_FAST32_TYPE__ */

#ifndef __UINT_FAST32_MAX__
#ifdef __PST_64BIT_TARGET__
#define __UINT_FAST32_MAX__ 0xffffffffffffffffUL
#else
#define __UINT_FAST32_MAX__ __UINT32_MAX__
#endif
#endif /* __UINT_FAST32_MAX__ */

#ifndef __UINT_LEAST32_TYPE__
#define __UINT_LEAST32_TYPE__ __UINT32_TYPE__
#endif /* __UINT_LEAST32_TYPE__ */

#ifndef __UINT_LEAST32_MAX__
#define __UINT_LEAST32_MAX__ 0xffffffffU
#endif /* __UINT_LEAST32_MAX__ */

#ifndef __INT64_TYPE__
#ifdef __PST_64BIT_TARGET__
#define __INT64_TYPE__ long int
#else
#define __INT64_TYPE__ long long int
#endif
#endif /* __INT64_TYPE__ */

#ifndef __INT64_MAX__
#ifdef __PST_64BIT_TARGET__
#define __INT64_MAX__ 0x7fffffffffffffffL
#else
#define __INT64_MAX__ 0x7fffffffffffffffLL
#endif
#endif /* __INT64_MAX__ */

#ifndef __INT_FAST64_TYPE__
#ifdef __PST_64BIT_TARGET__
#define __INT_FAST64_TYPE__ long int
#else
#define __INT_FAST64_TYPE__ long long int
#endif
#endif /* __INT_FAST64_TYPE__ */

#ifndef __INT_FAST64_MAX__
#define __INT_FAST64_MAX__ 0x7fffffffffffffffL
#endif /* __INT_FAST64_MAX__ */

#ifndef __INT_LEAST64_TYPE__
#ifdef __PST_64BIT_TARGET__
#define __INT_LEAST64_TYPE__ long int
#else
#define __INT_LEAST64_TYPE__ long long int
#endif
#endif /* __INT_LEAST64_TYPE__ */

#ifndef __INT_LEAST64_MAX__
#define __INT_LEAST64_MAX__ 0x7fffffffffffffffL
#endif /* __INT_LEAST64_MAX__ */

#ifndef __UINT64_TYPE__
#ifdef __PST_64BIT_TARGET__
#define __UINT64_TYPE__ long unsigned int
#else
#define __UINT64_TYPE__ long long unsigned int
#endif
#endif /* __UINT64_TYPE__ */

#ifndef __UINT64_MAX__
#ifdef __PST_64BIT_TARGET__
#define __UINT64_MAX__ 0xffffffffffffffffUL
#else
#define __UINT64_MAX__ 0xffffffffffffffffULL
#endif
#endif /* __UINT64_MAX__ */

#ifndef __UINT_FAST64_TYPE__
#ifdef __PST_64BIT_TARGET__
#define __UINT_FAST64_TYPE__ long unsigned int
#else
#define __UINT_FAST64_TYPE__ long long unsigned int
#endif
#endif /* __UINT_FAST64_TYPE__ */

#ifndef __UINT_FAST64_MAX__
#define __UINT_FAST64_MAX__ 0xffffffffffffffffUL
#endif /* __UINT_FAST64_MAX__ */

#ifndef __UINT_LEAST64_TYPE__
#ifdef __PST_64BIT_TARGET__
#define __UINT_LEAST64_TYPE__ long unsigned int
#else
#define __UINT_LEAST64_TYPE__ long long unsigned int
#endif
#endif /* __UINT_LEAST64_TYPE__ */

#ifndef __UINT_LEAST64_MAX__
#define __UINT_LEAST64_MAX__ 0xffffffffffffffffUL
#endif /* __UINT_LEAST64_MAX__ */


#ifndef __INT8_C
#define __INT8_C(c) c
#endif /* __INT8_C */

#ifndef __UINT8_C
#define __UINT8_C(c) c
#endif /* __UINT8_C */

#ifndef __INT16_C
#define __INT16_C(c) c
#endif /* __INT16_C */

#ifndef __UINT16_C
#define __UINT16_C(c) c
#endif /* __UINT16_C */

#ifndef __INT32_C
#ifdef __PST_16BIT_TARGET__
#define __INT32_C(c) c ## L
#else
#define __INT32_C(c) c
#endif
#endif /* __INT32_C */

#ifndef __UINT32_C
#ifdef __PST_16BIT_TARGET__
#define __UINT32_C(c) c ## UL
#else
#define __UINT32_C(c) c ## U
#endif
#endif /* __UINT32_C */

#ifndef __INT64_C
#ifdef __PST_64BIT_TARGET__
#define __INT64_C(c) c ## L
#else
#define __INT64_C(c) c ## LL
#endif
#endif /* __INT64_C */

#ifndef __UINT64_C
#ifdef __PST_64BIT_TARGET__
#define __UINT64_C(c) c ## UL
#else
#define __UINT64_C(c) c ## ULL
#endif
#endif /* __UINT64_C */

#ifndef __INTMAX_C
#ifdef __PST_64BIT_TARGET__
#define __INTMAX_C(c) c ## L
#else
#define __INTMAX_C(c) c ## LL
#endif
#endif /* __INTMAX_C */

#ifndef __UINTMAX_C
#ifdef __PST_64BIT_TARGET__
#define __UINTMAX_C(c) c ## UL
#else
#define __UINTMAX_C(c) c ## ULL
#endif
#endif /* __UINTMAX_C */


/*
 * Floating-point-related macros.
 */

#ifndef __SIZEOF_FLOAT__
#define __SIZEOF_FLOAT__ 4
#endif /* __SIZEOF_FLOAT__ */

#ifndef __FLT_DIG__
#define __FLT_DIG__ 6
#endif /* __FLT_DIG__ */

#ifndef __FLT_MIN__
#define __FLT_MIN__ 1.17549435082228750797e-38F
#endif /* __FLT_MIN__ */

#ifndef __FLT_MAX__
#define __FLT_MAX__ 3.40282346638528859812e+38F
#endif /* __FLT_MAX__ */

#ifndef __FLT_DENORM_MIN__
#define __FLT_DENORM_MIN__ 1.40129846432481707092e-45F
#endif /* __FLT_DENORM_MIN__ */

#ifndef __FLT_MIN_EXP__
#define __FLT_MIN_EXP__ (-125)
#endif /* __FLT_MIN_EXP__ */

#ifndef __FLT_MIN_10_EXP__
#define __FLT_MIN_10_EXP__ (-37)
#endif /* __FLT_MIN_10_EXP__ */

#ifndef __FLT_MAX_10_EXP__
#define __FLT_MAX_10_EXP__ 38
#endif /* __FLT_MAX_10_EXP__ */

#ifndef __FLT_MANT_DIG__
#define __FLT_MANT_DIG__ 24
#endif /* __FLT_MANT_DIG__ */

#ifndef __FLT_RADIX__
#define __FLT_RADIX__ 2
#endif /* __FLT_RADIX__ */

#ifndef __FLT_HAS_QUIET_NAN__
#define __FLT_HAS_QUIET_NAN__ 1
#endif /* __FLT_HAS_QUIET_NAN__ */

#ifndef __FLT_EPSILON__
#define __FLT_EPSILON__ 1.19209289550781250000e-7F
#endif /* __FLT_EPSILON__ */

#ifndef __FLT_HAS_DENORM__
#define __FLT_HAS_DENORM__ 1
#endif /* __FLT_HAS_DENORM__ */

#ifndef __FLT_EVAL_METHOD__
#ifdef __PST_64BIT_TARGET__
#define __FLT_EVAL_METHOD__ 0
#else
#define __FLT_EVAL_METHOD__ 2
#endif
#endif /* __FLT_EVAL_METHOD__ */

#ifndef __FLT_DECIMAL_DIG__
#define __FLT_DECIMAL_DIG__ 9
#endif /* __FLT_DECIMAL_DIG__ */

#ifndef __FLT_MAX_EXP__
#define __FLT_MAX_EXP__ 128
#endif /* __FLT_MAX_EXP__ */

#ifndef __FLT_HAS_INFINITY__
#define __FLT_HAS_INFINITY__ 1
#endif /* __FLT_HAS_INFINITY__ */

#ifndef __SIZEOF_DOUBLE__
#define __SIZEOF_DOUBLE__ 8
#endif /* __SIZEOF_DOUBLE__ */

#ifndef __DBL_DIG__
#define __DBL_DIG__ 15
#endif /* __DBL_DIG__ */

#ifndef __DBL_MIN__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_MIN__ __FLT_MIN__
#else
#define __DBL_MIN__ 2.22507385850720138309e-308
#endif
#endif /* __DBL_MIN__ */

#ifndef __DBL_MAX__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_MAX__ __FLT_MAX__
#else
#define __DBL_MAX__ 1.79769313486231570815e+308
#endif
#endif /* __DBL_MAX__ */

#ifndef __DBL_DENORM_MIN__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_DENORM_MIN__ __FLT_DENORM_MIN__
#else
#define __DBL_DENORM_MIN__ 4.94065645841246544177e-324
#endif
#endif /* __DBL_DENORM_MIN__ */

#ifndef __DBL_MIN_EXP__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_MIN_EXP__ __FLT_MIN_EXP__
#else
#define __DBL_MIN_EXP__ (-1021)
#endif
#endif /* __DBL_MIN_EXP__ */

#ifndef __DBL_MIN_10_EXP__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_MIN_10_EXP__ __FLT_MIN_10_EXP__
#else
#define __DBL_MIN_10_EXP__ (-307)
#endif
#endif /* __DBL_MIN_10_EXP__ */

#ifndef __DBL_DECIMAL_DIG__
#define __DBL_DECIMAL_DIG__ 17
#endif /* __DBL_DECIMAL_DIG__ */

#ifndef __DBL_MAX_10_EXP__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_MAX_10_EXP__ __FLT_MAX_10_EXP__
#else
#define __DBL_MAX_10_EXP__ 308
#endif
#endif /* __DBL_MAX_10_EXP__ */

#ifndef __DBL_MAX_EXP__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_MAX_EXP__ __FLT_MAX_EXP__
#else
#define __DBL_MAX_EXP__ 1024
#endif
#endif /* __DBL_MAX_EXP__ */

#ifndef __DBL_MANT_DIG__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_MANT_DIG__ __FLT_MANT_DIG__
#else
#define __DBL_MANT_DIG__ 53
#endif
#endif /* __DBL_MANT_DIG__ */

#ifndef __DBL_EPSILON__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_EPSILON__ __FLT_EPSILON__
#else
#define __DBL_EPSILON__ 2.22044604925031308085e-16
#endif
#endif /* __DBL_EPSILON__ */

#ifndef __DBL_HAS_QUIET_NAN__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_HAS_QUIET_NAN__ __FLT_HAS_QUIET_NAN__
#else
#define __DBL_HAS_QUIET_NAN__ 1
#endif
#endif /* __DBL_HAS_QUIET_NAN__ */

#ifndef __DBL_HAS_DENORM__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_HAS_DENORM__ __FLT_HAS_DENORM__
#else
#define __DBL_HAS_DENORM__ 1
#endif
#endif /* __DBL_HAS_DENORM__ */

#ifndef __DBL_HAS_INFINITY__
#if __DBL_DIG__ == __FLT_DIG__
#define __DBL_HAS_INFINITY__ __FLT_HAS_INFINITY__
#else
#define __DBL_HAS_INFINITY__ 1
#endif
#endif /* __DBL_HAS_INFINITY__ */

#ifndef __SIZEOF_LONG_DOUBLE__
#ifdef __PST_64BIT_TARGET__
#define __SIZEOF_LONG_DOUBLE__ 16
#else
#define __SIZEOF_LONG_DOUBLE__ 12
#endif
#endif /* __SIZEOF_LONG_DOUBLE__ */

#ifndef __LDBL_DIG__
#define __LDBL_DIG__ 18
#endif /* __LDBL_DIG__ */

#ifndef __LDBL_MIN__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_MIN__ __FLT_MIN__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_MIN__ __DBL_MIN__
#else
#define __LDBL_MIN__ 3.36210314311209350626e-4932L
#endif
#endif /* __LDBL_MIN__ */

#ifndef __LDBL_MAX__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_MAX__ __FLT_MAX__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_MAX__ __DBL_MAX__
#else
#define __LDBL_MAX__ 1.18973149535723176502e+4932L
#endif
#endif /* __LDBL_MAX__ */

#ifndef __LDBL_DENORM_MIN__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_DENORM_MIN__ __FLT_DENORM_MIN__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_DENORM_MIN__ __DBL_DENORM_MIN__
#else
#define __LDBL_DENORM_MIN__ 3.64519953188247460253e-4951L
#endif
#endif /* __LDBL_DENORM_MIN__ */

#ifndef __LDBL_HAS_INFINITY__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_HAS_INFINITY__ __FLT_HAS_INFINITY__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_HAS_INFINITY__ __DBL_HAS_INFINITY__
#else
#define __LDBL_HAS_INFINITY__ 1
#endif
#endif /* __LDBL_HAS_INFINITY__ */

#ifndef __LDBL_MIN_10_EXP__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_MIN_10_EXP__ __FLT_MIN_10_EXP__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_MIN_10_EXP__ __DBL_MIN_10_EXP__
#else
#define __LDBL_MIN_10_EXP__ (-4931)
#endif
#endif /* __LDBL_MIN_10_EXP__ */

#ifndef __LDBL_MIN_EXP__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_MIN_EXP__ __FLT_MIN_EXP__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_MIN_EXP__ __DBL_MIN_EXP__
#else
#define __LDBL_MIN_EXP__ (-16381)
#endif
#endif /* __LDBL_MIN_EXP__ */

#ifndef __LDBL_HAS_QUIET_NAN__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_HAS_QUIET_NAN__ __FLT_HAS_QUIET_NAN__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_HAS_QUIET_NAN__ __DBL_HAS_QUIET_NAN__
#else
#define __LDBL_HAS_QUIET_NAN__ 1
#endif
#endif /* __LDBL_HAS_QUIET_NAN__ */

#ifndef __LDBL_EPSILON__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_EPSILON__ __FLT_EPSILON__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_EPSILON__ __DBL_EPSILON__
#else
#define __LDBL_EPSILON__ 1.08420217248550443401e-19L
#endif
#endif /* __LDBL_EPSILON__ */

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

#ifndef __LDBL_MANT_DIG__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_MANT_DIG__ __FLT_MANT_DIG__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_MANT_DIG__ __DBL_MANT_DIG__
#else
#define __LDBL_MANT_DIG__ 64
#endif
#endif /* __LDBL_MANT_DIG__ */

#ifndef __LDBL_HAS_DENORM__
#if __LDBL_DIG__ == __FLT_DIG__
#define __LDBL_HAS_DENORM__ __FLT_HAS_DENORM__
#elif __LDBL_DIG__ == __DBL_DIG__
#define __LDBL_HAS_DENORM__ __DBL_HAS_DENORM__
#else
#define __LDBL_HAS_DENORM__ 1
#endif
#endif /* __LDBL_HAS_DENORM__ */

#ifndef __DEC32_MIN__
#define __DEC32_MIN__ 1E-95DF
#endif /* __DEC32_MIN__ */

#ifndef __DEC32_MAX__
#define __DEC32_MAX__ 9.999999E96DF
#endif /* __DEC32_MAX__ */

#ifndef __DEC32_SUBNORMAL_MIN__
#define __DEC32_SUBNORMAL_MIN__ 0.000001E-95DF
#endif /* __DEC32_SUBNORMAL_MIN__ */

#ifndef __DEC32_MANT_DIG__
#define __DEC32_MANT_DIG__ 7
#endif /* __DEC32_MANT_DIG__ */

#ifndef __DEC32_MIN_EXP__
#define __DEC32_MIN_EXP__ (-94)
#endif /* __DEC32_MIN_EXP__ */

#ifndef __DEC32_MAX_EXP__
#define __DEC32_MAX_EXP__ 97
#endif /* __DEC32_MAX_EXP__ */

#ifndef __DEC32_EPSILON__
#define __DEC32_EPSILON__ 1E-6DF
#endif /* __DEC32_EPSILON__ */

#ifndef __DEC64_MIN__
#define __DEC64_MIN__ 1E-383DD
#endif /* __DEC64_MIN__ */

#ifndef __DEC64_MAX__
#define __DEC64_MAX__ 9.999999999999999E384DD
#endif /* __DEC64_MAX__ */

#ifndef __DEC64_MANT_DIG__
#define __DEC64_MANT_DIG__ 16
#endif /* __DEC64_MANT_DIG__ */

#ifndef __DEC64_MIN_EXP__
#define __DEC64_MIN_EXP__ (-382)
#endif /* __DEC64_MIN_EXP__ */

#ifndef __DEC64_MAX_EXP__
#define __DEC64_MAX_EXP__ 385
#endif /* __DEC64_MAX_EXP__ */

#ifndef __DEC64_SUBNORMAL_MIN__
#define __DEC64_SUBNORMAL_MIN__ 0.000000000000001E-383DD
#endif /* __DEC64_SUBNORMAL_MIN__ */

#ifndef __DEC64_EPSILON__
#define __DEC64_EPSILON__ 1E-15DD
#endif /* __DEC64_EPSILON__ */

#ifndef __DEC128_MANT_DIG__
#define __DEC128_MANT_DIG__ 34
#endif /* __DEC128_MANT_DIG__ */

#ifndef __DEC128_MAX_EXP__
#define __DEC128_MAX_EXP__ 6145
#endif /* __DEC128_MAX_EXP__ */

#ifndef __DEC128_SUBNORMAL_MIN__
#define __DEC128_SUBNORMAL_MIN__ 0.000000000000000000000000000000001E-6143DL
#endif /* __DEC128_SUBNORMAL_MIN__ */

#ifndef __DEC128_MIN__
#define __DEC128_MIN__ 1E-6143DL
#endif /* __DEC128_MIN__ */

#ifndef __DEC128_MIN_EXP__
#define __DEC128_MIN_EXP__ (-6142)
#endif /* __DEC128_MIN_EXP__ */

#ifndef __DEC128_MAX__
#define __DEC128_MAX__ 9.999999999999999999999999999999999E6144DL
#endif /* __DEC128_MAX__ */

#ifndef __DEC128_EPSILON__
#define __DEC128_EPSILON__ 1E-33DL
#endif /* __DEC128_EPSILON__ */

#ifndef __DEC_EVAL_METHOD__
#define __DEC_EVAL_METHOD__ 2
#endif /* __DEC_EVAL_METHOD__ */

#ifndef __DECIMAL_BID_FORMAT__
#define __DECIMAL_BID_FORMAT__ 1
#endif /* __DECIMAL_BID_FORMAT__ */

#ifndef __DECIMAL_DIG__
#define __DECIMAL_DIG__ 21
#endif /* __DECIMAL_DIG__ */

#ifndef __FINITE_MATH_ONLY__
#define __FINITE_MATH_ONLY__ 0
#endif /* __FINITE_MATH_ONLY__ */


/* Polyspace does not support __float128 */
#ifdef __SIZEOF_FLOAT128__
#undef __SIZEOF_FLOAT128__
#endif /* __SIZEOF_FLOAT128__ */


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
#if !defined(__ATOMIC_RELAXED) && \
 !defined(__ATOMIC_CONSUME) && \
 !defined(__ATOMIC_ACQUIRE) && \
 !defined(__ATOMIC_RELEASE) && \
 !defined(__ATOMIC_ACQ_REL) && \
 !defined(__ATOMIC_SEQ_CST) && \
 !defined(__GCC_ATOMIC_TEST_AND_SET_TRUEVAL) && \
 !defined(__GCC_ATOMIC_BOOL_LOCK_FREE) && \
 !defined(__GCC_ATOMIC_CHAR_LOCK_FREE) && \
 !defined(__GCC_ATOMIC_CHAR8_T_LOCK_FREE) && \
 !defined(__GCC_ATOMIC_CHAR16_T_LOCK_FREE) && \
 !defined(__GCC_ATOMIC_CHAR32_T_LOCK_FREE) && \
 !defined(__GCC_ATOMIC_SHORT_LOCK_FREE) && \
 !defined(__GCC_ATOMIC_INT_LOCK_FREE) && \
 !defined(__GCC_ATOMIC_LONG_LOCK_FREE) && \
 !defined(__GCC_ATOMIC_LLONG_LOCK_FREE) && \
 !defined(__GCC_ATOMIC_WCHAR_T_LOCK_FREE) && \
 !defined(__GCC_ATOMIC_POINTER_LOCK_FREE) && \
 !defined(__SIG_ATOMIC_TYPE__) && \
 !defined(__SIG_ATOMIC_MIN__) && \
 !defined(__SIG_ATOMIC_MAX__)
#define __ATOMIC_RELAXED 0
#define __ATOMIC_CONSUME 1
#define __ATOMIC_ACQUIRE 2
#define __ATOMIC_RELEASE 3
#define __ATOMIC_ACQ_REL 4
#define __ATOMIC_SEQ_CST 5
#define __GCC_ATOMIC_TEST_AND_SET_TRUEVAL 1
#define __GCC_ATOMIC_BOOL_LOCK_FREE 2
#define __GCC_ATOMIC_CHAR_LOCK_FREE 2
#define __GCC_ATOMIC_CHAR8_T_LOCK_FREE 2
#define __GCC_ATOMIC_CHAR16_T_LOCK_FREE 2
#define __GCC_ATOMIC_CHAR32_T_LOCK_FREE 2
#define __GCC_ATOMIC_SHORT_LOCK_FREE 2
#define __GCC_ATOMIC_INT_LOCK_FREE 2
#define __GCC_ATOMIC_LONG_LOCK_FREE 2
#define __GCC_ATOMIC_LLONG_LOCK_FREE 2
#define __GCC_ATOMIC_WCHAR_T_LOCK_FREE 2
#define __GCC_ATOMIC_POINTER_LOCK_FREE 2
#define __SIG_ATOMIC_TYPE__ int
#define __SIG_ATOMIC_MIN__ (-__SIG_ATOMIC_MAX__ - 1)
#define __SIG_ATOMIC_MAX__ 0x7fffffff
#endif


/*
 * Miscellaneous macros.
 */

#ifndef __cpp_binary_literals
#define __cpp_binary_literals 201304
#endif /* __cpp_binary_literals */

#ifndef __has_include__
#define __has_include__(STR) __has_include(STR)
#endif /* __has_include */

#ifndef __STDC__
#define __STDC__ 1
#endif /* __STDC__ */

#ifndef __STDC_HOSTED__
#define __STDC_HOSTED__ 1
#endif /* __STDC_HOSTED__ */

#ifndef __has_include_next__
#define __has_include_next__(STR) __has_include_next(STR)
#endif /* __has_include_next */

#ifndef __BIGGEST_ALIGNMENT__
#define __BIGGEST_ALIGNMENT__ 16
#endif /* __BIGGEST_ALIGNMENT__ */


#ifndef __NO_INLINE__
#define __NO_INLINE__ 1
#endif /* __NO_INLINE__ */

#ifndef __cpp_rtti
#define __cpp_rtti 199711
#endif /* __cpp_rtti */

#ifndef __GLIBCXX_BITSIZE_INT_N_0
#define __GLIBCXX_BITSIZE_INT_N_0 128
#endif /* __GLIBCXX_BITSIZE_INT_N_0 */

#ifndef __PRAGMA_REDEFINE_EXTNAME
#define __PRAGMA_REDEFINE_EXTNAME 1
#endif /* __PRAGMA_REDEFINE_EXTNAME */

#ifndef __cpp_runtime_arrays
#define __cpp_runtime_arrays 198712
#endif /* __cpp_runtime_arrays */

#ifndef __cpp_exceptions
#define __cpp_exceptions 199711
#endif /* __cpp_exceptions */

#include "../tmw_builtins/tmw_builtins.h"

#define __builtin_expect(e,k) e
#define __builtin_expect_with_probability(e,k,p) e

#endif /* __POLYSPACE__GCC_H */
