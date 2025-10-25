/*
 * Copyright 2018-2022 The MathWorks, Inc.
 */

#ifndef _RENESAS_BUILTINS_RL78_H_
#define _RENESAS_BUILTINS_RL78_H_

/*
 * Intrinsic Functions from Renesas CC-RL version V1.05.00.
 */

#if defined(__TMW_COMPILER_RENESAS__) && defined(__TMW_TARGET_RL78__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

PST_LINK_C void __near __DI(void);
PST_LINK_C void __near __EI(void);
PST_LINK_C void __near __halt(void);
PST_LINK_C void __near __stop(void);
PST_LINK_C void __near __brk(void);
PST_LINK_C void __near __nop(void);

PST_LINK_C unsigned char __near __rolb(unsigned char x, unsigned char y);
PST_LINK_C unsigned char __near __rorb(unsigned char x, unsigned char y);
PST_LINK_C unsigned int __near __rolw(unsigned int x, unsigned char y);
PST_LINK_C unsigned int __near __rorw(unsigned int x, unsigned char y);
PST_LINK_C unsigned int __near __mulu(unsigned char x, unsigned char y);
PST_LINK_C unsigned long __far _COM_mului(unsigned int x, unsigned int y);
PST_LINK_C unsigned long __near __mului(unsigned int x, unsigned int y);
PST_LINK_C signed long __far _COM_mulsi(signed int x, signed int y);
PST_LINK_C signed long __near __mulsi(signed int x, signed int y);
PST_LINK_C unsigned long long __far _COM_mulul(unsigned long x, unsigned long y);
PST_LINK_C unsigned long long __far __mulul(unsigned long x, unsigned long y);
PST_LINK_C signed long long __far _COM_mulsl(signed long x, signed long y);
PST_LINK_C signed long long __far __mulsl(signed long x, signed long y);
PST_LINK_C unsigned int __far _COM_divui(unsigned int x, unsigned char y);
PST_LINK_C unsigned int __far __divui(unsigned int x, unsigned char y);
PST_LINK_C unsigned long __far _COM_divul(unsigned long x, unsigned int y);
PST_LINK_C unsigned long __far __divul(unsigned long x, unsigned int y);
PST_LINK_C unsigned char __far _COM_remui(unsigned int x, unsigned char y);
PST_LINK_C unsigned char __far __remui(unsigned int x, unsigned char y);
PST_LINK_C unsigned int __far _COM_remul(unsigned long x, unsigned int y);
PST_LINK_C unsigned int __far __remul(unsigned long x, unsigned int y);
PST_LINK_C unsigned long __far _COM_macui(unsigned int x, unsigned int y, unsigned long z);
PST_LINK_C unsigned long __far __macui(unsigned int x, unsigned int y, unsigned long z);
PST_LINK_C signed long __far _COM_macsi(signed int x, signed int y, signed long z);
PST_LINK_C signed long __far __macsi(signed int x, signed int y, signed long z);

PST_LINK_C unsigned char __near __get_psw(void);
PST_LINK_C void __near __set_psw(unsigned char x);
PST_LINK_C void __near __set1(unsigned char __near *x, unsigned char y);
PST_LINK_C void __near __clr1(unsigned char __near *x, unsigned char y);
PST_LINK_C void __near __not1(unsigned char __near *x, unsigned char y);

#ifndef __sectop
#define __sectop(section) (void __far * volatile)0x2000
#endif
#ifndef __secend
#define __secend(section) (void __far * volatile)0x3000
#endif

#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* __TMW_COMPILER_RENESAS__ && __TMW_TARGET_RL78__ */

#endif /* _RENESAS_BUILTINS_RL78_H_ */
