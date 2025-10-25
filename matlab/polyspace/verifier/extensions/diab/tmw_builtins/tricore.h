/*
 * Copyright 2016-2022 The MathWorks, Inc.
 */

#ifndef _DIAB_BUILTINS_TRICORE_H_
#define _DIAB_BUILTINS_TRICORE_H_

/*
   Intrinsic Functions, see Section 8.6 of the Wind River Diab for Tricore 5.9 manual.
   This header only declares functions not declared in <diab>/include/diab/tcasm.h
*/

#if defined(__TMW_COMPILER_DIAB__) && defined(__TMW_TARGET_TRICORE__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

#ifdef __PST_POLYSPACE_MODE

PST_LINK_C void *__alloca(unsigned int);
#if defined(__TMW_DIAB_TRICORE_INTRINSIC_MASK__) && (__TMW_DIAB_TRICORE_INTRINSIC_MASK__ & 0x800000)
PST_LINK_C void *alloca(unsigned int);
#endif

#else /* __PST_POLYSPACE_MODE */

PST_LINK_C void *__alloca(int);
#if defined(__TMW_DIAB_TRICORE_INTRINSIC_MASK__) && (__TMW_DIAB_TRICORE_INTRINSIC_MASK__ & 0x800000)
PST_LINK_C void *alloca(int);
#endif

#endif /* __PST_POLYSPACE_MODE */


#if defined(__TMW_DIAB_TRICORE_INTRINSIC_MASK__) && (__TMW_DIAB_TRICORE_INTRINSIC_MASK__ & 0x400000)

/* __builtin_expect
   ----------------
   We provide an implementation for this function that allows Polyspace to fully analyze
   (no stub).
*/
#define __builtin_expect(exp,c) (exp)

#endif
#if defined(__TMW_DIAB_TRICORE_INTRINSIC_MASK__) && (__TMW_DIAB_TRICORE_INTRINSIC_MASK__ & 0x2)

PST_LINK_C unsigned int __ff0(unsigned int);
PST_LINK_C unsigned int __ff0ll(unsigned long long);
PST_LINK_C unsigned int __ff1(unsigned int);
PST_LINK_C unsigned int __ff1ll(unsigned long long);
PST_LINK_C int abs(int);
PST_LINK_C long labs(long);
PST_LINK_C void _bisr(const unsigned int);
PST_LINK_C void _mcfr(const unsigned int, int);
PST_LINK_C void _mtcr(const unsigned int, int);
PST_LINK_C void _syscall(const unsigned int);
PST_LINK_C void _enable(void);
PST_LINK_C void _debug(void);
PST_LINK_C void _dsync(void);
PST_LINK_C void _isync(void);
PST_LINK_C void _rstv(void);
PST_LINK_C void _rslcxq(void);
PST_LINK_C void _sclcx(void);
PST_LINK_C void _nop(void);

#endif
#if defined(__TMW_DIAB_TRICORE_INTRINSIC_MASK__) && (__TMW_DIAB_TRICORE_INTRINSIC_MASK__ & 0x4)

PST_LINK_C void _disable(void);
PST_LINK_C void _restore(void);

#endif


#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* __TMW_COMPILER_DIAB__ && __TMW_TARGET_TRICORE__ */

#endif /* _DIAB_BUILTINS_TRICORE_H_ */
