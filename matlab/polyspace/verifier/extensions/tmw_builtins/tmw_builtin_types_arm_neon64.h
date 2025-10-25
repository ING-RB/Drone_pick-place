/*
 * Copyright 2024 The MathWorks, Inc.
 */

#ifndef __TMW_GNU_BUILTIN_TYPES_ARM_NEON64_H__
#define __TMW_GNU_BUILTIN_TYPES_ARM_NEON64_H__

#pragma tmw no_emit
#pragma tmw code_instrumentation off
#pragma tmw push(builtins)

#ifdef __TMW_HAS_BF16__
typedef __attribute__((neon_vector_type(4))) __bf16 __Bfloat16x4_t;
typedef __attribute__((neon_vector_type(8))) __bf16 __Bfloat16x8_t;
#endif
#ifdef __TMW_HAS_FP16__
typedef __attribute__((neon_vector_type(4))) __fp16 __Float16x4_t;
typedef __attribute__((neon_vector_type(8))) __fp16 __Float16x8_t;
#endif
typedef __attribute__((neon_vector_type(2))) float  __Float32x2_t;
typedef __attribute__((neon_vector_type(4))) float  __Float32x4_t;
typedef __attribute__((neon_vector_type(1))) double __Float64x1_t;
typedef __attribute__((neon_vector_type(2))) double __Float64x2_t;

typedef __attribute__((neon_vector_type(8)))  signed char    __Int8x8_t;
typedef __attribute__((neon_vector_type(16))) signed char    __Int8x16_t;
typedef __attribute__((neon_vector_type(8)))  unsigned char  __Uint8x8_t;
typedef __attribute__((neon_vector_type(16))) unsigned char  __Uint8x16_t;
typedef __attribute__((neon_vector_type(4)))  short          __Int16x4_t;
typedef __attribute__((neon_vector_type(8)))  short          __Int16x8_t;
typedef __attribute__((neon_vector_type(4)))  unsigned short __Uint16x4_t;
typedef __attribute__((neon_vector_type(8)))  unsigned short __Uint16x8_t;
typedef __attribute__((neon_vector_type(2)))  int            __Int32x2_t;
typedef __attribute__((neon_vector_type(4)))  int            __Int32x4_t;
typedef __attribute__((neon_vector_type(2)))  unsigned int   __Uint32x2_t;
typedef __attribute__((neon_vector_type(4)))  unsigned int   __Uint32x4_t;
typedef __attribute__((neon_vector_type(1)))  long           __Int64x1_t;
typedef __attribute__((neon_vector_type(2)))  long           __Int64x2_t;
typedef __attribute__((neon_vector_type(1)))  unsigned long  __Uint64x1_t;
typedef __attribute__((neon_vector_type(2)))  unsigned long  __Uint64x2_t;

typedef __attribute__((neon_polyvector_type(8)))  unsigned char  __Poly8x8_t;
typedef __attribute__((neon_polyvector_type(16))) unsigned char  __Poly8x16_t;
typedef __attribute__((neon_polyvector_type(4)))  unsigned short __Poly16x4_t;
typedef __attribute__((neon_polyvector_type(8)))  unsigned short __Poly16x8_t;
typedef __attribute__((neon_polyvector_type(1)))  unsigned long  __Poly64x1_t;
typedef __attribute__((neon_polyvector_type(2)))  unsigned long  __Poly64x2_t;

typedef unsigned char     __Poly8_t;
typedef unsigned short    __Poly16_t;
typedef unsigned long     __Poly64_t;
typedef unsigned __int128 __Poly128_t;

/* EDG < 6.7 does not support scalable types. Map them to neon_polyvector_type. */
typedef __attribute__((neon_polyvector_type(1)))  signed char  __SVInt8_t;
typedef __attribute__((neon_polyvector_type(2)))  signed char  __clang_svint8x2_t;
typedef __attribute__((neon_polyvector_type(3)))  signed char  __clang_svint8x3_t;
typedef __attribute__((neon_polyvector_type(4)))  signed char  __clang_svint8x4_t;

typedef __attribute__((neon_polyvector_type(1)))  unsigned char  __SVUInt8_t;
typedef __attribute__((neon_polyvector_type(2)))  unsigned char  __clang_svuint8x2_t;
typedef __attribute__((neon_polyvector_type(3)))  unsigned char  __clang_svuint8x3_t;
typedef __attribute__((neon_polyvector_type(4)))  unsigned char  __clang_svuint8x4_t;

typedef __attribute__((neon_polyvector_type(1)))  short  __SVInt16_t;
typedef __attribute__((neon_polyvector_type(2)))  short  __clang_svint16x2_t;
typedef __attribute__((neon_polyvector_type(3)))  short  __clang_svint16x3_t;
typedef __attribute__((neon_polyvector_type(4)))  short  __clang_svint16x4_t;

typedef __attribute__((neon_polyvector_type(1)))  unsigned short  __SVUInt16_t;
typedef __attribute__((neon_polyvector_type(2)))  unsigned short  __clang_svuint16x2_t;
typedef __attribute__((neon_polyvector_type(3)))  unsigned short  __clang_svuint16x3_t;
typedef __attribute__((neon_polyvector_type(4)))  unsigned short  __clang_svuint16x4_t;

typedef __attribute__((neon_polyvector_type(1)))  int  __SVInt32_t;
typedef __attribute__((neon_polyvector_type(2)))  int  __clang_svint32x2_t;
typedef __attribute__((neon_polyvector_type(3)))  int  __clang_svint32x3_t;
typedef __attribute__((neon_polyvector_type(4)))  int  __clang_svint32x4_t;

typedef __attribute__((neon_polyvector_type(1)))  unsigned int  __SVUInt32_t;
typedef __attribute__((neon_polyvector_type(2)))  unsigned int  __clang_svuint32x2_t;
typedef __attribute__((neon_polyvector_type(3)))  unsigned int  __clang_svuint32x3_t;
typedef __attribute__((neon_polyvector_type(4)))  unsigned int  __clang_svuint32x4_t;

typedef __attribute__((neon_polyvector_type(1)))  long  __SVInt64_t;
typedef __attribute__((neon_polyvector_type(2)))  long  __clang_svint64x2_t;
typedef __attribute__((neon_polyvector_type(3)))  long  __clang_svint64x3_t;
typedef __attribute__((neon_polyvector_type(4)))  long  __clang_svint64x4_t;

typedef __attribute__((neon_polyvector_type(1)))  unsigned long  __SVUInt64_t;
typedef __attribute__((neon_polyvector_type(2)))  unsigned long  __clang_svuint64x2_t;
typedef __attribute__((neon_polyvector_type(3)))  unsigned long  __clang_svuint64x3_t;
typedef __attribute__((neon_polyvector_type(4)))  unsigned long  __clang_svuint64x4_t;

#ifdef __TMW_HAS_FP16__
typedef __attribute__((neon_polyvector_type(1)))  __fp16  __SVFloat16_t;
typedef __attribute__((neon_polyvector_type(2)))  __fp16  __clang_svfloat16x2_t;
typedef __attribute__((neon_polyvector_type(3)))  __fp16  __clang_svfloat16x3_t;
typedef __attribute__((neon_polyvector_type(4)))  __fp16  __clang_svfloat16x4_t;
#endif

#ifdef __TMW_HAS_BF16__
#if defined(__clang_major__) && __clang_major__ < 18
typedef __attribute__((neon_polyvector_type(1)))  __bf16  __SVBFloat16_t;
#else
typedef __attribute__((neon_polyvector_type(1)))  __bf16  __SVBfloat16_t;
#endif
typedef __attribute__((neon_polyvector_type(2)))  __bf16  __clang_svbfloat16x2_t;
typedef __attribute__((neon_polyvector_type(3)))  __bf16  __clang_svbfloat16x3_t;
typedef __attribute__((neon_polyvector_type(4)))  __bf16  __clang_svbfloat16x4_t;
#endif

typedef __attribute__((neon_polyvector_type(1)))  float  __SVFloat32_t;
typedef __attribute__((neon_polyvector_type(2)))  float  __clang_svfloat32x2_t;
typedef __attribute__((neon_polyvector_type(3)))  float  __clang_svfloat32x3_t;
typedef __attribute__((neon_polyvector_type(4)))  float  __clang_svfloat32x4_t;

typedef __attribute__((neon_polyvector_type(1)))  double  __SVFloat64_t;
typedef __attribute__((neon_polyvector_type(2)))  double  __clang_svfloat64x2_t;
typedef __attribute__((neon_polyvector_type(3)))  double  __clang_svfloat64x3_t;
typedef __attribute__((neon_polyvector_type(4)))  double  __clang_svfloat64x4_t;

#ifdef __cplusplus
#define TMW_BOOL bool
#elif defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901
#define TMW_BOOL _Bool
#else
#define TMW_BOOL int
#endif

typedef __attribute__((neon_polyvector_type(1)))  TMW_BOOL  __SVBool_t;
#if defined(__clang_major__) && __clang_major__ >= 17
typedef __attribute__((neon_polyvector_type(2)))  TMW_BOOL  __clang_svboolx2_t;
typedef __attribute__((neon_polyvector_type(4)))  TMW_BOOL  __clang_svboolx4_t;

#undef TMW_BOOL

/* EDG < 6.7 does not support scalable types. Map them to neon_polyvector_type. */
typedef __attribute__((neon_polyvector_type(1)))  int  __SVCount_t;
#endif

#if defined(__GNUC__) && __GNUC__ >= 10
typedef __bf16            __builtin_aarch64_simd_bf;
#endif
#if defined(__GNUC__) && __GNUC__ >= 6
typedef __fp16            __builtin_aarch64_simd_hf;
#endif
typedef float             __builtin_aarch64_simd_sf;
typedef double            __builtin_aarch64_simd_df;
typedef signed char       __builtin_aarch64_simd_qi;
typedef unsigned char     __builtin_aarch64_simd_uqi;
typedef short             __builtin_aarch64_simd_hi;
typedef unsigned short    __builtin_aarch64_simd_uhi;
typedef int               __builtin_aarch64_simd_si;
typedef unsigned          __builtin_aarch64_simd_usi;
typedef long              __builtin_aarch64_simd_di;
typedef unsigned long     __builtin_aarch64_simd_udi;
typedef unsigned char     __builtin_aarch64_simd_poly8;
typedef unsigned short    __builtin_aarch64_simd_poly16;
typedef unsigned long     __builtin_aarch64_simd_poly64;
typedef unsigned __int128 __builtin_aarch64_simd_poly128;
typedef __int128          __builtin_aarch64_simd_ti;

typedef __attribute__((neon_polyvector_type(2))) __int128 __builtin_aarch64_simd_oi;
typedef __attribute__((neon_polyvector_type(3))) __int128 __builtin_aarch64_simd_ci;
typedef __attribute__((neon_polyvector_type(4))) __int128 __builtin_aarch64_simd_xi;

#pragma tmw pop(builtins)
#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* __TMW_GNU_BUILTIN_TYPES_ARM_NEON64_H__ */
