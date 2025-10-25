/*
 * Copyright 2024 The MathWorks, Inc.
 */

#ifndef __TMW_GNU_BUILTIN_TYPES_ARM_NEON32_H__
#define __TMW_GNU_BUILTIN_TYPES_ARM_NEON32_H__

#pragma tmw no_emit
#pragma tmw code_instrumentation off
#pragma tmw push(builtins)

typedef __attribute__((neon_vector_type(4))) __bf16 __simd64_bfloat16_t;
typedef __attribute__((neon_vector_type(8))) __bf16 __simd128_bfloat16_t;
typedef __attribute__((neon_vector_type(4))) __fp16 __simd64_float16_t;
typedef __attribute__((neon_vector_type(8))) __fp16 __simd128_float16_t;
typedef __attribute__((neon_vector_type(2))) float  __simd64_float32_t;
typedef __attribute__((neon_vector_type(4))) float  __simd128_float32_t;

typedef __attribute__((neon_vector_type(8)))  signed char        __simd64_int8_t;
typedef __attribute__((neon_vector_type(16))) signed char        __simd128_int8_t;
typedef __attribute__((neon_vector_type(8)))  unsigned char      __simd64_uint8_t;
typedef __attribute__((neon_vector_type(16))) unsigned char      __simd128_uint8_t;
typedef __attribute__((neon_vector_type(4)))  short              __simd64_int16_t;
typedef __attribute__((neon_vector_type(8)))  short              __simd128_int16_t;
typedef __attribute__((neon_vector_type(4)))  unsigned short     __simd64_uint16_t;
typedef __attribute__((neon_vector_type(8)))  unsigned short     __simd128_uint16_t;
typedef __attribute__((neon_vector_type(2)))  int                __simd64_int32_t;
typedef __attribute__((neon_vector_type(4)))  int                __simd128_int32_t;
typedef __attribute__((neon_vector_type(2)))  unsigned int       __simd64_uint32_t;
typedef __attribute__((neon_vector_type(4)))  unsigned int       __simd128_uint32_t;
typedef __attribute__((neon_vector_type(1)))  long long          __simd64_int64_t;
typedef __attribute__((neon_vector_type(2)))  long long          __simd128_int64_t;
typedef __attribute__((neon_vector_type(1)))  unsigned long long __simd64_uint64_t;
typedef __attribute__((neon_vector_type(2)))  unsigned long long __simd128_uint64_t;

typedef __attribute__((neon_polyvector_type(8)))  signed char  __simd64_poly8_t;
typedef __attribute__((neon_polyvector_type(16))) signed char  __simd128_poly8_t;
typedef __attribute__((neon_polyvector_type(4)))  short        __simd64_poly16_t;
typedef __attribute__((neon_polyvector_type(8)))  short        __simd128_poly16_t;
typedef __attribute__((neon_polyvector_type(1)))  long long    __simd64_poly64_t;
typedef __attribute__((neon_polyvector_type(2)))  long long    __simd128_poly64_t;

#if defined(__GNUC__) && __GNUC__ >= 10
typedef __bf16 __builtin_neon_bf;
#elif defined(__GNUC__) && __GNUC__ < 6
typedef __bf16 __builtin_neon_hf; /* Except that gcc didn't have __bf before 10.0.0? */
#endif
typedef float              __builtin_neon_sf;
typedef double             __builtin_neon_df;
typedef signed char        __builtin_neon_qi;
typedef unsigned char      __builtin_neon_uqi;
typedef short              __builtin_neon_hi;
typedef unsigned short     __builtin_neon_uhi;
typedef int                __builtin_neon_si;
typedef unsigned int       __builtin_neon_usi;
typedef long long          __builtin_neon_di;
typedef unsigned long long __builtin_neon_udi;
typedef unsigned char      __builtin_neon_poly8;
typedef short              __builtin_neon_poly16;
typedef unsigned long long __builtin_neon_poly64;
typedef unsigned __int128  __builtin_neon_poly128;
typedef unsigned __int128  __builtin_neon_uti;

typedef __attribute__((neon_polyvector_type(2))) long long __builtin_neon_ti;
typedef __attribute__((neon_polyvector_type(3))) long long __builtin_neon_ei;
typedef __attribute__((neon_polyvector_type(4))) long long __builtin_neon_oi;
typedef __attribute__((neon_polyvector_type(6))) long long __builtin_neon_ci;
typedef __attribute__((neon_polyvector_type(8))) long long __builtin_neon_xi;

#pragma tmw pop(builtins)
#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* __TMW_GNU_BUILTIN_TYPES_ARM_NEON32_H__ */
