/*
 * Copyright 2017-2022 The MathWorks, Inc.
 */


#ifndef _GREENHILLS_BUILTINS_POWERPC64_H_
#define _GREENHILLS_BUILTINS_POWERPC64_H_

#if defined(__TMW_COMPILER_GREENHILLS__) && defined(__TMW_TARGET_POWERPC64__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

PST_LINK_C void __DI(void);
PST_LINK_C void __EI(void);
PST_LINK_C unsigned long __GETSR(void);
PST_LINK_C void __SETSR(unsigned long val);
PST_LINK_C unsigned int __MULUH(unsigned int a, unsigned int b);
PST_LINK_C signed int __MULSH(signed int a, signed int b);
PST_LINK_C unsigned int __CLZ32(unsigned int a);

#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* __TMW_COMPILER_GREENHILLS__ && __TMW_TARGET_POWERPC64__ */

#endif /* _GREENHILLS_BUILTINS_POWERPC64_H_ */
