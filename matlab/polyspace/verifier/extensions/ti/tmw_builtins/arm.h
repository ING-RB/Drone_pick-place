/*
 * Copyright 2017-2022 The MathWorks, Inc.
 */

#ifndef _TI_BUILTINS_ARM_H_
#define _TI_BUILTINS_ARM_H_

#if defined(__TMW_COMPILER_TI__) && defined(__TMW_TARGET_ARM__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

#ifdef __cplusplus
extern "C" namespace std {
PST_LINK_C void* memcpy(void*, const void*, __SIZE_T_TYPE__);
PST_LINK_C void _nassert(int);
}
#endif

PST_LINK_C void _call_swi(unsigned int);
PST_LINK_C unsigned int _disable_FIQ(void);
PST_LINK_C unsigned int _disable_interrupts(void);
PST_LINK_C unsigned int _disable_IRQ(void);
PST_LINK_C unsigned int _enable_FIQ(void);
PST_LINK_C unsigned int _enable_interrupts(void);
PST_LINK_C unsigned int _enable_IRQ(void);
PST_LINK_C unsigned int _get_CPSR(void);
PST_LINK_C void _restore_interrupts(unsigned int);
PST_LINK_C void _set_CPSR(unsigned int);
PST_LINK_C void _set_CPSR_flg(unsigned int);
PST_LINK_C unsigned int _set_interrupt_priority(unsigned int);

PST_LINK_C short _abs16_s(short);
PST_LINK_C int _abs_s(int);
PST_LINK_C unsigned int _ftoi(float);
PST_LINK_C double _itod(unsigned int, unsigned int);
PST_LINK_C float _itof(unsigned int);
PST_LINK_C int _shl(int, short);
PST_LINK_C short _shl16(short, short);
PST_LINK_C int _shr(int, short);
PST_LINK_C short _shr16(short, short);
PST_LINK_C int _subc(int, int);

PST_LINK_C int __clz(int);
PST_LINK_C void __delay_cycles(unsigned int);
PST_LINK_C unsigned int __get_MSP(void);
PST_LINK_C unsigned int __get_PRIMASK(void);
PST_LINK_C unsigned int __ldrex(volatile void*);
PST_LINK_C unsigned int __ldrexb(volatile void*);
PST_LINK_C long long __ldrexd(volatile void*);
PST_LINK_C unsigned int __ldrexh(volatile void*);
PST_LINK_C void __MCR(unsigned int, unsigned int, unsigned int, unsigned int, unsigned int, unsigned int);
PST_LINK_C unsigned int __MRC(unsigned int, unsigned int, unsigned int, unsigned int, unsigned int);
PST_LINK_C void __nop(void);
PST_LINK_C int _norm(int);
PST_LINK_C int _pkhbt(int, int, int);
PST_LINK_C int _pkhtb(int, int, int);
PST_LINK_C int _qadd16(int, int);
PST_LINK_C int _qadd8(int, int);
PST_LINK_C int _qaddsubx(int, int);
PST_LINK_C int _qsub16(int, int);
PST_LINK_C int _qsub8(int, int);
PST_LINK_C int _qsubaddx(int, int);
PST_LINK_C int __rbit(int);
PST_LINK_C int __rev(int);
PST_LINK_C int __rev16(int);
PST_LINK_C int __revsh(int);
PST_LINK_C unsigned int __ror(unsigned int, unsigned int);
PST_LINK_C int _sadd(int, int);
PST_LINK_C int _sadd16(int, int);
PST_LINK_C int _sadd8(int, int);
PST_LINK_C int _saddsubx(int, int);
PST_LINK_C int _sdadd(int, int);
PST_LINK_C int _sdsub(int, int);
PST_LINK_C int _sel(int, int);
PST_LINK_C void __set_MSP(unsigned int);
PST_LINK_C unsigned int __set_PRIMASK(unsigned int);
PST_LINK_C int _shadd16(int, int);
PST_LINK_C int _shadd8(int, int);
PST_LINK_C int _shsub16(int, int);
PST_LINK_C int _shsub8(int, int);
PST_LINK_C int _smac(short, short, int);
PST_LINK_C int _smlabb(short, short, int);
PST_LINK_C int _smlabt(short, int, int);
PST_LINK_C int _smlad(int, int, int);
PST_LINK_C int _smladx(int, int, int);
PST_LINK_C long long _smlalbb(long long, short, short);
PST_LINK_C long long _smlalbt(long long, short, int);
PST_LINK_C long long _smlald(long long, int, int);
PST_LINK_C long long _smlaldx(long long, int, int);
PST_LINK_C long long _smlaltb(long long, int, short);
PST_LINK_C long long _smlaltt(long long, int, int);
PST_LINK_C int _smlatb(int, short, int);
PST_LINK_C int _smlatt(int, int, int);
PST_LINK_C int _smlawb(int, short, int);
PST_LINK_C int _smlawt(int, int, int);
PST_LINK_C int _smlsd(int, int, int);
PST_LINK_C int _smlsdx(int, int, int);
PST_LINK_C long long _smlsld(long long, int, int);
PST_LINK_C long long _smlsldx(long long, int, int);
PST_LINK_C int _smmla(int, int, int);
PST_LINK_C int _smmlar(int, int, int);
PST_LINK_C int _smmls(int, int, int);
PST_LINK_C int _smmlsr(int, int, int);
PST_LINK_C int _smmul(int, int);
PST_LINK_C int _smmulr(int, int);
PST_LINK_C int _smpy(int, int);
PST_LINK_C int _smsub(short, short, int);
PST_LINK_C int _smuad(int, int);
PST_LINK_C int _smuadx(int, int);
PST_LINK_C int _smulbb(short, short);
PST_LINK_C int _smulbt(short, int);
PST_LINK_C int _smultb(int, short);
PST_LINK_C int _smultt(int, int);
PST_LINK_C int _smulwb(int, short);
PST_LINK_C int _smulwt(int, int);
PST_LINK_C int _smusd(int, int);
PST_LINK_C int _smusdx(int, int);
PST_LINK_C double __sqrt(double);
PST_LINK_C float __sqrtf(float);
PST_LINK_C int _ssat16(int, int);
PST_LINK_C int _ssata(int, int, int);
PST_LINK_C int _ssatl(int, int, int);
PST_LINK_C int _ssub(int, int);
PST_LINK_C int _ssub16(int, int);
PST_LINK_C int _ssub8(int, int);
PST_LINK_C int _ssubaddx(int, int);
PST_LINK_C int __strex(unsigned int, volatile void*);
PST_LINK_C int __strexb(unsigned char, volatile void*);
PST_LINK_C int __strexd(long long, volatile void*);
PST_LINK_C int __strexh(unsigned short, volatile void*);
PST_LINK_C int _subc(int, int);
PST_LINK_C int _sxtab(int, int, int);
PST_LINK_C int _sxtab16(int, int, int);
PST_LINK_C int _sxtah(int, int, int);
PST_LINK_C int _sxtb(int, int);
PST_LINK_C int _sxtb16(int, int);
PST_LINK_C int _sxth(int, int);
PST_LINK_C int _uadd16(int, int);
PST_LINK_C int _uadd8(int, int);
PST_LINK_C int _uaddsubx(int, int);
PST_LINK_C int _uhadd16(int, int);
PST_LINK_C int _uhadd8(int, int);
PST_LINK_C int _uhsub16(int, int);
PST_LINK_C int _uhsub8(int, int);
PST_LINK_C long long _umaal(long long, int, int);
PST_LINK_C int _uqadd16(int, int);
PST_LINK_C int _uqadd8(int, int);
PST_LINK_C int _uqaddsubx(int, int);
PST_LINK_C int _uqsub16(int, int);
PST_LINK_C int _uqsub8(int, int);
PST_LINK_C int _uqsubaddx(int, int);
PST_LINK_C int _usad8(int, int);
PST_LINK_C int _usat16(int, int);
PST_LINK_C int _usata(int, int, int);
PST_LINK_C int _usatl(int, int, int);
PST_LINK_C int _usub16(int, int);
PST_LINK_C int _usub8(int, int);
PST_LINK_C int _usubaddx(int, int);
PST_LINK_C int _uxtab(int, int, int);
PST_LINK_C int _uxtab16(int, int, int);
PST_LINK_C int _uxtah(int, int, int);
PST_LINK_C int _uxtb(int, int);
PST_LINK_C int _uxtb16(int, int);
PST_LINK_C int _uxth(int, int);
PST_LINK_C void __wfe(void);
PST_LINK_C void __wfi(void);

#ifndef __cplusplus
PST_LINK_C int abs(int);
PST_LINK_C long labs(long);
PST_LINK_C double fabs(double);
#endif

PST_LINK_C void* __curpc(void);
PST_LINK_C int __run_address_check(void);

PST_LINK_C unsigned int _hi(double);
PST_LINK_C unsigned int _lo(double);

#pragma tmw code_instrumentation on
#pragma tmw emit

#endif

#endif /* _TI_BUILTINS_ARM_H_ */
