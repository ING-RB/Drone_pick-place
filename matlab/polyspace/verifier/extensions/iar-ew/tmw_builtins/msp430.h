/*
 * Copyright 2017-2023 The MathWorks, Inc.
 */

#ifndef _IAR_EW_BUILTINS_MSP430_H_
#define _IAR_EW_BUILTINS_MSP430_H_

/*
   Intrinsic Functions from IAR Embedded Workbench for MSP430 version Compiler V6.50.1.
*/

#if defined(__TMW_COMPILER_IAREW__) && defined(__TMW_TARGET_MSP430__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

__intrinsic int __low_level_init(void);

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

#endif /*__cplusplus*/

#pragma tmw code_instrumentation off
#pragma tmw emit

#endif /* __TMW_COMPILER_IAREW__ && __TMW_TARGET_MSP430__ */

#endif /* _IAR_EW_BUILTINS_MSP430_H_ */
