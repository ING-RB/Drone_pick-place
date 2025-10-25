/*
 * Copyright 2020-2023 The MathWorks, Inc.
 */

#ifndef _IAR_EW_BUILTINS_RISCV_H_
#define _IAR_EW_BUILTINS_RISCV_H_

/*
 * Intrinsic Functions from IAR Embedded Workbench for ARM version V7.80.2.
 */

#if defined(__TMW_COMPILER_IAREW__) && defined(__TMW_TARGET_RISCV__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

/* Support IAR new/delete operators instantiation for __data32 qualified
 * objects.
 * In case of problem, define the __PST_NO_IAR_DATA_OPERATORS macro to
 * deactivate this.
 */
#if !defined(__PST_NO_IAR_DATA_OPERATORS) && defined(__cplusplus)

namespace std { struct nothrow_t; }

void __data32 *operator new __data32(unsigned int, const std::nothrow_t&);
inline void __data32 *operator new __data32(unsigned int, void __data32 *_Where) { return _Where; }
void __data32 *operator new[] __data32(unsigned int, const std::nothrow_t&);
inline void __data32 *operator new[] __data32(unsigned int, void __data32 *_Where) { return _Where; }
void operator delete(void __data32 *, const std::nothrow_t&);
void operator delete[](void __data32 *, const std::nothrow_t&);
inline void operator delete(void __data32 *, void __data32 *) { }
inline void operator delete[](void __data32 *, void __data32 *) { }

#endif /* !defined(__PST_NO_IAR_DATA_OPERATORS) && defined(__cplusplus) */

/*
 * The following built-in functions are modeled as returning a fake value.
 * As they are used in variable initializations (for vector tables)
 * they cannot be modeled as a function call, nor to a volatile
 * variable value.
 */
#define __section_begin(x) ((void*)8)
#define __section_end(x) ((void*)108)
#define __section_size(x) 100U
#define __segment_begin(x) ((void*)8)
#define __segment_end(x) ((void*)108)
#define __segment_size(x) 100U
#define __sfb(x) ((void*)8)
#define __sfe(x) ((void*)108)
#define __sfs(x) 100U


#define __constrange(x,y) const

extern double __pst_rnddbl(double);
#define __c99_generic(a,b,c,d,e,f,g,h,i) __pst_rnddbl


#ifdef __cplusplus

#define __iar_atomic_is_lock_free(a, b) true

PST_LINK_C __intrinsic void __atomic_load(__edg_size_type__,const volatile _Atomic void*,void*,int);
PST_LINK_C __intrinsic void __atomic_store(__edg_size_type__,volatile _Atomic void*,void*,int);
PST_LINK_C __intrinsic bool __atomic_compare_exchange(__edg_size_type__,volatile _Atomic void*,void*,void*,int,int);
PST_LINK_C __intrinsic void __atomic_exchange(__edg_size_type__,volatile _Atomic void*,void*,void*,int);

PST_LINK_C __intrinsic unsigned char      __atomic_load_1      (const volatile _Atomic void*,int);
PST_LINK_C __intrinsic void               __atomic_store_1     (volatile _Atomic void*, unsigned char, int);
PST_LINK_C __intrinsic unsigned char      __atomic_add_fetch_1 (volatile _Atomic void*, unsigned char, int);
PST_LINK_C __intrinsic unsigned char      __atomic_and_fetch_1 (volatile _Atomic void*, unsigned char, int);
PST_LINK_C __intrinsic unsigned char      __atomic_exchange_1  (volatile _Atomic void*, unsigned char, int);
PST_LINK_C __intrinsic unsigned char      __atomic_fetch_add_1 (volatile _Atomic void*, unsigned char, int);
PST_LINK_C __intrinsic unsigned char      __atomic_fetch_and_1 (volatile _Atomic void*, unsigned char, int);
PST_LINK_C __intrinsic unsigned char      __atomic_fetch_or_1  (volatile _Atomic void*, unsigned char, int);
PST_LINK_C __intrinsic unsigned char      __atomic_fetch_xor_1 (volatile _Atomic void*, unsigned char, int);
PST_LINK_C __intrinsic unsigned char      __atomic_or_fetch_1  (volatile _Atomic void*, unsigned char, int);
PST_LINK_C __intrinsic unsigned char      __atomic_sub_fetch_1 (volatile _Atomic void*, unsigned char, int);
PST_LINK_C __intrinsic unsigned char      __atomic_xor_fetch_1 (volatile _Atomic void*, unsigned char, int);
PST_LINK_C __intrinsic unsigned short     __atomic_load_2      (const volatile _Atomic void*,int);
PST_LINK_C __intrinsic void               __atomic_store_2     (volatile _Atomic void*, unsigned short, int);
PST_LINK_C __intrinsic unsigned short     __atomic_add_fetch_2 (volatile _Atomic void*, unsigned short, int);
PST_LINK_C __intrinsic unsigned short     __atomic_and_fetch_2 (volatile _Atomic void*, unsigned short, int);
PST_LINK_C __intrinsic unsigned short     __atomic_exchange_2  (volatile _Atomic void*, unsigned short, int);
PST_LINK_C __intrinsic unsigned short     __atomic_fetch_add_2 (volatile _Atomic void*, unsigned short, int);
PST_LINK_C __intrinsic unsigned short     __atomic_fetch_and_2 (volatile _Atomic void*, unsigned short, int);
PST_LINK_C __intrinsic unsigned short     __atomic_fetch_or_2  (volatile _Atomic void*, unsigned short, int);
PST_LINK_C __intrinsic unsigned short     __atomic_fetch_xor_2 (volatile _Atomic void*, unsigned short, int);
PST_LINK_C __intrinsic unsigned short     __atomic_or_fetch_2  (volatile _Atomic void*, unsigned short, int);
PST_LINK_C __intrinsic unsigned short     __atomic_sub_fetch_2 (volatile _Atomic void*, unsigned short, int);
PST_LINK_C __intrinsic unsigned short     __atomic_xor_fetch_2 (volatile _Atomic void*, unsigned short, int);
PST_LINK_C __intrinsic unsigned int       __atomic_load_4      (const volatile _Atomic void*,int);
PST_LINK_C __intrinsic void               __atomic_store_4     (volatile _Atomic void*, unsigned int, int);
PST_LINK_C __intrinsic unsigned int       __atomic_add_fetch_4 (volatile _Atomic void*, unsigned int, int);
PST_LINK_C __intrinsic unsigned int       __atomic_and_fetch_4 (volatile _Atomic void*, unsigned int, int);
PST_LINK_C __intrinsic unsigned int       __atomic_exchange_4  (volatile _Atomic void*, unsigned int, int);
PST_LINK_C __intrinsic unsigned int       __atomic_fetch_add_4 (volatile _Atomic void*, unsigned int, int);
PST_LINK_C __intrinsic unsigned int       __atomic_fetch_and_4 (volatile _Atomic void*, unsigned int, int);
PST_LINK_C __intrinsic unsigned int       __atomic_fetch_or_4  (volatile _Atomic void*, unsigned int, int);
PST_LINK_C __intrinsic unsigned int       __atomic_fetch_xor_4 (volatile _Atomic void*, unsigned int, int);
PST_LINK_C __intrinsic unsigned int       __atomic_or_fetch_4  (volatile _Atomic void*, unsigned int, int);
PST_LINK_C __intrinsic unsigned int       __atomic_sub_fetch_4 (volatile _Atomic void*, unsigned int, int);
PST_LINK_C __intrinsic unsigned int       __atomic_xor_fetch_4 (volatile _Atomic void*, unsigned int, int);
PST_LINK_C __intrinsic unsigned long long __atomic_load_8      (const volatile _Atomic void*,int);
PST_LINK_C __intrinsic void               __atomic_store_8     (volatile _Atomic void*, unsigned long long, int);
PST_LINK_C __intrinsic unsigned long long __atomic_add_fetch_8 (volatile _Atomic void*, unsigned long long, int);
PST_LINK_C __intrinsic unsigned long long __atomic_and_fetch_8 (volatile _Atomic void*, unsigned long long, int);
PST_LINK_C __intrinsic unsigned long long __atomic_exchange_8  (volatile _Atomic void*, unsigned long long, int);
PST_LINK_C __intrinsic unsigned long long __atomic_fetch_add_8 (volatile _Atomic void*, unsigned long long, int);
PST_LINK_C __intrinsic unsigned long long __atomic_fetch_and_8 (volatile _Atomic void*, unsigned long long, int);
PST_LINK_C __intrinsic unsigned long long __atomic_fetch_or_8  (volatile _Atomic void*, unsigned long long, int);
PST_LINK_C __intrinsic unsigned long long __atomic_fetch_xor_8 (volatile _Atomic void*, unsigned long long, int);
PST_LINK_C __intrinsic unsigned long long __atomic_or_fetch_8  (volatile _Atomic void*, unsigned long long, int);
PST_LINK_C __intrinsic unsigned long long __atomic_sub_fetch_8 (volatile _Atomic void*, unsigned long long, int);
PST_LINK_C __intrinsic unsigned long long __atomic_xor_fetch_8 (volatile _Atomic void*, unsigned long long, int);

#define __assignment_by_bitwise_copy_allowed(x) true
#define __construction_by_bitwise_copy_allowed(x) true
#define __has_constructor(x) true
#define __has_destructor(x) true

#if (__IAR_SYSTEMS_ICC__>=9) && !defined(PST_NO_IAR_ATOMIC_DEFINES)
#ifndef __iar_atomic_add_fetch
#define __iar_atomic_add_fetch(x,y,z) 0
#endif
#ifndef __iar_atomic_sub_fetch
#define __iar_atomic_sub_fetch(x,y,z) 0
#endif
#ifndef __iar_atomic_load
#define __iar_atomic_load(x,y) 0
#endif
#ifndef __iar_atomic_compare_exchange_weak
#define __iar_atomic_compare_exchange_weak(x,y,z,t,u) 0
#endif
#endif

#endif /*__cplusplus*/

#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* __TMW_COMPILER_IAREW__ && __TMW_TARGET_ARM__ */

#endif /* _IAR_EW_BUILTINS_RISCV_H_ */
