/*
 * Copyright 2016-2022 The MathWorks, Inc.
 */

#ifndef _DIAB_BUILTINS_ARM_H_
#define _DIAB_BUILTINS_ARM_H_

/*
   Intrinsic Functions, see Section 8.6 of the Wind River Diab for ARM 5.9 manual.
   This header only declares functions not declared in <diab>/include/diab/armasm.h
*/

#if defined(__TMW_COMPILER_DIAB__) && defined(__TMW_TARGET_ARM__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

#ifdef __PST_POLYSPACE_MODE
PST_LINK_C void *__alloca(unsigned int);
#if defined(__TMW_DIAB_ARM_INTRINSIC_MASK__) && (__TMW_DIAB_ARM_INTRINSIC_MASK__ & 0x800000)
PST_LINK_C void *alloca(unsigned int);
#endif
#else /* __PST_POLYSPACE_MODE */
PST_LINK_C void *__alloca(int);
#if defined(__TMW_DIAB_ARM_INTRINSIC_MASK__) && (__TMW_DIAB_ARM_INTRINSIC_MASK__ & 0x800000)
PST_LINK_C void *alloca(int);
#endif
#endif /* __PST_POLYSPACE_MODE */

#if defined(__TMW_DIAB_ARM_INTRINSIC_MASK__) && (__TMW_DIAB_ARM_INTRINSIC_MASK__ & 0x400000)

/* __builtin_expect
   ----------------
   We provide an implementation for this function that allows Polyspace to fully analyze
   (no stub).
*/
#define __builtin_expect(exp,c) (exp)

#endif

/*
   For the functions under masks 0x10 and 0x11, the manual notes the following:
   - Functions taking long long arguments first sign-extend their arguments to 64 bits.
   - These functions are not prototyped and return a 32-bit int (or void) by default, 
     except that functions taking a long long argument return long long (or void). 
     A prototype may be used to define a different return type.
*/
#if defined(__TMW_DIAB_ARM_INTRINSIC_MASK__) && (__TMW_DIAB_ARM_INTRINSIC_MASK__ & 0x10)


PST_LINK_C unsigned int __ff1(unsigned int);
PST_LINK_C unsigned int __ff1ll(unsigned long long);
PST_LINK_C void *__diab_tls_addr_gd(void *);
PST_LINK_C void *__diab_tls_addr_ie(signed char *, void *);
PST_LINK_C void *__diab_tls_addr_le(void *);
PST_LINK_C void *__diab__got__(signed char *, void *);
PST_LINK_C void *__tls_varp(void *);


PST_LINK_C unsigned int __qadd(unsigned int, unsigned int);
PST_LINK_C unsigned int __qdadd(unsigned int, unsigned int);
PST_LINK_C unsigned int __qdsub(unsigned int, unsigned int);
PST_LINK_C unsigned int __qsub(unsigned int, unsigned int);
PST_LINK_C unsigned long long __mra(void);
PST_LINK_C unsigned int __smlabb(unsigned int, unsigned int, unsigned int);
PST_LINK_C unsigned int __smlabt(unsigned int, unsigned int, unsigned int);
PST_LINK_C unsigned long long __smlalbb(unsigned long long, unsigned int, unsigned int);
PST_LINK_C unsigned long long __smlalbt(unsigned long long, unsigned int, unsigned int);
PST_LINK_C unsigned long long __smlaltb(unsigned long long, unsigned int, unsigned int);
PST_LINK_C unsigned long long __smlaltt(unsigned long long, unsigned int, unsigned int);
PST_LINK_C unsigned int __smlatb(unsigned int, unsigned int, unsigned int);
PST_LINK_C unsigned int __smlatt(unsigned int, unsigned int, unsigned int);
PST_LINK_C unsigned int __smlawb(unsigned int, unsigned int, unsigned int);
PST_LINK_C unsigned int __smlawt(unsigned int, unsigned int, unsigned int);
PST_LINK_C unsigned int __smulbb(unsigned int, unsigned int);
PST_LINK_C unsigned int __smulbt(unsigned int, unsigned int);
PST_LINK_C unsigned int __smultb(unsigned int, unsigned int);
PST_LINK_C unsigned int __smultt(unsigned int, unsigned int);
PST_LINK_C unsigned int __smulwb(unsigned int, unsigned int);
PST_LINK_C unsigned int __smulwt(unsigned int, unsigned int);

#endif
#if defined(__TMW_DIAB_ARM_INTRINSIC_MASK__) && (__TMW_DIAB_ARM_INTRINSIC_MASK__ & 0x11)

PST_LINK_C void __mar(unsigned long long);
PST_LINK_C void __mia(unsigned int, unsigned int);
PST_LINK_C void __miabb(unsigned int, unsigned int);
PST_LINK_C void __miabt(unsigned int, unsigned int);
PST_LINK_C void __miaph(unsigned int, unsigned int);
PST_LINK_C void __miatb(unsigned int, unsigned int);
PST_LINK_C void __miatt(unsigned int, unsigned int);

#endif

#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* __TMW_COMPILER_DIAB__ && __TMW_TARGET_ARM__ */

#endif /* _DIAB_BUILTINS_ARM_H_ */
