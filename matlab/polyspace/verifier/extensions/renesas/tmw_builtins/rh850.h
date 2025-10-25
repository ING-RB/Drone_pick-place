/*
 * Copyright 2018-2022 The MathWorks, Inc.
 */

#ifndef _RENESAS_BUILTINS_RH850_H_
#define _RENESAS_BUILTINS_RH850_H_

/*
 * Intrinsic Functions from Renesas CC-RH version V1.06.00.
 */

#if defined(__TMW_COMPILER_RENESAS__) && defined(__TMW_TARGET_RH850__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

PST_LINK_C void __nop(void);
PST_LINK_C void __halt(void);
PST_LINK_C long __satadd(long, long);
PST_LINK_C long __satsub(long, long);
PST_LINK_C long __bsh(long);
PST_LINK_C long __bsw(long);
PST_LINK_C long __hsw(long);
PST_LINK_C long __mul32(long, long);
PST_LINK_C unsigned long __mul32u(unsigned long, unsigned long);
PST_LINK_C long __sch0l(long);
PST_LINK_C long __sch0r(long);
PST_LINK_C long __sch1l(long);
PST_LINK_C long __sch1r(long);
PST_LINK_C void __ldsr(long, unsigned long);
PST_LINK_C void __ldsr_rh(long, long, unsigned long);
PST_LINK_C unsigned long __stsr(long);
PST_LINK_C unsigned long __stsr_rh(long, long);
PST_LINK_C long __caxi(long*, long, long);
PST_LINK_C void __DI(void);
PST_LINK_C void __EI(void);
PST_LINK_C void __set_il_rh(long, void*);
PST_LINK_C void __clr1(unsigned char*, long);
PST_LINK_C void __set1(unsigned char*, long);
PST_LINK_C void __not1(unsigned char*, long);
PST_LINK_C long __ldlw(long*);
#if defined(__RENESAS_VERSION__)&&(__RENESAS_VERSION__<0x01060000)
PST_LINK_C void __stcw(long*, long); /* Return void before V1.05.00 */
#else
PST_LINK_C long __stcw(long*, long);
#endif
PST_LINK_C void __synce(void);
PST_LINK_C void __synci(void);
PST_LINK_C void __syncm(void);
PST_LINK_C void __syncp(void);
PST_LINK_C void __dbcp(void);
PST_LINK_C void __dbpush(long, long);
PST_LINK_C void __dbtag(long);
PST_LINK_C void __traceivalue(long);
PST_LINK_C void __tracefvalue(float);
PST_LINK_C void __tracestring(const char*);

#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* __TMW_COMPILER_RENESAS__ && __TMW_TARGET_RH850__ */

#endif /* _RENESAS_BUILTINS_RH850_H_ */
