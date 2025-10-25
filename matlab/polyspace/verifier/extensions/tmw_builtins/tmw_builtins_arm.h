/*
 * Copyright 2024 The MathWorks, Inc.
 */

#ifndef _TMW_BUILTINS_ARM_H_
#define _TMW_BUILTINS_ARM_H_

#pragma tmw no_emit
#pragma tmw code_instrumentation off
#pragma tmw push(builtins)

#if (defined(__GNUC__) && !defined(__tmw_clang__)) || defined(__tmw_clang__)
PST_LINK_C unsigned int __clz(unsigned int);
#endif

#if defined(__GNUC__) && !defined(__tmw_clang__)
#if defined(__GNUC__) && !defined(__tmw_clang__)
PST_LINK_C void* __builtin___emutls_get_address(void*);
PST_LINK_C void __builtin___emutls_register_common(void*,__edg_size_type__,__edg_size_type__,void*);
#endif
#endif /* __GNUC__ && !__tmw_clang__ */

#ifdef __tmw_clang__
#if CLANG_LE2(14,99) || CLANG_GE(16) || (CLANG_GE(15) && CLANG_LE2(15,99) && defined(__ARM_32BIT_STATE))
PST_LINK_C void __builtin_arm_clrex(void);
PST_LINK_C unsigned __builtin_arm_crc32b(unsigned,unsigned char) __edg_throw__();
PST_LINK_C unsigned __builtin_arm_crc32cb(unsigned,unsigned char) __edg_throw__();
PST_LINK_C unsigned __builtin_arm_crc32ch(unsigned,unsigned short) __edg_throw__();
PST_LINK_C unsigned __builtin_arm_crc32cw(unsigned,unsigned) __edg_throw__();
PST_LINK_C unsigned __builtin_arm_crc32h(unsigned,unsigned short) __edg_throw__();
PST_LINK_C unsigned __builtin_arm_crc32w(unsigned,unsigned) __edg_throw__();
PST_LINK_C void __builtin_arm_dmb(unsigned) __edg_throw__();
PST_LINK_C void __builtin_arm_dsb(unsigned) __edg_throw__();
PST_LINK_C void __builtin_arm_isb(unsigned) __edg_throw__();
PST_LINK_C void __builtin_arm_ldaex(...);
PST_LINK_C int __builtin_arm_ldrex(...);
PST_LINK_C void __builtin_arm_nop(void);
PST_LINK_C unsigned __builtin_arm_rbit(unsigned) __edg_throw__();
PST_LINK_C unsigned __builtin_arm_rsr(const char*) __edg_throw__();
PST_LINK_C void* __builtin_arm_rsrp(const char*) __edg_throw__();
PST_LINK_C void __builtin_arm_sev(void);
PST_LINK_C void __builtin_arm_sevl(void);
PST_LINK_C int __builtin_arm_stlex(...);
PST_LINK_C int __builtin_arm_strex(...);
PST_LINK_C void __builtin_arm_wfe(void);
PST_LINK_C void __builtin_arm_wfi(void);
PST_LINK_C void __builtin_arm_wsr(const char*,unsigned) __edg_throw__();
PST_LINK_C void __builtin_arm_wsrp(const char*,const void*) __edg_throw__();
PST_LINK_C void __builtin_arm_yield(void);
PST_LINK_C void __clear_cache(void*,void*);
#endif
#if (CLANG_GE(10) && CLANG_LE2(14,99)) || CLANG_GE(16) || (CLANG_GE(15) && CLANG_LE2(15,99) && defined(__ARM_32BIT_STATE))
PST_LINK_C unsigned __builtin_arm_cls(unsigned) __edg_throw__();
#endif
#if CLANG_GE(16) || (CLANG_GE(15) && CLANG_LE2(15,99) && defined(__ARM_32BIT_STATE)) || (CLANG_GE(9) && CLANG_LE2(14,99) && defined(__ARM_64BIT_STATE))
PST_LINK_C void* __builtin_sponentry(void);
#endif
#if CLANG_GE(17)
PST_LINK_C unsigned __builtin_arm_clz(unsigned) __edg_throw__();
#endif
#endif /* __tmw_clang__ */


#pragma tmw pop(builtins)
#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* _TMW_BUILTINS_ARM_H_ */
