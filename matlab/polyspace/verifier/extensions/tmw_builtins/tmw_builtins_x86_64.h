/*
 * Copyright 2024 The MathWorks, Inc.
 */

#ifndef _TMW_BUILTINS_X86_64_H_
#define _TMW_BUILTINS_X86_64_H_

#pragma tmw no_emit
#pragma tmw code_instrumentation off
#pragma tmw push(builtins)

#if __SIZEOF_POINTER__ == 8

#if defined(__GNUC__) && !defined(__tmw_clang__)
#if GNU_GE(13)
PST_LINK_C int __builtin_ia32_cmpccxadd(int*,int,int,int);
#endif
#if GNU_GE(14)
PST_LINK_C void __builtin_ia32_ldtilecfg(const void*);
PST_LINK_C void __builtin_ia32_sttilecfg(void*);
PST_LINK_C unsigned long long __builtin_ia32_urdmsr(unsigned long long);
PST_LINK_C void __builtin_ia32_uwrmsr(unsigned long long,unsigned long long);
#endif
#endif /* __GNUC__ && !__tmw_clang__ */

#ifdef __tmw_clang__
#if CLANG_GE(18)
PST_LINK_C unsigned long long __builtin_ia32_urdmsr(unsigned long long) __edg_throw__();
PST_LINK_C void __builtin_ia32_uwrmsr(unsigned long long,unsigned long long) __edg_throw__();
#endif
#endif /* __tmw_clang__ */

#endif /* __SIZEOF_POINTER__ == 8 */

#pragma tmw pop(builtins)
#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* _TMW_BUILTINS_X86_64_H_ */
