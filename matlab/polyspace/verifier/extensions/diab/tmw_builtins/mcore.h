/*
 * Copyright 2016-2022 The MathWorks, Inc.
 */

#ifndef _DIAB_BUILTINS_MCORE_H_
#define _DIAB_BUILTINS_MCORE_H_

#if defined(__TMW_COMPILER_DIAB__) && defined(__TMW_TARGET_MCORE__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

#ifdef __PST_POLYSPACE_MODE
PST_LINK_C void *__alloca(unsigned int);

#if defined(__TMW_DIAB_MCORE_INTRINSIC_MASK__) && (__TMW_DIAB_MCORE_INTRINSIC_MASK__ & 0x800000)

PST_LINK_C void *alloca(unsigned int);
#endif
#else /* __PST_POLYSPACE_MODE */
PST_LINK_C void *__alloca(int);
#if defined(__TMW_DIAB_MCORE_INTRINSIC_MASK__) && (__TMW_DIAB_MCORE_INTRINSIC_MASK__ & 0x800000)
PST_LINK_C void *alloca(int);
#endif
#endif /* __PST_POLYSPACE_MODE */

#if defined(__TMW_DIAB_MCORE_INTRINSIC_MASK__) && (__TMW_DIAB_MCORE_INTRINSIC_MASK__ & 0x400000)

/* __builtin_expect
   ----------------
   We provide an implementation for this function that allows Polyspace to fully analyze
   (no stub).
*/
#define __builtin_expect(exp,c) (exp)

#endif
#if defined(__TMW_DIAB_MCORE_INTRINSIC_MASK__) && (__TMW_DIAB_MCORE_INTRINSIC_MASK__ & 0x1)

PST_LINK_C unsigned int __ff0(unsigned int);
PST_LINK_C unsigned int __ff0l(unsigned int);
PST_LINK_C unsigned int __ff0ll(unsigned long long);
PST_LINK_C unsigned int __ff1(unsigned int);
PST_LINK_C unsigned int __ff1l(unsigned int);
PST_LINK_C unsigned int __ff1ll(unsigned long long);

#endif
#if defined(__TMW_DIAB_MCORE_INTRINSIC_MASK__) && (__TMW_DIAB_MCORE_INTRINSIC_MASK__ & 0x2)

PST_LINK_C unsigned int __brev(unsigned int);

#endif
#if defined(__TMW_DIAB_MCORE_INTRINSIC_MASK__) && (__TMW_DIAB_MCORE_INTRINSIC_MASK__ & 0x4)

PST_LINK_C unsigned int __tstnbz(unsigned int);

#endif
#if defined(__TMW_DIAB_MCORE_INTRINSIC_MASK__) && (__TMW_DIAB_MCORE_INTRINSIC_MASK__ & 0x8)

PST_LINK_C int abs(int);
PST_LINK_C long labs(long);

#endif


PST_LINK_C void __cprc(void);
PST_LINK_C int __cprcr(int);
PST_LINK_C int __cprgr(int);
PST_LINK_C int __cprsr(void);
PST_LINK_C void __cpseti(int);
PST_LINK_C void __cpwcr(int, int);
PST_LINK_C void __cpwgr(int, int);
PST_LINK_C void __cpwir(int);
PST_LINK_C void __cpwsr(int);
PST_LINK_C void __mac(int, int);
PST_LINK_C void __memory_barrier(void);
PST_LINK_C unsigned int __mfhi(void);
PST_LINK_C long long __mfhilo(void);
PST_LINK_C int __mfhis(void);
PST_LINK_C unsigned int __mflo(void);
PST_LINK_C unsigned int __mflos(void);
PST_LINK_C void __mthi(int);
PST_LINK_C void __mthilo(long long);
PST_LINK_C void __mtlo(int);
PST_LINK_C void __muls(int, int);
PST_LINK_C void __mulsa(int, int);
PST_LINK_C int __mulsh(int, int);
PST_LINK_C void __mulsha(short, short);
PST_LINK_C void __mulshs(short, short);
PST_LINK_C void __mulss(int, int);
PST_LINK_C int __mulsw(int, int);
PST_LINK_C void __mulswa(short, int);
PST_LINK_C int __mulsws(int, int);
PST_LINK_C unsigned char __mult(unsigned char, unsigned char);
PST_LINK_C unsigned char __mulu(unsigned char, unsigned char);
PST_LINK_C unsigned char __mulua(unsigned char, unsigned char);
PST_LINK_C unsigned char __mulus(unsigned char, unsigned char);
PST_LINK_C unsigned char __mulush(unsigned char, unsigned char);
PST_LINK_C void __mvtc(void);
PST_LINK_C void __omflip(int, int);
PST_LINK_C void __scheduling_barrier(void);
PST_LINK_C void __vmulsh(unsigned char, unsigned char);
PST_LINK_C void __vmulsha(int, int);
PST_LINK_C void __vmulshs(unsigned char, unsigned char);
PST_LINK_C void __vmulsw(unsigned char, unsigned char);
PST_LINK_C void __vmulswa(unsigned char, unsigned char);
PST_LINK_C void __vmulsws(unsigned char, unsigned char);

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

#endif /* __TMW_COMPILER_DIAB__ && __TMW_TARGET_MCORE__ */

#endif /* _DIAB_BUILTINS_MCORE_H_ */
