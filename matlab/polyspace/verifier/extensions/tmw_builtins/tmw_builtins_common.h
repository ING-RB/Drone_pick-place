/*
 * Copyright 2024 The MathWorks, Inc.
 */

#ifndef _TMW_BUILTINS_COMMON_H_
#define _TMW_BUILTINS_COMMON_H_

#pragma tmw no_emit
#pragma tmw code_instrumentation off
#pragma tmw push(builtins)


#if defined(__GNUC__) && !defined(__tmw_clang__)
#if GNU_GE(14)
PST_LINK_C void __builtin___gcc_nested_func_ptr_created(void*,void*,void*);
PST_LINK_C void __builtin___gcc_nested_func_ptr_deleted(void);
#endif
#if GNU_GE(14)
PST_LINK_C int __builtin_clrsbg(...);
PST_LINK_C int __builtin_clzg(...);
PST_LINK_C int __builtin_ctzg(...);
PST_LINK_C int __builtin_ffsg(...);
PST_LINK_C int __builtin_iseqsig(...);
PST_LINK_C int __builtin_parityg(...);
PST_LINK_C int __builtin_popcountg(...);
PST_LINK_C void* __builtin_stack_address(void);
PST_LINK_C void __cxa_call_terminate(void*) __attribute((noreturn));
#endif
#endif /* __GNUC__ && !__tmw_clang__ */

#ifdef __tmw_clang__
#if CLANG_GE(18)
PST_LINK_C void __builtin_elementwise_bitreverse(...) __edg_throw__();
PST_LINK_C void __builtin_elementwise_sqrt(...) __edg_throw__();
PST_LINK_C __fp16 __builtin_exp10f16(__fp16) __edg_throw__();
PST_LINK_C int __builtin_issubnormal(...) __edg_throw__();
PST_LINK_C int __builtin_iszero(...) __edg_throw__();
PST_LINK_C void __builtin_vectorelements(...) __edg_throw__();
PST_LINK_C void __scoped_atomic_add_fetch(...);
PST_LINK_C void __scoped_atomic_and_fetch(...);
PST_LINK_C void __scoped_atomic_compare_exchange(...);
PST_LINK_C void __scoped_atomic_compare_exchange_n(...);
PST_LINK_C void __scoped_atomic_exchange(...);
PST_LINK_C void __scoped_atomic_exchange_n(...);
PST_LINK_C void __scoped_atomic_fetch_add(...);
PST_LINK_C void __scoped_atomic_fetch_and(...);
PST_LINK_C void __scoped_atomic_fetch_max(...);
PST_LINK_C void __scoped_atomic_fetch_min(...);
PST_LINK_C void __scoped_atomic_fetch_nand(...);
PST_LINK_C void __scoped_atomic_fetch_or(...);
PST_LINK_C void __scoped_atomic_fetch_sub(...);
PST_LINK_C void __scoped_atomic_fetch_xor(...);
PST_LINK_C void __scoped_atomic_load(...);
PST_LINK_C void __scoped_atomic_load_n(...);
PST_LINK_C void __scoped_atomic_max_fetch(...);
PST_LINK_C void __scoped_atomic_min_fetch(...);
PST_LINK_C void __scoped_atomic_nand_fetch(...);
PST_LINK_C void __scoped_atomic_or_fetch(...);
PST_LINK_C void __scoped_atomic_store(...);
PST_LINK_C void __scoped_atomic_store_n(...);
PST_LINK_C void __scoped_atomic_sub_fetch(...);
PST_LINK_C void __scoped_atomic_xor_fetch(...);
#endif
#if CLANG_GE(18)
PST_LINK_C __float128 __builtin_exp10f128(__float128) __edg_throw__();
#endif
#endif /* __tmw_clang__ */


#pragma tmw pop(builtins)
#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* _TMW_BUILTINS_COMMON_H_ */
