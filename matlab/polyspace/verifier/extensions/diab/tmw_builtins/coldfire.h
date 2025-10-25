/*
 * Copyright 2016-2022 The MathWorks, Inc.
 */

#ifndef _DIAB_BUILTINS_COLDFIRE_H_
#define _DIAB_BUILTINS_COLDFIRE_H_

/*
   Intrinsic Functions, see Section 8.6 of the Wind River Diab for ColdFire 5.9 manual.
   No functions are declared for ColdFire in <diab>/include/diab/xxxasm.h
*/

#if defined(__TMW_COMPILER_DIAB__) && defined(__TMW_TARGET_COLDFIRE__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

#ifdef __PST_POLYSPACE_MODE
PST_LINK_C void *__alloca(unsigned int);
#if defined(__TMW_DIAB_COLDFIRE_INTRINSIC_MASK__) && (__TMW_DIAB_COLDFIRE_INTRINSIC_MASK__ & 0x800000)
PST_LINK_C void *alloca(unsigned int);
#endif
#else /* __PST_POLYSPACE_MODE */
PST_LINK_C void *__alloca(int);
#if defined(__TMW_DIAB_COLDFIRE_INTRINSIC_MASK__) && (__TMW_DIAB_COLDFIRE_INTRINSIC_MASK__ & 0x800000)
PST_LINK_C void *alloca(int);
#endif
#endif /* __PST_POLYSPACE_MODE */

#if defined(__TMW_DIAB_COLDFIRE_INTRINSIC_MASK__) && (__TMW_DIAB_COLDFIRE_INTRINSIC_MASK__ & 0x400000)

/* __builtin_expect
   ----------------
   We provide an implementation for this function that allows Polyspace to fully analyze
   (no stub).
*/
#define __builtin_expect(exp,c) (exp)

#endif


#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* __TMW_COMPILER_DIAB__ && __TMW_TARGET_COLDFIRE__ */

#endif /* _DIAB_BUILTINS_COLDFIRE_H_ */

