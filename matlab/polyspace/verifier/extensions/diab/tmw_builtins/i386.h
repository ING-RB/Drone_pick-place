/*
 * Copyright 2016-2022 The MathWorks, Inc.
 */

#ifndef _DIAB_BUILTINS_I386_H_
#define _DIAB_BUILTINS_I386_H_

#if defined(__TMW_COMPILER_DIAB__) && defined(__TMW_TARGET_I386__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

#ifdef __PST_POLYSPACE_MODE

PST_LINK_C void *__alloca(unsigned int);
#if defined(__TMW_DIAB_I386_INTRINSIC_MASK__) && (__TMW_DIAB_I386_INTRINSIC_MASK__ & 0x800000)
PST_LINK_C void *alloca(unsigned int);
#endif

#else /* __PST_POLYSPACE_MODE */

PST_LINK_C void *__alloca(int);
#if defined(__TMW_DIAB_I386_INTRINSIC_MASK__) && (__TMW_DIAB_I386_INTRINSIC_MASK__ & 0x800000)
PST_LINK_C void *alloca(int);
#endif

#endif /* __PST_POLYSPACE_MODE */

#if defined(__TMW_DIAB_I386_INTRINSIC_MASK__) && (__TMW_DIAB_I386_INTRINSIC_MASK__ & 0x400000)

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

PST_LINK_C void *__diab__got__(signed char *, void *);
PST_LINK_C void __memory_barrier(void);
PST_LINK_C void __scheduling_barrier(void);
PST_LINK_C void *__tls_varp(void *);
PST_LINK_C signed char *__va_stkaddr_of_cls(void *);


#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* __TMW_COMPILER_DIAB__ && __TMW_TARGET_I386__ */

#endif /* _DIAB_BUILTINS_I386_H_ */

