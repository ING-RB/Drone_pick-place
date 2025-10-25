/*
 * Copyright 2018-2022 The MathWorks, Inc.
 */

#ifndef _ARMCC_X_H_
#define _ARMCC_X_H_

#if defined(__TMW_COMPILER_ARMCC__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off


PST_LINK_C void __breakpoint(int val);
PST_LINK_C void __cdp(unsigned int coproc, unsigned int opcode1, unsigned int opcode2);
PST_LINK_C void __clrex(void);
PST_LINK_C unsigned char __clz(unsigned int val);
PST_LINK_C unsigned int __current_pc(void);
PST_LINK_C unsigned int __current_sp(void);
PST_LINK_C int __disable_fiq(void);
PST_LINK_C void __enable_fiq(void);
PST_LINK_C void __enable_irq(void);
PST_LINK_C double __fabs(double val);
PST_LINK_C float __fabsf(float val);
PST_LINK_C void __force_stores(void);
PST_LINK_C unsigned int __ldrex(volatile void *ptr);
PST_LINK_C unsigned long long __ldrexd(volatile void *ptr);
PST_LINK_C unsigned int __ldrt(const volatile void *ptr);
PST_LINK_C void __memory_changed(void);

PST_LINK_C void __nop(void);
PST_LINK_C void __schedule_barrier(void); 
PST_LINK_C void __dsb(unsigned char); 
PST_LINK_C void __isb(unsigned char); 

PST_LINK_C int __qadd(int val1, int val2);
PST_LINK_C int __qdbl(int val);
PST_LINK_C int __qsub(int val1, int val2);
PST_LINK_C unsigned int __rbit(unsigned int val);
PST_LINK_C unsigned int __rev(unsigned int val);
PST_LINK_C unsigned int __return_address(void);
PST_LINK_C unsigned int __ror(unsigned int val, unsigned int shift);
PST_LINK_C void schedule_barrier(void);
PST_LINK_C void __sev(void);
PST_LINK_C double __sqrt(double val);
PST_LINK_C float __sqrtf(float val);
PST_LINK_C int __ssat(int val, unsigned int sat);
PST_LINK_C int __strex(unsigned int val, volatile void *ptr);
PST_LINK_C int __strexd(unsigned long long val, volatile void *ptr);
PST_LINK_C void __strt(unsigned int val, volatile void *ptr);
PST_LINK_C unsigned int __swp(unsigned int val, volatile void *ptr);

PST_LINK_C int __usat(unsigned int val, unsigned int sat);
PST_LINK_C void __wfe(void);
PST_LINK_C void __wfi(void);
PST_LINK_C void __yield(void);



PST_LINK_C unsigned int __qadd16(unsigned int, unsigned int);
PST_LINK_C unsigned int __qadd8(unsigned int, unsigned int);
PST_LINK_C unsigned int __qasx(unsigned int, unsigned int);
PST_LINK_C unsigned int __qsax(unsigned int, unsigned int);
PST_LINK_C unsigned int __qsub16(unsigned int, unsigned int);
PST_LINK_C unsigned int __qsub8(unsigned int, unsigned int);
PST_LINK_C unsigned int __sadd16(unsigned int, unsigned int);
PST_LINK_C unsigned int __sadd8(unsigned int, unsigned int);
PST_LINK_C unsigned int __sasx(unsigned int, unsigned int);
PST_LINK_C unsigned int __sel(unsigned int, unsigned int);
PST_LINK_C unsigned int __shadd16(unsigned int, unsigned int);
PST_LINK_C unsigned int __shadd8(unsigned int, unsigned int);
PST_LINK_C unsigned int __shasx(unsigned int, unsigned int);
PST_LINK_C unsigned int __shsax(unsigned int, unsigned int);
PST_LINK_C unsigned int __shsub16(unsigned int, unsigned int);
PST_LINK_C unsigned int __shsub8(unsigned int, unsigned int);
PST_LINK_C unsigned int __smlad(unsigned int, unsigned int, unsigned int);
PST_LINK_C unsigned long long __smlald(unsigned int, unsigned int, unsigned long long);
PST_LINK_C unsigned int __smlsd(unsigned int, unsigned int, unsigned int);
PST_LINK_C unsigned long long __smlsld(unsigned int, unsigned int, unsigned long long);
PST_LINK_C unsigned int __smuad(unsigned int, unsigned int);
PST_LINK_C unsigned int __smusd(unsigned int, unsigned int);
PST_LINK_C unsigned int __ssat16(unsigned int, unsigned int);
PST_LINK_C unsigned int __ssax(unsigned int, unsigned int);
PST_LINK_C unsigned int __ssub16(unsigned int, unsigned int);
PST_LINK_C unsigned int __ssub8(unsigned int, unsigned int);
PST_LINK_C unsigned int __sxtab16(unsigned int, unsigned int);
PST_LINK_C unsigned int __sxtb16(unsigned int, unsigned int);
PST_LINK_C unsigned int __uadd16(unsigned int, unsigned int);
PST_LINK_C unsigned int __uadd8(unsigned int, unsigned int);
PST_LINK_C unsigned int __uasx(unsigned int, unsigned int);
PST_LINK_C unsigned int __uhadd16(unsigned int, unsigned int);
PST_LINK_C unsigned int __uhadd8(unsigned int, unsigned int);
PST_LINK_C unsigned int __uhasx(unsigned int, unsigned int);
PST_LINK_C unsigned int __uhsax(unsigned int, unsigned int);
PST_LINK_C unsigned int __uhsub16(unsigned int, unsigned int);
PST_LINK_C unsigned int __uhsub8(unsigned int, unsigned int);
PST_LINK_C unsigned int __uqadd16(unsigned int, unsigned int);
PST_LINK_C unsigned int __uqadd8(unsigned int, unsigned int);
PST_LINK_C unsigned int __uqasx(unsigned int, unsigned int);
PST_LINK_C unsigned int __uqsax(unsigned int, unsigned int);
PST_LINK_C unsigned int __uqsub16(unsigned int, unsigned int);
PST_LINK_C unsigned int __uqsub8(unsigned int, unsigned int);
PST_LINK_C unsigned int __usad8(unsigned int, unsigned int);
PST_LINK_C unsigned int __usada8(unsigned int, unsigned int, unsigned int);
PST_LINK_C unsigned int __usax(unsigned int, unsigned int);
PST_LINK_C unsigned int __usat16(unsigned int, unsigned int);
PST_LINK_C unsigned int __usub16(unsigned int, unsigned int);
PST_LINK_C unsigned int __usub8(unsigned int, unsigned int);
PST_LINK_C unsigned int __uxtab16(unsigned int, unsigned int);
PST_LINK_C unsigned int __uxtb16(unsigned int, unsigned int);


PST_LINK_C float __builtin_inff();
PST_LINK_C float __builtin_nanf(const char*);
PST_LINK_C float __builtin_nansf(const char*);

PST_LINK_C double __builtin_inf(const char*);
PST_LINK_C double __builtin_nan(const char*);
PST_LINK_C double __builtin_nans(const char*);
PST_LINK_C int __builtin_popcountll(unsigned long long);


#ifdef __cplusplus
long double __builtin_inf();
long double __builtin_nan();
long double __builtin_nans();
#endif

#ifndef __global_reg
#define __global_reg(x)
#endif

#ifndef __smc
#define __smc(x)
#endif

#ifndef __svc
#define __svc(x)
#endif

#ifndef __svc_indirect
#define __svc_indirect(x)
#endif

#ifndef __svc_indirect_r7
#define __svc_indirect_r7(x)
#endif

#ifndef __swi
#define __swi(x)
#endif

#ifndef __swi_indirect
#define __swi_indirect(x)
#endif

#pragma tmw code_instrumentation on
#pragma tmw emit

#endif

#endif /* _ARMCC_X_H_ */
