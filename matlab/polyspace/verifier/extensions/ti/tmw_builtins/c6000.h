/*
 * Copyright 2017-2022 The MathWorks, Inc.
 */

#ifndef _TI_BUILTINS_C6000_H_
#define _TI_BUILTINS_C6000_H_

#if defined(__TMW_COMPILER_TI__) && defined(__TMW_TARGET_C6000__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

#ifdef __cplusplus
extern "C" namespace std {
#endif /* __cplusplus */
PST_LINK_C void* memcpy(void*, const void*, __SIZE_T_TYPE__);
PST_LINK_C void _nassert(int);
#ifdef __cplusplus
}
#endif

PST_LINK_C void *__cursp(void);

PST_LINK_C unsigned int _disable_interrupts(void);
PST_LINK_C unsigned int _enable_interrupts(void);
PST_LINK_C void _restore_interrupts(unsigned int);

PST_LINK_C double _dinthsp(unsigned int);
PST_LINK_C double _dinthspu(unsigned int);
PST_LINK_C double _dintsp(long long);
PST_LINK_C double _dintspu(long long);

PST_LINK_C double _dmpysp(double, double);
PST_LINK_C unsigned int _dotpu4(unsigned int, unsigned int);
PST_LINK_C long long _dpackhl2(long long, long long);
PST_LINK_C long long _dspint(double);
PST_LINK_C unsigned int _dspinth(double);
PST_LINK_C double _dsubsp(double, double);
PST_LINK_C void _mark(unsigned int);
PST_LINK_C double _mpy2(int, int);
PST_LINK_C double _mpyhi(int, int);
PST_LINK_C double _mpyid(int, int);
PST_LINK_C double _mpyli(int, int);
PST_LINK_C double _mpysu4(int, unsigned int);
PST_LINK_C double _mpyu4(unsigned int, unsigned int);
PST_LINK_C double _smpy2(int, int);

PST_LINK_C __int40_t _labs(__int40_t);
PST_LINK_C int _abs2(int);
PST_LINK_C int _add2(int, int);
PST_LINK_C int _add4(int, int);
PST_LINK_C long long _addsub(int, int);
PST_LINK_C long long _addsub2(unsigned int, unsigned int);
PST_LINK_C int _avg2(int, int);
PST_LINK_C unsigned _avgu4(unsigned, unsigned);
PST_LINK_C unsigned _bitc4(unsigned);
PST_LINK_C unsigned _bitr(unsigned);
PST_LINK_C unsigned _clr(unsigned, unsigned, unsigned);
PST_LINK_C unsigned _clrr(unsigned, int);
PST_LINK_C int _cmpeq2(int, int);
PST_LINK_C int _cmpeq4(int, int);
PST_LINK_C int _cmpgt2(int, int);
PST_LINK_C unsigned _cmpgtu4(unsigned, unsigned);
PST_LINK_C long long _cmpy(unsigned, unsigned);
PST_LINK_C unsigned _cmpyr(unsigned, unsigned);
PST_LINK_C unsigned _cmpyr1(unsigned, unsigned);
PST_LINK_C long long _ddotp4(unsigned, unsigned);
PST_LINK_C long long _ddotph2(long long, unsigned);
PST_LINK_C long long _ddotpl2(long long, unsigned);
PST_LINK_C unsigned _ddotph2r(long long, unsigned);
PST_LINK_C unsigned _ddotpl2r(long long, unsigned);
PST_LINK_C unsigned _deal(unsigned);
PST_LINK_C long long _dmv(unsigned int, unsigned int);
PST_LINK_C int _dotp2(int, int);
PST_LINK_C __int40_t _ldotp2(int, int);
PST_LINK_C int _dotpn2(int, int);
PST_LINK_C int _dotpnrsu2(int, unsigned);
PST_LINK_C int _dotprsu2(int, unsigned);
PST_LINK_C int _dotpsu4(int, unsigned);
PST_LINK_C long long _dpack2(unsigned, unsigned);
PST_LINK_C long long _dpackx2(unsigned, unsigned);
PST_LINK_C __int40_t _dtol(double);
PST_LINK_C int _ext(int, unsigned, unsigned);
PST_LINK_C int _extr(int, int);
PST_LINK_C unsigned _extu(unsigned, unsigned, unsigned);
PST_LINK_C unsigned _extur(unsigned, int);
PST_LINK_C unsigned _ftoi(float);
PST_LINK_C unsigned _gmpy(unsigned, unsigned);
PST_LINK_C int _gmpy4(int, int);
PST_LINK_C unsigned _hi(double);
PST_LINK_C unsigned _hill(long long);
PST_LINK_C double _itod(unsigned, unsigned);
PST_LINK_C float _itof(unsigned);
PST_LINK_C long long _itoll(unsigned, unsigned);
PST_LINK_C unsigned _lmbd(unsigned, unsigned);
PST_LINK_C unsigned _lo(double);
PST_LINK_C unsigned _loll(long long);
PST_LINK_C double _ltod(__int40_t);
PST_LINK_C double _lltod(long long);
PST_LINK_C int _max2(int, int);
PST_LINK_C int _min2(int, int);
PST_LINK_C unsigned _maxu4(unsigned, unsigned);
PST_LINK_C unsigned _minu4(unsigned, unsigned);
PST_LINK_C long long _dtoll(double);
PST_LINK_C int _mpy(int, int);
PST_LINK_C int _mpyus(unsigned, int);
PST_LINK_C int _mpysu(int, unsigned);
PST_LINK_C unsigned _mpyu(unsigned, unsigned);
PST_LINK_C long long _mpy2ir(unsigned int, int);
PST_LINK_C long long _mpy2ll(int, int);
PST_LINK_C int _mpy32(int, int);
PST_LINK_C long long _mpy32ll(int, int);
PST_LINK_C long long _mpy32su(int, unsigned int);
PST_LINK_C long long _mpy32us(unsigned, int);
PST_LINK_C long long _mpy32u(unsigned, unsigned);
PST_LINK_C int _mpyh(int, int);
PST_LINK_C int _mpyhus(unsigned, int);
PST_LINK_C int _mpyhsu(int, unsigned);
PST_LINK_C unsigned _mpyhu(unsigned, unsigned);
PST_LINK_C long long _mpyhill(int, int);
PST_LINK_C long long _mpylill(int, int);
PST_LINK_C int _mpyhir(int, int);
PST_LINK_C int _mpylir(int, int);
PST_LINK_C int _mpyhl(int, int);
PST_LINK_C int _mpyhuls(unsigned, int);
PST_LINK_C int _mpyhslu(int, unsigned);
PST_LINK_C unsigned _mpyhlu(unsigned, unsigned);
PST_LINK_C int _mpylh(int, int);
PST_LINK_C int _mpyluhs(unsigned, int);
PST_LINK_C int _mpylshu(int, unsigned);
PST_LINK_C unsigned _mpylhu(unsigned, unsigned);
PST_LINK_C long long _mpysu4ll(int, unsigned);
PST_LINK_C long long _mpyu4ll(unsigned, unsigned);
PST_LINK_C int _mvd(int);

#ifndef __cplusplus
PST_LINK_C void _nassert(int);
#endif

PST_LINK_C unsigned _norm(int);
PST_LINK_C unsigned _lnorm(__int40_t);
PST_LINK_C unsigned _pack2(unsigned, unsigned);
PST_LINK_C unsigned _packh2(unsigned, unsigned);
PST_LINK_C unsigned _packh4(unsigned, unsigned);
PST_LINK_C unsigned _packl4(unsigned, unsigned);
PST_LINK_C unsigned _packhl2(unsigned, unsigned);
PST_LINK_C unsigned _packlh2(unsigned, unsigned);
PST_LINK_C unsigned _rotl(unsigned, unsigned);
PST_LINK_C unsigned int _rpack2(unsigned int, unsigned int);

PST_LINK_C int _sadd(int, int);
PST_LINK_C __int40_t _lsadd(int, __int40_t);
PST_LINK_C int _sadd2(int, int);
PST_LINK_C int _saddus2(unsigned, int);
PST_LINK_C long long _saddsub(int, int);
PST_LINK_C long long _saddsub2(unsigned, unsigned);
PST_LINK_C unsigned _saddu4(unsigned, unsigned);
PST_LINK_C int _sat(__int40_t);
PST_LINK_C unsigned _set(unsigned, unsigned, unsigned);
PST_LINK_C unsigned _setr(unsigned int, int);
PST_LINK_C unsigned _shfl(unsigned);
PST_LINK_C long long _shfl3(unsigned, unsigned);
PST_LINK_C unsigned _shlmb(unsigned, unsigned);
PST_LINK_C unsigned _shrmb(unsigned, unsigned);
PST_LINK_C int _shr2(int, unsigned);
PST_LINK_C unsigned int _shru2(unsigned int, unsigned);
PST_LINK_C int _smpy(int, int);
PST_LINK_C int _smpyh(int, int);
PST_LINK_C int _smpyhl(int, int);
PST_LINK_C int _smpylh(int, int);
PST_LINK_C long long _smpy2ll(int, int);
PST_LINK_C int _smpy32(int, int);
PST_LINK_C int _spack2(int, int);
PST_LINK_C unsigned _spacku4(int, int);
PST_LINK_C int _sshl(int, unsigned);
PST_LINK_C int _sshvl(int, int);
PST_LINK_C int _sshvr(int, int);
PST_LINK_C int _ssub(int, int);
PST_LINK_C __int40_t _lssub(int, __int40_t);
PST_LINK_C int _ssub2(int, int);
PST_LINK_C int _sub4(int, int);
PST_LINK_C int _subabs4(int, int);
PST_LINK_C unsigned _subc(unsigned, unsigned);
PST_LINK_C int _sub2(int, int);
PST_LINK_C unsigned _swap4(unsigned);
PST_LINK_C unsigned _unpkhu4(unsigned);
PST_LINK_C unsigned _unpklu4(unsigned);
PST_LINK_C unsigned _xormpy(unsigned, unsigned);
PST_LINK_C unsigned _xpnd2(unsigned);
PST_LINK_C unsigned _xpnd4(unsigned);


PST_LINK_C int _dpint(double);
PST_LINK_C double _fabs(double);
PST_LINK_C float _fabsf(float);
PST_LINK_C long long _mpyidll(int, int);
PST_LINK_C double _mpysp2dp(float, float);
PST_LINK_C double _mpyspdp(float, double);
PST_LINK_C double _rcpdp(double);
PST_LINK_C float _rcpsp(float);
PST_LINK_C double _rsqrdp(double);
PST_LINK_C float _rsqrsp(float);
PST_LINK_C int _spint(float);
PST_LINK_C long long _ccmpy32r1(long long, long long);
PST_LINK_C long long _cmpy32r1(long long, long long);
PST_LINK_C double _complex_conjugate_mpysp(double, double);
PST_LINK_C double _complex_mpysp(double, double);
PST_LINK_C int _crot90(int);
PST_LINK_C int _crot270(int);
PST_LINK_C long long _dadd(long long, long long);
PST_LINK_C long long _dadd2(long long, long long);
PST_LINK_C long long _dadd_c(int, long long);
PST_LINK_C long long _dapys2(long long, long long);
PST_LINK_C long long _davg2(long long, long long);
PST_LINK_C long long _davgnr2(long long, long long);
PST_LINK_C long long _davgnru4(long long, long long);
PST_LINK_C long long _davgu4(long long, long long);
PST_LINK_C long long _dccmpyr1(long long, long long);
PST_LINK_C unsigned _dcmpeq2(long long, long long);
PST_LINK_C unsigned _dcmpeq4(long long, long long);
PST_LINK_C unsigned _dcmpgt2(long long, long long);
PST_LINK_C unsigned _dcmpgtu4(long long, long long);
PST_LINK_C long long _dcmpyr1(long long, long long);
PST_LINK_C long long _dcrot90(long long);
PST_LINK_C long long _dcrot270(long long);
PST_LINK_C long long _dmax2(long long, long long);
PST_LINK_C long long _dmaxu4(long long, long long);
PST_LINK_C long long _dmin2(long long, long long);
PST_LINK_C long long _dminu4(long long, long long);
PST_LINK_C long long _dmvd(int, int);
PST_LINK_C int _dotp4h(long long, long long);
PST_LINK_C long long _dotp4hll(long long, long long);
PST_LINK_C int _dotpsu4h(long long, long long);
PST_LINK_C long long _dotpsu4hll(long long, long long);
PST_LINK_C long long _dpackh2(long long, long long);
PST_LINK_C long long _dpackh4(long long, long long);
PST_LINK_C long long _dpacklh2(long long, long long);
PST_LINK_C long long _dpacklh4(unsigned, unsigned);
PST_LINK_C long long _dpackl2(long long, long long);
PST_LINK_C long long _dpackl4(long long, long long);
PST_LINK_C long long _dsadd(long long, long long);
PST_LINK_C long long _dsadd2(long long, long long);
PST_LINK_C long long _dshl(long long, unsigned);
PST_LINK_C long long _dshl2(long long, unsigned);
PST_LINK_C long long _dshr(long long, unsigned);
PST_LINK_C long long _dshr2(long long, unsigned);
PST_LINK_C long long _dshru(long long, unsigned);
PST_LINK_C long long _dshru2(long long, unsigned);
PST_LINK_C long long _dspacku4(long long, long long);
PST_LINK_C long long _dssub(long long, long long);
PST_LINK_C long long _dssub2(long long, long long);
PST_LINK_C long long _dsub(long long, long long);
PST_LINK_C long long _dsub2(long long, long long);
PST_LINK_C long long _dxpnd2(unsigned);
PST_LINK_C long long _dxpnd4(unsigned);
PST_LINK_C int _land(int, int);
PST_LINK_C int _landn(int, int);
PST_LINK_C int _lor(int, int);
PST_LINK_C void _mfence(void);
PST_LINK_C long long _mpyu2(unsigned, unsigned);
PST_LINK_C unsigned _shl2(unsigned, unsigned);
PST_LINK_C long long _unpkbu4(unsigned);
PST_LINK_C long long _unpkh2(unsigned);
PST_LINK_C long long _unpkhu2(unsigned);
PST_LINK_C long long _xorll_c(int, long long);

PST_LINK_C double _ftod(float, float);
PST_LINK_C float _hif(double);
PST_LINK_C float _lof(double);
PST_LINK_C void* __c6xabi_get_tp(void);
PST_LINK_C int _abs(int);
PST_LINK_C double _daddsp(double, double);

#ifndef __cplusplus
PST_LINK_C int abs(int);
PST_LINK_C long labs(long);
PST_LINK_C double fabs(double);
#endif

#pragma tmw code_instrumentation on
#pragma tmw emit

#endif

#endif /* _TI_BUILTINS_C6000_H_ */
