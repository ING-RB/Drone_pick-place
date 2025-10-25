/*
 * Copyright 2017-2023 The MathWorks, Inc.
 */

#ifndef _IAR_EW_BUILTINS_ARM_H_
#define _IAR_EW_BUILTINS_ARM_H_

/*
 * Intrinsic Functions from IAR Embedded Workbench for ARM.
 */

#if defined(__TMW_COMPILER_IAREW__) && defined(__TMW_TARGET_ARM__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

#if __IAR_SYSTEMS_ICC__ < 9 /* IAR v7.x */
PST_LINK_C __interwork __softfp unsigned long __get_return_address(void);
PST_LINK_C __interwork __softfp unsigned long __get_LR(void);
PST_LINK_C __interwork __softfp void __set_LR(unsigned long);
PST_LINK_C __interwork __softfp unsigned long __get_SP(void);
PST_LINK_C __interwork __softfp void __set_SP(unsigned long);
PST_LINK_C __interwork __softfp unsigned long __get_PC(void);
#else /* IAR v8.x and higher */
PST_LINK_C __nounwind __interwork __softfp unsigned int __get_return_address(void);
PST_LINK_C __interwork __softfp unsigned int __get_LR(void);
PST_LINK_C __interwork __softfp void __set_LR(unsigned int);
PST_LINK_C __interwork __softfp unsigned int __get_SP(void);
PST_LINK_C __interwork __softfp void __set_SP(unsigned int);
PST_LINK_C __nounwind __interwork __softfp unsigned int __get_PC(void);
#endif


PST_LINK_C __intrinsic void __aeabi_memset(void *, unsigned int, int);
PST_LINK_C __intrinsic void __aeabi_memcpy(void *, const void *, unsigned int);
PST_LINK_C __intrinsic void __aeabi_memmove(void *, const void *, unsigned int);

__nounwind  __softfp unsigned int __iar_fp2bits32(float);
__nounwind  __softfp unsigned long long __iar_fp2bits64(double);
__nounwind  __softfp unsigned int __iar_fpgethi64(double);


/* Support IAR new/delete operators instantiation for __data qualified
 * objects.
 * In case of problem, define the __PST_NO_IAR_DATA_OPERATORS macro to
 * deactivate this.
 */
#if !defined(__PST_NO_IAR_DATA_OPERATORS) && defined(__cplusplus) && __IAR_SYSTEMS_ICC__ >= 9

namespace std { struct nothrow_t; }

void __data *operator new __data(unsigned int, const std::nothrow_t&) noexcept;
inline void __data *operator new __data(unsigned int, void __data *_Where) noexcept { return _Where; }
void __data *operator new[] __data(unsigned int, const std::nothrow_t&) noexcept;
inline void __data *operator new[] __data(unsigned int, void __data *_Where) noexcept { return _Where; }
void operator delete(void __data *, const std::nothrow_t&) noexcept;
void operator delete[](void __data *, const std::nothrow_t&) noexcept;
inline void operator delete(void __data *, void __data *) noexcept { }
inline void operator delete[](void __data *, void __data *) noexcept { }

#endif /* !defined(__PST_NO_IAR_DATA_OPERATORS) && defined(__cplusplus) && __IAR_SYSTEMS_ICC__ >= 9 */

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

#endif /* _IAR_EW_BUILTINS_ARM_H_ */
