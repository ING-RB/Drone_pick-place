/*
 * Copyright 2016-2022 The MathWorks, Inc.
 */

#ifndef _DIAB_BUILTINS_POWERPC64_H_
#define _DIAB_BUILTINS_POWERPC64_H_

/*
   Intrinsic Functions, see Section 8.6 of the Wind River Diab for PowerPC 5.9 manual.
   This header only declares functions not declared in <diab>/include/diab/ppcasm.h
*/

#if defined(__TMW_COMPILER_DIAB__) && defined(__TMW_TARGET_POWERPC64__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

#ifdef __PST_POLYSPACE_MODE

PST_LINK_C void *__alloca(unsigned long);
#if defined(__TMW_DIAB_POWERPC64_INTRINSIC_MASK__) && (__TMW_DIAB_POWERPC64_INTRINSIC_MASK__ & 0x800000)
PST_LINK_C void *alloca(unsigned long);
#endif

#else /* __PST_POLYSPACE_MODE */

PST_LINK_C void *__alloca(int);
#if defined(__TMW_DIAB_POWERPC64_INTRINSIC_MASK__) && (__TMW_DIAB_POWERPC64_INTRINSIC_MASK__ & 0x800000)
PST_LINK_C void *alloca(int);
#endif

#endif /* __PST_POLYSPACE_MODE */

#if defined(__TMW_DIAB_POWERPC64_INTRINSIC_MASK__) && (__TMW_DIAB_POWERPC64_INTRINSIC_MASK__ & 0x400000)
/* __builtin_expect
   ----------------
   We provide an implementation for this function that allows Polyspace to fully analyze
   (no stub).
*/
#define __builtin_expect(exp,c) (exp)

/* __builtin_prefetch
   ------------------
   We provide an implementation for this function that allows Polyspace to fully analyze
   (no stub).
*/
#define __builtin_prefetch(...) do{}while(0)
#endif

#if defined(__TMW_DIAB_POWERPC64_INTRINSIC_MASK__) && (__TMW_DIAB_POWERPC64_INTRINSIC_MASK__ & 0x1)
PST_LINK_C unsigned int __ff0(unsigned int);
PST_LINK_C unsigned int __ff0l(unsigned int);
PST_LINK_C unsigned int __ff0ll(unsigned long long);
PST_LINK_C unsigned int __ff1(unsigned int);
PST_LINK_C unsigned int __ff1l(unsigned int);
PST_LINK_C unsigned int __ff1ll(unsigned long long);
#endif

#if defined(__TMW_DIAB_POWERPC64_INTRINSIC_MASK__) && (__TMW_DIAB_POWERPC64_INTRINSIC_MASK__ & 0x2)
PST_LINK_C unsigned int __fpscr(void);
#endif

#ifndef __skip_ansi_vararg_prototypes
#ifndef __cplusplus
extern int printf(const char *, ...);
extern int scanf(const char *, ...);
extern int sprintf(char *, const char *, ...);
extern int sscanf(const char *, const char *, ...);
#endif /* __cplusplus */
#endif /* __skip_ansi_vararg_prototypes */

PST_LINK_C void*__adjustvleretaddress(unsigned int);
PST_LINK_C void *__diab__got__(signed char *, void *);
PST_LINK_C void*__diab_memcpy(void*, void*, unsigned int, unsigned int);
PST_LINK_C void*__diab_memset(void*, int, unsigned int, unsigned int);
PST_LINK_C void *__diab_tls_addr_gd(void *);
PST_LINK_C void *__diab_tls_addr_ie(signed char *, void *);
PST_LINK_C void *__diab_tls_addr_le(void *);
PST_LINK_C int __ev_get_spefscr_fdbz(void);
PST_LINK_C int __ev_get_spefscr_fdbze(void);
PST_LINK_C int __ev_get_spefscr_fdbzh(void);
PST_LINK_C int __ev_get_spefscr_fdbzs(void);
PST_LINK_C int __ev_get_spefscr_fg(void);
PST_LINK_C int __ev_get_spefscr_fgh(void);
PST_LINK_C int __ev_get_spefscr_finv(void);
PST_LINK_C int __ev_get_spefscr_finve(void);
PST_LINK_C int __ev_get_spefscr_finvh(void);
PST_LINK_C int __ev_get_spefscr_finvs(void);
PST_LINK_C int __ev_get_spefscr_finxe(void);
PST_LINK_C int __ev_get_spefscr_finxs(void);
PST_LINK_C int __ev_get_spefscr_fovf(void);
PST_LINK_C int __ev_get_spefscr_fovfe(void);
PST_LINK_C int __ev_get_spefscr_fovfh(void);
PST_LINK_C int __ev_get_spefscr_fovfs(void);
PST_LINK_C int __ev_get_spefscr_frmc(void);
PST_LINK_C int __ev_get_spefscr_funf(void);
PST_LINK_C int __ev_get_spefscr_funfe(void);
PST_LINK_C int __ev_get_spefscr_funfh(void);
PST_LINK_C int __ev_get_spefscr_funfs(void);
PST_LINK_C int __ev_get_spefscr_fx(void);
PST_LINK_C int __ev_get_spefscr_fxh(void);
PST_LINK_C int __ev_get_spefscr_mode(void);
PST_LINK_C int __ev_get_spefscr_ov(void);
PST_LINK_C int __ev_get_spefscr_ovh(void);
PST_LINK_C int __ev_get_spefscr_sov(void);
PST_LINK_C int __ev_get_spefscr_sovh(void);
PST_LINK_C void __ev_clr_spefscr_fdbzs(void);
PST_LINK_C void __ev_clr_spefscr_finvs(void);
PST_LINK_C void __ev_clr_spefscr_finxs(void);
PST_LINK_C void __ev_clr_spefscr_fovfs(void);
PST_LINK_C void __ev_clr_spefscr_funfs(void);
PST_LINK_C void __ev_clr_spefscr_sov(void);
PST_LINK_C void __ev_clr_spefscr_sovh(void);
PST_LINK_C double __fabs(double);
PST_LINK_C double __fabsd(double);
PST_LINK_C float __fabsf(float);
PST_LINK_C void *__tls_varp(void *);
PST_LINK_C unsigned int __fpscr(void);

PST_LINK_C long long __ev_convert_s64(__ev64_opaque__);
PST_LINK_C unsigned long long __ev_convert_u64(__ev64_opaque__);
PST_LINK_C __ev64_opaque__ __ev_create_fs(float, float);
PST_LINK_C __ev64_opaque__ __ev_create_s16(short, short, short, short);
PST_LINK_C __ev64_opaque__ __ev_create_s32(int, int);
PST_LINK_C __ev64_opaque__ __ev_create_s64(long long);
PST_LINK_C __ev64_opaque__ __ev_create_sfix32_fs(float, float);
PST_LINK_C __ev64_opaque__ __ev_create_sfix32_s32(int, int);
PST_LINK_C __ev64_opaque__ __ev_create_u16(unsigned short, unsigned short, unsigned short, unsigned short);
PST_LINK_C __ev64_opaque__ __ev_create_u32(unsigned int, unsigned int);
PST_LINK_C __ev64_opaque__ __ev_create_u64(unsigned long long);
PST_LINK_C __ev64_opaque__ __ev_create_ufix32_fs(float, float);
PST_LINK_C __ev64_opaque__ __ev_create_ufix32_u32(unsigned int, unsigned int);
PST_LINK_C float __ev_get_fs(__ev64_opaque__, int);
PST_LINK_C float __ev_get_lower_fs(__ev64_opaque__);
PST_LINK_C int __ev_get_lower_s32(__ev64_opaque__);
PST_LINK_C float __ev_get_lower_sfix32_fs(__ev64_opaque__);
PST_LINK_C int __ev_get_lower_sfix32_s32(__ev64_opaque__);
PST_LINK_C unsigned int __ev_get_lower_u32(__ev64_opaque__);
PST_LINK_C float __ev_get_lower_ufix32_fs(__ev64_opaque__);
PST_LINK_C unsigned int __ev_get_lower_ufix32_u32(__ev64_opaque__);
PST_LINK_C int __ev_get_s32(__ev64_opaque__, int);
PST_LINK_C float __ev_get_sfix32_fs(__ev64_opaque__, int);
PST_LINK_C int __ev_get_sfix32_s32(__ev64_opaque__, int);
PST_LINK_C unsigned int __ev_get_u32(__ev64_opaque__, int);
PST_LINK_C float __ev_get_ufix32_fs(__ev64_opaque__, int);
PST_LINK_C unsigned int __ev_get_ufix32_u32(__ev64_opaque__, int);
PST_LINK_C float __ev_get_upper_fs(__ev64_opaque__);
PST_LINK_C int __ev_get_upper_s32(__ev64_opaque__);
PST_LINK_C float __ev_get_upper_sfix32_fs(__ev64_opaque__);
PST_LINK_C int __ev_get_upper_sfix32_s32(__ev64_opaque__);
PST_LINK_C unsigned int __ev_get_upper_u32(__ev64_opaque__);
PST_LINK_C float __ev_get_upper_ufix32_fs(__ev64_opaque__);
PST_LINK_C unsigned int __ev_get_upper_ufix32_u32(__ev64_opaque__);
PST_LINK_C __ev64_opaque__ __ev_set_acc_s64(long long);
PST_LINK_C __ev64_opaque__ __ev_set_acc_u64(unsigned long long);
PST_LINK_C __ev64_opaque__ __ev_set_acc_vec64(__ev64_opaque__);
PST_LINK_C __ev64_opaque__ __ev_set_fs(__ev64_opaque__, float, int);
PST_LINK_C __ev64_opaque__ __ev_set_lower_fs(__ev64_opaque__, float);
PST_LINK_C __ev64_opaque__ __ev_set_lower_sfix32_fs(__ev64_opaque__, float);
PST_LINK_C __ev64_opaque__ __ev_set_lower_ufix32_fs(__ev64_opaque__, float);
PST_LINK_C __ev64_opaque__ __ev_set_s32(__ev64_opaque__, int, int);
PST_LINK_C __ev64_opaque__ __ev_set_sfix32_fs(__ev64_opaque__, float, int);
PST_LINK_C __ev64_opaque__ __ev_set_sfix32_s32(__ev64_opaque__, int, int);
PST_LINK_C void __ev_set_spefscr_frmc(unsigned int);
PST_LINK_C __ev64_opaque__ __ev_set_u32(__ev64_opaque__, int, int);
PST_LINK_C __ev64_opaque__ __ev_set_ufix32_fs(__ev64_opaque__, float, int);
PST_LINK_C __ev64_opaque__ __ev_set_ufix32_u32(__ev64_opaque__, int, int);
PST_LINK_C __ev64_opaque__ __ev_set_upper_fs(__ev64_opaque__, float);
PST_LINK_C __ev64_opaque__ __ev_set_upper_sfix32_fs(__ev64_opaque__, float);
PST_LINK_C __ev64_opaque__ __ev_set_upper_ufix32_fs(__ev64_opaque__, float);
PST_LINK_C void *__diab__got__(signed char *, void *);
PST_LINK_C void *__diab_tls_addr_gd(void *);
PST_LINK_C void *__diab_tls_addr_ie(signed char *, void *);
PST_LINK_C void *__diab_tls_addr_le(void *);
PST_LINK_C void *__tls_varp(void *);

#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* __TMW_COMPILER_DIAB__ && __TMW_TARGET_POWERPC64__ */

#endif /* _DIAB_BUILTINS_POWERPC64_H_ */
