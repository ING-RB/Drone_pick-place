/*
 * Copyright 2016-2022 The MathWorks, Inc.
 */

#ifndef _DIAB_BUILTINS_RH850_H_
#define _DIAB_BUILTINS_RH850_H_

/*
   Intrinsic Functions, see Section 8.6 of the Wind River Diab for RH850 5.9 manual.
   This header only declares functions not declared in <diab>/include/diab/necasm.h
*/

#if defined(__TMW_COMPILER_DIAB__) && defined(__TMW_TARGET_RH850__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

#ifdef __PST_POLYSPACE_MODE

PST_LINK_C void *__alloca(unsigned int);
#if defined(__TMW_DIAB_RH850_INTRINSIC_MASK__) && (__TMW_DIAB_RH850_INTRINSIC_MASK__ & 0x800000)
PST_LINK_C void *alloca(unsigned int);
#endif

#else /* __PST_POLYSPACE_MODE */

PST_LINK_C void *__alloca(int);
#if defined(__TMW_DIAB_RH850_INTRINSIC_MASK__) && (__TMW_DIAB_RH850_INTRINSIC_MASK__ & 0x800000)
PST_LINK_C void *alloca(int);
#endif

#endif /* __PST_POLYSPACE_MODE */

#if defined(__TMW_DIAB_RH850_INTRINSIC_MASK__) && (__TMW_DIAB_RH850_INTRINSIC_MASK__ & 0x400000)

/* __builtin_expect
   ----------------
   We provide an implementation for this function that allows Polyspace to fully analyze
   (no stub).
*/
#define __builtin_expect(exp,c) (exp)

#endif

#ifndef __skip_ansi_vararg_prototypes
#ifndef __cplusplus
PST_LINK_C int printf(const char *, ...);
PST_LINK_C int scanf(const char *, ...);
PST_LINK_C int sprintf(char *, const char *, ...);
PST_LINK_C int sscanf(const char *, const char *, ...);
#endif /* __cplusplus */
#endif /* __skip_ansi_vararg_prototypes */

PST_LINK_C void *__diab__got__(signed char *, void *, float*);
PST_LINK_C unsigned int __ff0(unsigned int);
PST_LINK_C unsigned int __ff1(unsigned int);
PST_LINK_C unsigned int __ff1l(unsigned int);
PST_LINK_C void __memory_barrier(void);
PST_LINK_C void __scheduling_barrier(void);
PST_LINK_C void __wait(float*);


#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* __TMW_COMPILER_DIAB__ && __TMW_TARGET_RH850__ */

#endif /* _DIAB_BUILTINS_RH850_H_ */

