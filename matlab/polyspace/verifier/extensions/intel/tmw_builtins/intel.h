/* Copyright 2022 The MathWorks, Inc. */

#ifndef _INTEL_H_
#define _INTEL_H_

/*
 * From Intel® Parallel Studio XE 2020
 */

#if defined(__TMW_COMPILER_INTEL__) && defined(__TMW_TARGET_X86_64__)

#pragma tmw no_emit

#if !defined(__ICC) && !defined(__ICL)
#define __ICL 1910
#endif

#ifndef __cplusplus

#ifndef __DEC_EVAL_METHOD__
#define __DEC_EVAL_METHOD__ 2
#endif
#ifndef __STDC_DEC_FP__
#define __STDC_DEC_FP__ 200704L
#endif
#if defined(__ICC) && !defined(__STDC_UTF_16__)
#define __STDC_UTF_16__ 1
#endif
#if defined(__ICC) && !defined(__STDC_UTF_32__)
#define __STDC_UTF_32__ 1
#endif
#ifndef __STDC_VERSION__
#define __STDC_VERSION__ 201112L
#endif

#else /* __cplusplus */

#if defined(__ICC) && !defined(_BOOL)
#define _BOOL 1
#endif
#if defined(__ICC) && !defined(_GNU_SOURCE)
#define _GNU_SOURCE 1
#endif
#ifndef _WCHAR_T
#define _WCHAR_T 1
#endif
#ifndef __ARRAY_OPERATORS
#define __ARRAY_OPERATORS 1
#endif
#ifndef __CHAR16_T_AND_CHAR32_T
#define __CHAR16_T_AND_CHAR32_T 1
#endif
#if defined(__ICC) && !defined(__DEPRECATED)
#define __DEPRECATED 1
#endif
#if defined(__ICC) && !defined(__GLIBCXX_BITSIZE_INT_N_0)
#define __GLIBCXX_BITSIZE_INT_N_0 128
#endif
#if defined(__ICC) && !defined(__GLIBCXX_TYPE_INT_N_0)
#define __GLIBCXX_TYPE_INT_N_0 __int128
#endif
#if defined(__ICC) && !defined(__GXX_EXPERIMENTAL_CXX0X__)
#define __GXX_EXPERIMENTAL_CXX0X__ 1
#endif
#if defined(__ICC) && !defined(__GXX_RTTI)
#define __GXX_RTTI 1
#endif
#if defined(__ICC) && !defined(__GXX_WEAK__)
#define __GXX_WEAK__ 1
#endif
#if defined(__ICC) && !defined(__PLACEMENT_DELETE)
#define __PLACEMENT_DELETE 1
#endif
#ifndef __RTTI
#define __RTTI 1
#endif
#ifndef __STDCPP_DEFAULT_NEW_ALIGNMENT__
#define __STDCPP_DEFAULT_NEW_ALIGNMENT__ 16
#endif
#ifndef __STDCPP_THREADS__
#define __STDCPP_THREADS__ 1
#endif
#ifndef __VARIADIC_TEMPLATES
#define __VARIADIC_TEMPLATES 1
#endif
#ifndef __cpp_aggregate_nsdmi
#define __cpp_aggregate_nsdmi 201304L
#endif
#ifndef __cpp_alias_templates
#define __cpp_alias_templates 200704L
#endif
#ifndef __cpp_attributes
#define __cpp_attributes 200809L
#endif
#ifndef __cpp_binary_literals
#define __cpp_binary_literals 201304L
#endif
#ifndef __cpp_constexpr
#define __cpp_constexpr 201304L
#endif
#ifndef __cpp_decltype
#define __cpp_decltype 200707L
#endif
#ifndef __cpp_decltype_auto
#define __cpp_decltype_auto 201304L
#endif
#ifndef __cpp_delegating_constructors
#define __cpp_delegating_constructors 200604L
#endif
#ifndef __cpp_exceptions
#define __cpp_exceptions 199711L
#endif
#ifndef __cpp_generic_lambdas
#define __cpp_generic_lambdas 201304L
#endif
#ifndef __cpp_inheriting_constructors
#define __cpp_inheriting_constructors 200802L
#endif
#ifndef __cpp_init_captures
#define __cpp_init_captures 201304L
#endif
#ifndef __cpp_initializer_lists
#define __cpp_initializer_lists 200806L
#endif
#ifndef __cpp_lambdas
#define __cpp_lambdas 200907L
#endif
#ifndef __cpp_nsdmi
#define __cpp_nsdmi 200809L
#endif
#ifndef __cpp_range_based_for
#define __cpp_range_based_for 200907L
#endif
#ifndef __cpp_raw_strings
#define __cpp_raw_strings 200710L
#endif
#ifndef __cpp_ref_qualifiers
#define __cpp_ref_qualifiers 200710L
#endif
#ifndef __cpp_return_type_deduction
#define __cpp_return_type_deduction 201304L
#endif
#ifndef __cpp_rtti
#define __cpp_rtti 199711L
#endif
#ifndef __cpp_rvalue_references
#define __cpp_rvalue_references 200610L
#endif
#ifndef __cpp_sized_deallocation
#define __cpp_sized_deallocation 201309L
#endif
#ifndef __cpp_static_assert
#define __cpp_static_assert 200410
#endif
#ifndef __cpp_threadsafe_static_init
#define __cpp_threadsafe_static_init 200806L
#endif
#ifndef __cpp_unicode_characters
#define __cpp_unicode_characters 200704L
#endif
#ifndef __cpp_unicode_literals
#define __cpp_unicode_literals 200710L
#endif
#ifndef __cpp_user_defined_literals
#define __cpp_user_defined_literals 200809L
#endif
#ifndef __cpp_variable_templates
#define __cpp_variable_templates 201304L
#endif
#ifndef __cpp_variadic_templates
#define __cpp_variadic_templates 200704L
#endif

#endif /* __cplusplus */

#if defined(__ICC) && !defined(_GLIBCXX_NO_BUILTIN_HAS_UNIQ_OBJ_REP)
#define _GLIBCXX_NO_BUILTIN_HAS_UNIQ_OBJ_REP 1
#endif
#if defined(__ICC) && !defined(_GLIBCXX_NO_BUILTIN_LAUNDER)
#define _GLIBCXX_NO_BUILTIN_LAUNDER 1
#endif
#if defined(__ICC) && !defined(_LP64)
#define _LP64 1
#endif
#if !defined(__SIGNED_CHARS__) && ((char)-1<0)
#define __SIGNED_CHARS__ 1
#endif

#if defined(__ICC) && !defined(__ATOMIC_ACQUIRE)
#define __ATOMIC_ACQUIRE 2
#endif
#if defined(__ICC) && !defined(__ATOMIC_ACQ_REL)
#define __ATOMIC_ACQ_REL 4
#endif
#if defined(__ICC) && !defined(__ATOMIC_CONSUME)
#define __ATOMIC_CONSUME 1
#endif
#if defined(__ICC) && !defined(__ATOMIC_HLE_ACQUIRE)
#define __ATOMIC_HLE_ACQUIRE 65536
#endif
#if defined(__ICC) && !defined(__ATOMIC_HLE_RELEASE)
#define __ATOMIC_HLE_RELEASE 131072
#endif
#if defined(__ICC) && !defined(__ATOMIC_RELAXED)
#define __ATOMIC_RELAXED 0
#endif
#if defined(__ICC) && !defined(__ATOMIC_RELEASE)
#define __ATOMIC_RELEASE 3
#endif
#if defined(__ICC) && !defined(__ATOMIC_SEQ_CST)
#define __ATOMIC_SEQ_CST 5
#endif
#if defined(__ICC) && !defined(__BIGGEST_ALIGNMENT__)
#define __BIGGEST_ALIGNMENT__ 64
#endif
#if defined(__ICC) && !defined(__BYTE_ORDER__)
#define __BYTE_ORDER__ __ORDER_LITTLE_ENDIAN__
#endif
#if defined(__ICC) && !defined(__CHAR16_TYPE__)
#define __CHAR16_TYPE__ unsigned short
#endif
#if defined(__ICC) && !defined(__CHAR32_TYPE__)
#define __CHAR32_TYPE__ unsigned int
#endif
#if defined(__ICC) && !defined(__CHAR_BIT__)
#define __CHAR_BIT__ 8
#endif
#if defined(__ICC) && !defined(__DBL_DECIMAL_DIG__)
#define __DBL_DECIMAL_DIG__ 17
#endif
#if defined(__ICC) && !defined(__DBL_DENORM_MIN__)
#define __DBL_DENORM_MIN__ 4.9406564584124654e-324
#endif
#if defined(__ICC) && !defined(__DBL_DIG__)
#define __DBL_DIG__ 15
#endif
#if defined(__ICC) && !defined(__DBL_EPSILON__)
#define __DBL_EPSILON__ 2.2204460492503131e-16
#endif
#if defined(__ICC) && !defined(__DBL_HAS_DENORM__)
#define __DBL_HAS_DENORM__ 1
#endif
#if defined(__ICC) && !defined(__DBL_HAS_INFINITY__)
#define __DBL_HAS_INFINITY__ 1
#endif
#if defined(__ICC) && !defined(__DBL_HAS_QUIET_NAN__)
#define __DBL_HAS_QUIET_NAN__ 1
#endif
#if defined(__ICC) && !defined(__DBL_MANT_DIG__)
#define __DBL_MANT_DIG__ 53
#endif
#if defined(__ICC) && !defined(__DBL_MAX_10_EXP__)
#define __DBL_MAX_10_EXP__ 308
#endif
#if defined(__ICC) && !defined(__DBL_MAX_EXP__)
#define __DBL_MAX_EXP__ 1024
#endif
#if defined(__ICC) && !defined(__DBL_MAX__)
#define __DBL_MAX__ 1.7976931348623157e+308
#endif
#if defined(__ICC) && !defined(__DBL_MIN_10_EXP__)
#define __DBL_MIN_10_EXP__ -307
#endif
#if defined(__ICC) && !defined(__DBL_MIN_EXP__)
#define __DBL_MIN_EXP__ -1021
#endif
#if defined(__ICC) && !defined(__DBL_MIN__)
#define __DBL_MIN__ 2.2250738585072014e-308
#endif
#if defined(__ICC) && !defined(__DEC128_EPSILON__)
#define __DEC128_EPSILON__ 1E-33DL
#endif
#if defined(__ICC) && !defined(__DEC128_MANT_DIG__)
#define __DEC128_MANT_DIG__ 34
#endif
#if defined(__ICC) && !defined(__DEC128_MAX_EXP__)
#define __DEC128_MAX_EXP__ 6145
#endif
#if defined(__ICC) && !defined(__DEC128_MAX__)
#define __DEC128_MAX__ 9.999999999999999999999999999999999E6144DL
#endif
#if defined(__ICC) && !defined(__DEC128_MIN_EXP__)
#define __DEC128_MIN_EXP__ -6142
#endif
#if defined(__ICC) && !defined(__DEC128_MIN__)
#define __DEC128_MIN__ 1E-6143DL
#endif
#if defined(__ICC) && !defined(__DEC128_SUBNORMAL_MIN__)
#define __DEC128_SUBNORMAL_MIN__ 0.000000000000000000000000000000001E-6143DL
#endif
#if defined(__ICC) && !defined(__DEC32_EPSILON__)
#define __DEC32_EPSILON__ 1E-6DF
#endif
#if defined(__ICC) && !defined(__DEC32_MANT_DIG__)
#define __DEC32_MANT_DIG__ 7
#endif
#if defined(__ICC) && !defined(__DEC32_MAX_EXP__)
#define __DEC32_MAX_EXP__ 97
#endif
#if defined(__ICC) && !defined(__DEC32_MAX__)
#define __DEC32_MAX__ 9.999999E96DF
#endif
#if defined(__ICC) && !defined(__DEC32_MIN_EXP__)
#define __DEC32_MIN_EXP__ -94
#endif
#if defined(__ICC) && !defined(__DEC32_MIN__)
#define __DEC32_MIN__ 1E-95DF
#endif
#if defined(__ICC) && !defined(__DEC32_SUBNORMAL_MIN__)
#define __DEC32_SUBNORMAL_MIN__ 0.000001E-95DF
#endif
#if defined(__ICC) && !defined(__DEC64_EPSILON__)
#define __DEC64_EPSILON__ 1E-15DD
#endif
#if defined(__ICC) && !defined(__DEC64_MANT_DIG__)
#define __DEC64_MANT_DIG__ 16
#endif
#if defined(__ICC) && !defined(__DEC64_MAX_EXP__)
#define __DEC64_MAX_EXP__ 385
#endif
#if defined(__ICC) && !defined(__DEC64_MAX__)
#define __DEC64_MAX__ 9.999999999999999E384DD
#endif
#if defined(__ICC) && !defined(__DEC64_MIN_EXP__)
#define __DEC64_MIN_EXP__ -382
#endif
#if defined(__ICC) && !defined(__DEC64_MIN__)
#define __DEC64_MIN__ 1E-383DD
#endif
#if defined(__ICC) && !defined(__DEC64_SUBNORMAL_MIN__)
#define __DEC64_SUBNORMAL_MIN__ 0.000000000000001E-383DD
#endif
#if defined(__ICC) && !defined(__DECIMAL_BID_FORMAT__)
#define __DECIMAL_BID_FORMAT__ 1
#endif
#if defined(__ICC) && !defined(__DECIMAL_DIG__)
#define __DECIMAL_DIG__ 21
#endif
#if defined(__ICC) && !defined(__ELF__)
#define __ELF__ 1
#endif
#if defined(__ICC) && !defined(__FINITE_MATH_ONLY__)
#define __FINITE_MATH_ONLY__ 0
#endif
#if defined(__ICC) && !defined(__FLOAT_WORD_ORDER__)
#define __FLOAT_WORD_ORDER__ __ORDER_LITTLE_ENDIAN__
#endif
#if defined(__ICC) && !defined(__FLT_DECIMAL_DIG__)
#define __FLT_DECIMAL_DIG__ 9
#endif
#if defined(__ICC) && !defined(__FLT_DENORM_MIN__)
#define __FLT_DENORM_MIN__ 1.40129846e-45F
#endif
#if defined(__ICC) && !defined(__FLT_DIG__)
#define __FLT_DIG__ 6
#endif
#if defined(__ICC) && !defined(__FLT_EPSILON__)
#define __FLT_EPSILON__ 1.19209290e-7F
#endif
#if defined(__ICC) && !defined(__FLT_HAS_DENORM__)
#define __FLT_HAS_DENORM__ 1
#endif
#if defined(__ICC) && !defined(__FLT_HAS_INFINITY__)
#define __FLT_HAS_INFINITY__ 1
#endif
#if defined(__ICC) && !defined(__FLT_HAS_QUIET_NAN__)
#define __FLT_HAS_QUIET_NAN__ 1
#endif
#if defined(__ICC) && !defined(__FLT_MANT_DIG__)
#define __FLT_MANT_DIG__ 24
#endif
#if defined(__ICC) && !defined(__FLT_MAX_10_EXP__)
#define __FLT_MAX_10_EXP__ 38
#endif
#if defined(__ICC) && !defined(__FLT_MAX_EXP__)
#define __FLT_MAX_EXP__ 128
#endif
#if defined(__ICC) && !defined(__FLT_MAX__)
#define __FLT_MAX__ 3.40282347e+38F
#endif
#if defined(__ICC) && !defined(__FLT_MIN_10_EXP__)
#define __FLT_MIN_10_EXP__ -37
#endif
#if defined(__ICC) && !defined(__FLT_MIN_EXP__)
#define __FLT_MIN_EXP__ -125
#endif
#if defined(__ICC) && !defined(__FLT_MIN__)
#define __FLT_MIN__ 1.17549435e-38F
#endif
#if defined(__ICC) && !defined(__FLT_RADIX__)
#define __FLT_RADIX__ 2
#endif
#if defined(__ICC) && !defined(__GCC_ATOMIC_BOOL_LOCK_FREE)
#define __GCC_ATOMIC_BOOL_LOCK_FREE 2
#endif
#if defined(__ICC) && !defined(__GCC_ATOMIC_CHAR16_T_LOCK_FREE)
#define __GCC_ATOMIC_CHAR16_T_LOCK_FREE 2
#endif
#if defined(__ICC) && !defined(__GCC_ATOMIC_CHAR32_T_LOCK_FREE)
#define __GCC_ATOMIC_CHAR32_T_LOCK_FREE 2
#endif
#if defined(__ICC) && !defined(__GCC_ATOMIC_CHAR_LOCK_FREE)
#define __GCC_ATOMIC_CHAR_LOCK_FREE 2
#endif
#if defined(__ICC) && !defined(__GCC_ATOMIC_INT_LOCK_FREE)
#define __GCC_ATOMIC_INT_LOCK_FREE 2
#endif
#if defined(__ICC) && !defined(__GCC_ATOMIC_LLONG_LOCK_FREE)
#define __GCC_ATOMIC_LLONG_LOCK_FREE 2
#endif
#if defined(__ICC) && !defined(__GCC_ATOMIC_LONG_LOCK_FREE)
#define __GCC_ATOMIC_LONG_LOCK_FREE 2
#endif
#if defined(__ICC) && !defined(__GCC_ATOMIC_POINTER_LOCK_FREE)
#define __GCC_ATOMIC_POINTER_LOCK_FREE 2
#endif
#if defined(__ICC) && !defined(__GCC_ATOMIC_SHORT_LOCK_FREE)
#define __GCC_ATOMIC_SHORT_LOCK_FREE 2
#endif
#if defined(__ICC) && !defined(__GCC_ATOMIC_TEST_AND_SET_TRUEVAL)
#define __GCC_ATOMIC_TEST_AND_SET_TRUEVAL 1
#endif
#if defined(__ICC) && !defined(__GCC_ATOMIC_WCHAR_T_LOCK_FREE)
#define __GCC_ATOMIC_WCHAR_T_LOCK_FREE 2
#endif
#if defined(__ICC) && !defined(__GCC_HAVE_SYNC_COMPARE_AND_SWAP_1)
#define __GCC_HAVE_SYNC_COMPARE_AND_SWAP_1 1
#endif
#if defined(__ICC) && !defined(__GCC_HAVE_SYNC_COMPARE_AND_SWAP_2)
#define __GCC_HAVE_SYNC_COMPARE_AND_SWAP_2 1
#endif
#if defined(__ICC) && !defined(__GCC_HAVE_SYNC_COMPARE_AND_SWAP_4)
#define __GCC_HAVE_SYNC_COMPARE_AND_SWAP_4 1
#endif
#if defined(__ICC) && !defined(__GCC_HAVE_SYNC_COMPARE_AND_SWAP_8)
#define __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8 1
#endif
#if defined(__ICC) && !defined(__GNUC_GNU_INLINE__)
#define __GNUC_GNU_INLINE__ 1
#endif
#if defined(__ICC) && !defined(__GNUC_MINOR__)
#define __GNUC_MINOR__ 1
#endif
#if defined(__ICC) && !defined(__GNUC_PATCHLEVEL__)
#define __GNUC_PATCHLEVEL__ 0
#endif
#if defined(__ICC) && !defined(__GNUC_STDC_INLINE__)
#define __GNUC_STDC_INLINE__ 1
#endif
#if defined(__ICC) && !defined(__GNUC__)
#define __GNUC__ 10
#endif
#if defined(__ICC) && !defined(__GXX_ABI_VERSION)
#define __GXX_ABI_VERSION 1010
#endif
#if defined(__ICC) && !defined(__INT16_MAX__)
#define __INT16_MAX__ 32767
#endif
#if defined(__ICC) && !defined(__INT16_TYPE__)
#define __INT16_TYPE__ short
#endif
#if defined(__ICC) && !defined(__INT32_MAX__)
#define __INT32_MAX__ 2147483647
#endif
#if defined(__ICC) && !defined(__INT32_TYPE__)
#define __INT32_TYPE__ int
#endif
#if defined(__ICC) && !defined(__INT64_MAX__)
#define __INT64_MAX__ 9223372036854775807L
#endif
#if defined(__ICC) && !defined(__INT64_TYPE__)
#define __INT64_TYPE__ long
#endif
#if defined(__ICC) && !defined(__INT8_MAX__)
#define __INT8_MAX__ 127
#endif
#if defined(__ICC) && !defined(__INT8_TYPE__)
#define __INT8_TYPE__ signed char
#endif
#ifndef __INTEL_COMPILER
#if defined(__ICC)
#define __INTEL_COMPILER 2021
#else
#define __INTEL_COMPILER 1910
#endif
#endif
#ifndef __INTEL_COMPILER_BUILD_DATE
#if defined(__ICC)
#define __INTEL_COMPILER_BUILD_DATE 20211109
#else
#define __INTEL_COMPILER_BUILD_DATE 20191121
#endif
#endif
#ifndef __INTEL_COMPILER_UPDATE
#define __INTEL_COMPILER_UPDATE 5
#endif
#ifndef __INTEL_OFFLOAD
#define __INTEL_OFFLOAD 1
#endif
#if defined(__ICC) && !defined(__INTEL_RTTI__)
#define __INTEL_RTTI__ 1
#endif
#if defined(__ICC) && !defined(__INTMAX_MAX__)
#define __INTMAX_MAX__ 0x7fffffffffffffff
#endif
#if defined(__ICC) && !defined(__INTMAX_TYPE__)
#define __INTMAX_TYPE__ long int
#endif
#if defined(__ICC) && !defined(__INTPTR_MAX__)
#define __INTPTR_MAX__ 9223372036854775807L
#endif
#if defined(__ICC) && !defined(__INTPTR_TYPE__)
#define __INTPTR_TYPE__ long
#endif
#if defined(__ICC) && !defined(__INT_FAST16_MAX__)
#define __INT_FAST16_MAX__ 9223372036854775807L
#endif
#if defined(__ICC) && !defined(__INT_FAST16_TYPE__)
#define __INT_FAST16_TYPE__ long
#endif
#if defined(__ICC) && !defined(__INT_FAST32_MAX__)
#define __INT_FAST32_MAX__ 9223372036854775807L
#endif
#if defined(__ICC) && !defined(__INT_FAST32_TYPE__)
#define __INT_FAST32_TYPE__ long
#endif
#if defined(__ICC) && !defined(__INT_FAST64_MAX__)
#define __INT_FAST64_MAX__ 9223372036854775807L
#endif
#if defined(__ICC) && !defined(__INT_FAST64_TYPE__)
#define __INT_FAST64_TYPE__ long
#endif
#if defined(__ICC) && !defined(__INT_FAST8_MAX__)
#define __INT_FAST8_MAX__ 127
#endif
#if defined(__ICC) && !defined(__INT_FAST8_TYPE__)
#define __INT_FAST8_TYPE__ char
#endif
#if defined(__ICC) && !defined(__INT_LEAST16_MAX__)
#define __INT_LEAST16_MAX__ 32767
#endif
#if defined(__ICC) && !defined(__INT_LEAST16_TYPE__)
#define __INT_LEAST16_TYPE__ short
#endif
#if defined(__ICC) && !defined(__INT_LEAST32_MAX__)
#define __INT_LEAST32_MAX__ 2147483647
#endif
#if defined(__ICC) && !defined(__INT_LEAST32_TYPE__)
#define __INT_LEAST32_TYPE__ int
#endif
#if defined(__ICC) && !defined(__INT_LEAST64_MAX__)
#define __INT_LEAST64_MAX__ 9223372036854775807L
#endif
#if defined(__ICC) && !defined(__INT_LEAST64_TYPE__)
#define __INT_LEAST64_TYPE__ long
#endif
#if defined(__ICC) && !defined(__INT_LEAST8_MAX__)
#define __INT_LEAST8_MAX__ 127
#endif
#if defined(__ICC) && !defined(__INT_LEAST8_TYPE__)
#define __INT_LEAST8_TYPE__ char
#endif
#if defined(__ICC) && !defined(__INT_MAX__)
#define __INT_MAX__ 2147483647
#endif
#if defined(__ICC) && !defined(__LDBL_DENORM_MIN__)
#define __LDBL_DENORM_MIN__ 3.64519953188247460253e-4951L
#endif
#if defined(__ICC) && !defined(__LDBL_DIG__)
#define __LDBL_DIG__ 18
#endif
#if defined(__ICC) && !defined(__LDBL_EPSILON__)
#define __LDBL_EPSILON__ 1.08420217248550443401e-19L
#endif
#if defined(__ICC) && !defined(__LDBL_HAS_DENORM__)
#define __LDBL_HAS_DENORM__ 1
#endif
#if defined(__ICC) && !defined(__LDBL_HAS_INFINITY__)
#define __LDBL_HAS_INFINITY__ 1
#endif
#if defined(__ICC) && !defined(__LDBL_HAS_QUIET_NAN__)
#define __LDBL_HAS_QUIET_NAN__ 1
#endif
#if defined(__ICC) && !defined(__LDBL_MANT_DIG__)
#define __LDBL_MANT_DIG__ 64
#endif
#if defined(__ICC) && !defined(__LDBL_MAX_10_EXP__)
#define __LDBL_MAX_10_EXP__ 4932
#endif
#if defined(__ICC) && !defined(__LDBL_MAX_EXP__)
#define __LDBL_MAX_EXP__ 16384
#endif
#if defined(__ICC) && !defined(__LDBL_MAX__)
#define __LDBL_MAX__ 1.18973149535723176502e+4932L
#endif
#if defined(__ICC) && !defined(__LDBL_MIN_10_EXP__)
#define __LDBL_MIN_10_EXP__ -4931
#endif
#if defined(__ICC) && !defined(__LDBL_MIN_EXP__)
#define __LDBL_MIN_EXP__ -16381
#endif
#if defined(__ICC) && !defined(__LDBL_MIN__)
#define __LDBL_MIN__ 3.36210314311209350626e-4932L
#endif
#ifndef __LONG_DOUBLE_SIZE__
#if defined(__ICC)
#define __LONG_DOUBLE_SIZE__ 80
#else
#define __LONG_DOUBLE_SIZE__ 64
#endif
#endif
#if defined(__ICC) && !defined(__LONG_LONG_MAX__)
#define __LONG_LONG_MAX__ 0x7fffffffffffffff
#endif
#if defined(__ICC) && !defined(__LONG_MAX__)
#define __LONG_MAX__ 9223372036854775807L
#endif
#if defined(__ICC) && !defined(__LP64__)
#define __LP64__ 1
#endif
#ifndef __MMX__
#define __MMX__ 1
#endif
#if defined(__ICC) && !defined(__NO_INLINE__)
#define __NO_INLINE__ 1
#endif
#if defined(__ICC) && !defined(__NO_MATH_INLINES)
#define __NO_MATH_INLINES 1
#endif
#if defined(__ICC) && !defined(__NO_STRING_INLINES)
#define __NO_STRING_INLINES 1
#endif
#if defined(__ICC) && !defined(__ORDER_BIG_ENDIAN__)
#define __ORDER_BIG_ENDIAN__ 4321
#endif
#if defined(__ICC) && !defined(__ORDER_LITTLE_ENDIAN__)
#define __ORDER_LITTLE_ENDIAN__ 1234
#endif
#if defined(__ICC) && !defined(__ORDER_PDP_ENDIAN__)
#define __ORDER_PDP_ENDIAN__ 3412
#endif
#if defined(__ICC) && !defined(__PRAGMA_REDEFINE_EXTNAME)
#define __PRAGMA_REDEFINE_EXTNAME 1
#endif
#if defined(__ICC) && !defined(__PTRDIFF_MAX__)
#define __PTRDIFF_MAX__ 9223372036854775807L
#endif
#if defined(__ICC) && !defined(__PTRDIFF_TYPE__)
#define __PTRDIFF_TYPE__ long
#endif
#ifndef __QMSPP_
#define __QMSPP_ 1
#endif
#if defined(__ICC) && !defined(__REGISTER_PREFIX__)
#define __REGISTER_PREFIX__
#endif
#if defined(__ICC) && !defined(__SCHAR_MAX__)
#define __SCHAR_MAX__ 127
#endif
#if defined(__ICC) && !defined(__SHRT_MAX__)
#define __SHRT_MAX__ 32767
#endif
#if defined(__ICC) && !defined(__SIG_ATOMIC_MAX__)
#define __SIG_ATOMIC_MAX__ 2147483647
#endif
#if defined(__ICC) && !defined(__SIG_ATOMIC_MIN__)
#define __SIG_ATOMIC_MIN__ (-__SIG_ATOMIC_MAX__ - 1)
#endif
#if defined(__ICC) && !defined(__SIG_ATOMIC_TYPE__)
#define __SIG_ATOMIC_TYPE__ int
#endif
#if defined(__ICC) && !defined(__SIZEOF_DOUBLE__)
#define __SIZEOF_DOUBLE__ 8
#endif
#if defined(__ICC) && !defined(__SIZEOF_FLOAT128__)
#define __SIZEOF_FLOAT128__ 16
#endif
#if defined(__ICC) && !defined(__SIZEOF_FLOAT80__)
#define __SIZEOF_FLOAT80__ 12
#endif
#if defined(__ICC) && !defined(__SIZEOF_FLOAT__)
#define __SIZEOF_FLOAT__ 4
#endif
#if defined(__ICC) && !defined(__SIZEOF_INT128__)
#define __SIZEOF_INT128__ 16
#endif
#if defined(__ICC) && !defined(__SIZEOF_INT__)
#define __SIZEOF_INT__ 4
#endif
#if defined(__ICC) && !defined(__SIZEOF_LONG_DOUBLE__)
#define __SIZEOF_LONG_DOUBLE__ 16
#endif
#if defined(__ICC) && !defined(__SIZEOF_LONG_LONG__)
#define __SIZEOF_LONG_LONG__ 8
#endif
#if defined(__ICC) && !defined(__SIZEOF_LONG__)
#define __SIZEOF_LONG__ 8
#endif
#if defined(__ICC) && !defined(__SIZEOF_POINTER__)
#define __SIZEOF_POINTER__ 8
#endif
#if defined(__ICC) && !defined(__SIZEOF_PTRDIFF_T__)
#define __SIZEOF_PTRDIFF_T__ 8
#endif
#if defined(__ICC) && !defined(__SIZEOF_SHORT__)
#define __SIZEOF_SHORT__ 2
#endif
#if defined(__ICC) && !defined(__SIZEOF_SIZE_T__)
#define __SIZEOF_SIZE_T__ 8
#endif
#if defined(__ICC) && !defined(__SIZEOF_WCHAR_T__)
#define __SIZEOF_WCHAR_T__ 4
#endif
#if defined(__ICC) && !defined(__SIZEOF_WINT_T__)
#define __SIZEOF_WINT_T__ 4
#endif
#if defined(__ICC) && !defined(__SIZE_MAX__)
#define __SIZE_MAX__ 18446744073709551615UL
#endif
#if defined(__ICC) && !defined(__SIZE_TYPE__)
#define __SIZE_TYPE__ unsigned long
#endif

#if !defined(_M_IX86)&&!defined(_M_X64)&&!defined(_M_ARM)&&!defined(_M_ARM64)
#define _M_X64
#endif

#if !defined(__SSE__)&&!defined(__SSE2__)&&!defined(__SSE3__)&&!defined(__SSE4_1__)&&!defined(__SSE4_2__)&&!defined(__SSSE3__)
#define __SSE__ 1
#define __SSE2__ 1
#ifndef __SSE2_MATH__
#define __SSE2_MATH__ 1
#endif
#ifndef __SSE_MATH__
#define __SSE_MATH__ 1
#endif
#endif

#ifndef __STDC_HOSTED__
#define __STDC_HOSTED__ 1
#endif
#if defined(__ICC) && !defined(__STDC_IEC_559_COMPLEX__)
#define __STDC_IEC_559_COMPLEX__ 1
#endif
#if defined(__ICC) && !defined(__STDC_IEC_559__)
#define __STDC_IEC_559__ 1
#endif
#if defined(__ICC) && !defined(__STDC_ISO_10646__)
#define __STDC_ISO_10646__ 201706L
#endif
#if defined(__ICC) && !defined(__STDC__)
#define __STDC__ 1
#endif
#if defined(__ICC) && !defined(__UINT16_MAX__)
#define __UINT16_MAX__ 65535
#endif
#if defined(__ICC) && !defined(__UINT16_TYPE__)
#define __UINT16_TYPE__ unsigned short
#endif
#if defined(__ICC) && !defined(__UINT32_MAX__)
#define __UINT32_MAX__ 4294967295U
#endif
#if defined(__ICC) && !defined(__UINT32_TYPE__)
#define __UINT32_TYPE__ unsigned int
#endif
#if defined(__ICC) && !defined(__UINT64_MAX__)
#define __UINT64_MAX__ 18446744073709551615UL
#endif
#if defined(__ICC) && !defined(__UINT64_TYPE__)
#define __UINT64_TYPE__ unsigned long
#endif
#if defined(__ICC) && !defined(__UINT8_MAX__)
#define __UINT8_MAX__ 255
#endif
#if defined(__ICC) && !defined(__UINT8_TYPE__)
#define __UINT8_TYPE__ unsigned char
#endif
#if defined(__ICC) && !defined(__UINTMAX_MAX__)
#define __UINTMAX_MAX__ 0xffffffffffffffff
#endif
#if defined(__ICC) && !defined(__UINTMAX_TYPE__)
#define __UINTMAX_TYPE__ long unsigned int
#endif
#if defined(__ICC) && !defined(__UINTPTR_MAX__)
#define __UINTPTR_MAX__ 18446744073709551615UL
#endif
#if defined(__ICC) && !defined(__UINTPTR_TYPE__)
#define __UINTPTR_TYPE__ unsigned long
#endif
#if defined(__ICC) && !defined(__UINT_FAST16_MAX__)
#define __UINT_FAST16_MAX__ 18446744073709551615UL
#endif
#if defined(__ICC) && !defined(__UINT_FAST16_TYPE__)
#define __UINT_FAST16_TYPE__ unsigned long
#endif
#if defined(__ICC) && !defined(__UINT_FAST32_MAX__)
#define __UINT_FAST32_MAX__ 18446744073709551615UL
#endif
#if defined(__ICC) && !defined(__UINT_FAST32_TYPE__)
#define __UINT_FAST32_TYPE__ unsigned long
#endif
#if defined(__ICC) && !defined(__UINT_FAST64_MAX__)
#define __UINT_FAST64_MAX__ 18446744073709551615UL
#endif
#if defined(__ICC) && !defined(__UINT_FAST64_TYPE__)
#define __UINT_FAST64_TYPE__ unsigned long
#endif
#if defined(__ICC) && !defined(__UINT_FAST8_MAX__)
#define __UINT_FAST8_MAX__ 255
#endif
#if defined(__ICC) && !defined(__UINT_FAST8_TYPE__)
#define __UINT_FAST8_TYPE__ unsigned char
#endif
#if defined(__ICC) && !defined(__UINT_LEAST16_MAX__)
#define __UINT_LEAST16_MAX__ 65535
#endif
#if defined(__ICC) && !defined(__UINT_LEAST16_TYPE__)
#define __UINT_LEAST16_TYPE__ unsigned short
#endif
#if defined(__ICC) && !defined(__UINT_LEAST32_MAX__)
#define __UINT_LEAST32_MAX__ 4294967295U
#endif
#if defined(__ICC) && !defined(__UINT_LEAST32_TYPE__)
#define __UINT_LEAST32_TYPE__ unsigned int
#endif
#if defined(__ICC) && !defined(__UINT_LEAST64_MAX__)
#define __UINT_LEAST64_MAX__ 18446744073709551615UL
#endif
#if defined(__ICC) && !defined(__UINT_LEAST64_TYPE__)
#define __UINT_LEAST64_TYPE__ unsigned long
#endif
#if defined(__ICC) && !defined(__UINT_LEAST8_MAX__)
#define __UINT_LEAST8_MAX__ 255
#endif
#if defined(__ICC) && !defined(__UINT_LEAST8_TYPE__)
#define __UINT_LEAST8_TYPE__ unsigned char
#endif
#if defined(__ICC) && !defined(__USER_LABEL_PREFIX__)
#define __USER_LABEL_PREFIX__
#endif
#if defined(__ICC) && !defined(__VERSION__)
#define __VERSION__ "Intel(R) C++ g++ 10.1 mode"
#endif
#if defined(__ICC) && !defined(__WCHAR_MAX__)
#define __WCHAR_MAX__ 2147483647
#endif
#if defined(__ICC) && !defined(__WCHAR_MIN__)
#define __WCHAR_MIN__ (-__WCHAR_MAX__ - 1)
#endif
#if defined(__ICC) && !defined(__WCHAR_TYPE__)
#define __WCHAR_TYPE__ int
#endif
#if defined(__ICC) && !defined(__WINT_MAX__)
#define __WINT_MAX__ 4294967295U
#endif
#if defined(__ICC) && !defined(__WINT_MIN__)
#define __WINT_MIN__ 0U
#endif
#if defined(__ICC) && !defined(__WINT_TYPE__)
#define __WINT_TYPE__ unsigned int
#endif
#ifndef __cilk
#define __cilk 200
#endif
#ifndef __tune_pentium4__
#define __tune_pentium4__ 1
#endif

#if defined(__ICC) && !defined(__gnu_linux__)
#define __gnu_linux__ 1
#endif
#if defined(__ICC) && !defined(__linux)
#define __linux 1
#endif
#if defined(__ICC) && !defined(__linux__)
#define __linux__ 1
#endif
#if defined(__ICC) && !defined(__unix)
#define __unix 1
#endif
#if defined(__ICC) && !defined(__unix__)
#define __unix__ 1
#endif
#if defined(__ICC) && !defined(linux)
#define linux 1
#endif
#if defined(__ICC) && !defined(unix)
#define unix 1
#endif


// Windows/ICL only macros
#if !defined(__ICC) && !defined(__w64)
#define __w64
#endif
#if !defined(__ICC) && !defined(_INTEGRAL_MAX_BITS)
#define _INTEGRAL_MAX_BITS 64
#endif
#if !defined(__ICC) && !defined(__INTEL_MS_COMPAT_LEVEL)
#define __INTEL_MS_COMPAT_LEVEL 1
#endif
#if !defined(__ICC) && !defined(_M_AMD64)
#define _M_AMD64 100
#endif
#if !defined(__ICC) && !defined(_M_X64)
#define _M_X64 100
#endif
#if !defined(__ICC) && !defined(_MSC_EXTENSIONS)
#define _MSC_EXTENSIONS 1
#endif
#if !defined(__ICC) && !defined(_MSC_FULL_VER)
#define _MSC_FULL_VER 192930137
#endif
#if !defined(__ICC) && !defined(_MSC_VER)
#define _MSC_VER 1929
#endif
#if !defined(__ICC) && !defined(_MSVC_TRADITIONAL)
#define _MSVC_TRADITIONAL 1
#endif
#if !defined(__ICC) && !defined(_MSVC_LANG) && defined(__cplusplus)
#define _MSVC_LANG 201402L
#endif
#if !defined(__ICC) && !defined(_MT)
#define _MT 1
#endif
#if !defined(__ICC) && !defined(_WIN32)
#define _WIN32 1
#endif
#if !defined(__ICC) && !defined(_WIN64)
#define _WIN64 1
#endif


#if !defined(__i386__)&&!defined(__i386)&&!defined(i386)&&!defined(__x86_64)&&!defined(__x86_64__)&&!defined(__amd64)&&!defined(__amd64__)&&!defined(__pentium4)&&!defined(__pentium4__)

#define __pentium4 1
#define __pentium4__ 1
#define __amd64 1
#define __amd64__ 1
#if defined(__ICC)
#define __x86_64 1
#define __x86_64__ 1
#endif
#endif

#define _exit _pst_exit
#define _Exit _pst_exit

#if defined(_WIN32)
#if defined(_exit)
#undef _exit
#else
#define _exit _pst_exit
#endif
#endif

#pragma tmw emit

#endif /* __TMW_COMPILER_INTEL__ && __TMW_TARGET_X86_64__ */

#endif /* _INTEL_H_ */

/* LocalWords:  GNUG ICL
 */
