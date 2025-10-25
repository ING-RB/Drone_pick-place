/*
 * Copyright 2017-2022 The MathWorks, Inc.
 */

#ifndef _TI_BUILTINS_C28X_H_
#define _TI_BUILTINS_C28X_H_

#if defined(__TMW_COMPILER_TI__) && defined(__TMW_TARGET_C28X__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

#ifdef __cplusplus
extern "C" namespace std {
#endif
PST_LINK_C void* memcpy(void*, const void*, __SIZE_T_TYPE__);
PST_LINK_C void _nassert(int);
#ifdef __cplusplus
}
#endif

PST_LINK_C int __abs16_sat(int);
#ifndef __cplusplus
PST_LINK_C int abs(int);
PST_LINK_C long labs(long);
PST_LINK_C double fabs(double);
#endif
PST_LINK_C void __add(int*, int);
PST_LINK_C long __addcu(long, unsigned int);
PST_LINK_C void __addl(long*, long);
PST_LINK_C void __and(int*, int);
PST_LINK_C float __atan(float);
PST_LINK_C float __atan2(float, float);
PST_LINK_C float __atan2puf32(float, float);
PST_LINK_C float __atanpuf32(float);
PST_LINK_C int &__byte(int*, unsigned int);
PST_LINK_C unsigned long &__byte_peripheral_32(unsigned long*);
PST_LINK_C float __cos(float);
PST_LINK_C float __cospuf32(float);
PST_LINK_C void __dec(int*);
PST_LINK_C unsigned int __disable_interrupts(void);
PST_LINK_C unsigned int _disable_interrupts(void);
PST_LINK_C float __div2pif32(float);
PST_LINK_C float __divf32(float, float);
PST_LINK_C void __dmac(long, long, long&, long&, int);
PST_LINK_C void __eallow(void);
PST_LINK_C void __edis(void);
PST_LINK_C unsigned int __enable_interrupts(void);
PST_LINK_C unsigned int _enable_interrupts(void);
PST_LINK_C float __einvf32(float);
PST_LINK_C float __eisqrtf32(float);
#if defined __TI_COMPILER_VERSION__ && __TI_COMPILER_VERSION__ < 18000000
/* Not predeclared anymore in version 18 and higher */
PST_LINK_C long __euclidean_div_i32byu32(long, unsigned long, unsigned long&);
#endif
PST_LINK_C unsigned long __f32_bits_as_u32(float);
PST_LINK_C void __f32_max_idx(double&, double, double&, double);
PST_LINK_C void __f32_min_idx(double&, double, double&, double);
PST_LINK_C int __f32toi16r(float);
PST_LINK_C unsigned int __f32toui16r(float);
PST_LINK_C unsigned long long __f64_bits_as_u64(long double);
PST_LINK_C int __flip16(int);
PST_LINK_C long __flip32(long);
PST_LINK_C long long __flip64(long long);
PST_LINK_C float __fmax(float, float);
PST_LINK_C float __fmin(float, float);
PST_LINK_C float __fracf32(float);
PST_LINK_C float __fsat(float, float, float);
PST_LINK_C void __inc(int*);
PST_LINK_C long __IQ(long double, int);
PST_LINK_C long __IQmpy(long, long, int);
PST_LINK_C long __IQsat(long, long, long);
PST_LINK_C long __IQxmpy(long, long, int);
PST_LINK_C long long __llmax(long long, long long);
PST_LINK_C long long __llmin(long long, long long);
PST_LINK_C long __lmax(long, long);
PST_LINK_C long __lmin(long, long);
PST_LINK_C int __max(int, int);
PST_LINK_C int __min(int, int);
PST_LINK_C int __mov_byte(int*, unsigned int);
PST_LINK_C long __mpy(int, int);
PST_LINK_C float __mpy2pif32(float);
PST_LINK_C long __mpy_mov_t(int, int, int*);
PST_LINK_C long __mpyb(int, unsigned int);
PST_LINK_C unsigned long __mpyu(unsigned int, unsigned int);
PST_LINK_C long __mpyxu(int, unsigned int);
PST_LINK_C long __norm32(long, int*);
PST_LINK_C long long __norm64(long long, int*);
PST_LINK_C void __or(int*, int);
PST_LINK_C long __qmpy32(long, long, int);
PST_LINK_C long __qmpy32by16(long, int, int);
PST_LINK_C double __quadf32(double&, double, double);
PST_LINK_C void __restore_interrupts(unsigned int);
PST_LINK_C void _restore_interrupts(unsigned int);
PST_LINK_C long __rol(long);
PST_LINK_C long __ror(long);
PST_LINK_C void* __rpt_mov_imm(void*, int, int);
PST_LINK_C int __rpt_norm_dec(long, int, int);
PST_LINK_C int __rpt_norm_inc(long, int, int);
PST_LINK_C long __rpt_rol(long, int);
PST_LINK_C long __rpt_ror(long, int);
PST_LINK_C long __rpt_subcu(long, int, int);
PST_LINK_C unsigned long __rpt_subcul(unsigned long, unsigned long, unsigned long&, int);
PST_LINK_C long __sat(long);
PST_LINK_C long __sat32(long, long);
PST_LINK_C long __sathigh16(long, int);
PST_LINK_C long __satlow16(long);
PST_LINK_C long __sbbu(long, unsigned int);
PST_LINK_C float __sin(float);
PST_LINK_C float __sinpuf32(float);
#if __TI_COMPILER_VERSION__ < 17000000
PST_LINK_C double __sqrt(double);
#else
PST_LINK_C float __sqrt(float);
#endif
PST_LINK_C void __sub(int*, int);
PST_LINK_C long __subcu(long, int);
PST_LINK_C unsigned long __subcul(unsigned long, unsigned long, unsigned long&);
PST_LINK_C void __subl(long*, long);
PST_LINK_C void __subr(int*, int);
PST_LINK_C void __subrl(long*, long);
PST_LINK_C void __swapf(double&, double&);
PST_LINK_C void __swapff(float&, float&);
PST_LINK_C unsigned long _symval(const void*);
PST_LINK_C int __tbit(int, int bit);
PST_LINK_C float __u32_bits_as_f32(unsigned long);
PST_LINK_C long double __u64_bits_as_f64(unsigned long long);
PST_LINK_C void __xor(int*, int);

#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* #if defined(__TMW_COMPILER_TI__) && defined(__TMW_TARGET_C28X__) */

#endif /* _TI_BUILTINS_C28X_H_ */
