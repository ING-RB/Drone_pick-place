/*
 * Copyright 2016-2022 The MathWorks, Inc.
 */

#ifndef _DIAB_BUILTINS_SUPERH_H_
#define _DIAB_BUILTINS_SUPERH_H_

#if defined(__TMW_COMPILER_DIAB__) && defined(__TMW_TARGET_SUPERH__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

#ifdef __PST_POLYSPACE_MODE
PST_LINK_C void *__alloca(unsigned int);
#if defined(__TMW_DIAB_SUPERH_INTRINSIC_MASK__) && (__TMW_DIAB_SUPERH_INTRINSIC_MASK__ & 0x800000)
PST_LINK_C void *alloca(unsigned int);
#endif
#else /* __PST_POLYSPACE_MODE */
PST_LINK_C void *__alloca(int);
#if defined(__TMW_DIAB_SUPERH_INTRINSIC_MASK__) && (__TMW_DIAB_SUPERH_INTRINSIC_MASK__ & 0x800000)
PST_LINK_C void *alloca(int);
#endif
#endif /* __PST_POLYSPACE_MODE */

#if defined(__TMW_DIAB_SUPERH_INTRINSIC_MASK__) && (__TMW_DIAB_SUPERH_INTRINSIC_MASK__ & 0x400000)

/* __builtin_expect
   ----------------
   We provide an implementation for this function that allows Polyspace to fully analyze
   (no stub).
*/
#define __builtin_expect(exp,c) (exp)

#endif
#if defined(__TMW_DIAB_SUPERH_INTRINSIC_MASK__) && (__TMW_DIAB_SUPERH_INTRINSIC_MASK__ & 0x1)

/*
   The manual notes the following:
   - These functions are not prototyped. Functions taking a __fixed argument
     return __fixed by default; other functions return int (32 bits). A prototype may
     be used to define a different return type.
*/
#ifndef __cplusplus
PST_LINK_C __fixed __pabs(__fixed);
PST_LINK_C __fixed __paddc(__fixed, __fixed);
PST_LINK_C __fixed __pdmsb(__fixed);
PST_LINK_C __fixed __plds(__fixed);
PST_LINK_C __fixed __prnd(__fixed);
PST_LINK_C __fixed __pshl(__fixed, int);
PST_LINK_C __fixed __psts(void);
PST_LINK_C __fixed __psubc(__fixed, __fixed);
#endif

PST_LINK_C int __swapb(int);
PST_LINK_C int __swapw(int);
PST_LINK_C int __xtrct(__fixed);

#endif

PST_LINK_C unsigned int __ff0(unsigned int);
PST_LINK_C unsigned int __ff0ll(unsigned long long);
PST_LINK_C unsigned int __ff1(unsigned int);
PST_LINK_C unsigned int __ff1l(unsigned int);
PST_LINK_C unsigned int __ff1ll(unsigned long long);
PST_LINK_C float __pabs(float);
PST_LINK_C void __wait(void);

PST_LINK_C void *__diab__got__(signed char *, void *);
PST_LINK_C void __memory_barrier(void);
PST_LINK_C float __paddc(float, float);
PST_LINK_C float __pclr(void);
PST_LINK_C float __pdmsb(float);
PST_LINK_C float __plds(float);
PST_LINK_C float __prnd(float);
PST_LINK_C float __pshl(float, int);
PST_LINK_C float __psts(void);
PST_LINK_C float __psubc(float, float);
PST_LINK_C void __scheduling_barrier(void);
PST_LINK_C void *__tls_varp(void *);


#ifndef __skip_ansi_vararg_prototypes
#ifndef __cplusplus
PST_LINK_C int printf(const char *, ...);
PST_LINK_C int scanf(const char *, ...);
PST_LINK_C int sprintf(char *, const char *, ...);
PST_LINK_C int sscanf(const char *, const char *, ...);
#endif /* __cplusplus */
#endif /* __skip_ansi_vararg_prototypes */

#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* __TMW_COMPILER_DIAB__ && __TMW_TARGET_SUPERH__ */

#endif /* _DIAB_BUILTINS_SUPERH_H_ */
