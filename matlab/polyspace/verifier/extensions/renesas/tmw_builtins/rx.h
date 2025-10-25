/*
 * Copyright 2018-2022 The MathWorks, Inc.
 */

#ifndef _RENESAS_BUILTINS_RX_H_
#define _RENESAS_BUILTINS_RX_H_

/*
 * Intrinsic Functions from Renesas CC-RX version V2.07.00.
 */

#if defined(__TMW_COMPILER_RENESAS__) && defined(__TMW_TARGET_RX__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

#ifndef __PST_NO_BUILTIN_FABSF_HIDING
/* The Renesas RX compiler allows multiple declarations of a
 * function with different floating-point parameter types.
 * As this is not allowed in Polyspace, the following trick
 * hides away the uses of the _builtin_fabsf function.
 *
 * In case of issue with this on Polyspace, just define the
 * macro __PST_NO_BUILTIN_FABSF_HIDING to deactivate this
 * behavior.
 */
#define __PST_STRINGIZE_RX(x) id_##x
#define __PST_GETNAME_RX(x) __PST_STRINGIZE_RX(x)
#define _builtin_fabsf __PST_GETNAME_RX(__LINE__)
#endif /* __PST_NO_BUILTIN_FABSF_HIDING */


PST_LINK_C signed long        _builtin_max(signed long, signed long);
PST_LINK_C signed long        _builtin_min(signed long, signed long);
PST_LINK_C unsigned long      _builtin_revl(unsigned long);
PST_LINK_C unsigned long      _builtin_revw(unsigned long);
PST_LINK_C void               _builtin_xchg(signed long *, signed long *);
PST_LINK_C long long          _builtin_rmpab(long long, unsigned long, signed char *, signed char *);
PST_LINK_C long long          _builtin_rmpaw(long long, unsigned long, short *, short *);
PST_LINK_C long long          _builtin_rmpal(long long, unsigned long, long *, long *);
PST_LINK_C unsigned long      _builtin_rolc(unsigned long);
PST_LINK_C unsigned long      _builtin_rorc(unsigned long);
PST_LINK_C unsigned long      _builtin_rotl(unsigned long, unsigned long);
PST_LINK_C unsigned long      _builtin_rotr(unsigned long, unsigned long);
PST_LINK_C void               _builtin_brk(void);
PST_LINK_C void               _builtin_int_exception(signed long);
PST_LINK_C void               _builtin_wait(void);
PST_LINK_C void               _builtin_nop(void);
PST_LINK_C void               _builtin_set_ipl(signed long);
PST_LINK_C unsigned char      _builtin_get_ipl(void);
PST_LINK_C void               _builtin_set_psw(unsigned long);
PST_LINK_C unsigned long      _builtin_get_psw(void);
PST_LINK_C void               _builtin_set_fpsw(unsigned long);
PST_LINK_C unsigned long      _builtin_get_fpsw(void);
PST_LINK_C void               _builtin_set_usp(void *);
PST_LINK_C void *             _builtin_get_usp(void);
PST_LINK_C void               _builtin_set_isp(void *);
PST_LINK_C void *             _builtin_get_isp(void);
PST_LINK_C void               _builtin_set_intb(void *);
PST_LINK_C void *             _builtin_get_intb(void);
PST_LINK_C void               _builtin_set_bpsw(unsigned long);
PST_LINK_C unsigned long      _builtin_get_bpsw(void);
PST_LINK_C void               _builtin_set_bpc(void *);
PST_LINK_C void *             _builtin_get_bpc(void);
PST_LINK_C void               _builtin_set_fintv(void *);
PST_LINK_C void *             _builtin_get_fintv(void);
PST_LINK_C signed long long   _builtin_emul(signed long, signed long);
PST_LINK_C unsigned long long _builtin_emulu(unsigned long, unsigned long);
PST_LINK_C short              _builtin_macw1(short *, short *, unsigned long);
PST_LINK_C short              _builtin_macw2(short *, short *, unsigned long);
PST_LINK_C long               _builtin_macl(short *, short *, unsigned long);
PST_LINK_C void               _builtin_chg_pmusr(void);
PST_LINK_C void               _builtin_set_acc(signed long long data);
PST_LINK_C signed long long   _builtin_get_acc(void);
PST_LINK_C void               _builtin_setpsw_i(void);
PST_LINK_C void               _builtin_clrpsw_i(void);
PST_LINK_C void               _builtin_set_extb(void *);
PST_LINK_C void *             _builtin_get_extb(void);
PST_LINK_C void               __bclr(unsigned char *, unsigned long);
PST_LINK_C void               __bnot(unsigned char *, unsigned long);
PST_LINK_C void               __bset(unsigned char *, unsigned long);


#ifndef __max
#define __max(data1, data2)                _builtin_max(data1, data2)
#endif
#ifndef __min
#define __min(data1, data2)                _builtin_min(data1, data2)
#endif
#ifndef __revl
#define __revl(data)                       _builtin_revl(data)
#endif
#ifndef __revw
#define __revw(data)                       _builtin_revw(data)
#endif
#ifndef __xchg
#define __xchg(data1, data2)               _builtin_xchg(data1, data2)
#endif
#ifndef __rmpab
#define __rmpab(init, count, addr1, addr2) _builtin_rmpab(init, count, addr1, addr2)
#endif
#ifndef __rmpaw
#define __rmpaw(init, count, addr1, addr2) _builtin_rmpaw(init, count, addr1, addr2)
#endif
#ifndef __rmpal
#define __rmpal(init, count, addr1, addr2) _builtin_rmpal(init, count, addr1, addr2)
#endif
#ifndef __rolc
#define __rolc(data)                       _builtin_rolc(data)
#endif
#ifndef __rorc
#define __rorc(data)                       _builtin_rorc(data)
#endif
#ifndef __rotl
#define __rotl(data, num)                  _builtin_rotl(data, num)
#endif
#ifndef __rotr
#define __rotr(data, num)                  _builtin_rotr(data, num)
#endif
#ifndef __brk
#define __brk()                            _builtin_brk()
#endif
#ifndef __int_exception
#define __int_exception(num)               _builtin_int_exception(num)
#endif
#ifndef __wait
#define __wait()                           _builtin_wait()
#endif
#ifndef __nop
#define __nop()                            _builtin_nop()
#endif
#ifndef __set_ipl
#define __set_ipl(level)                   _builtin_set_ipl(level)
#endif
#ifndef __get_ipl
#define __get_ipl()                        _builtin_get_ipl()
#endif
#ifndef __set_psw
#define __set_psw(data)                    _builtin_set_psw(data)
#endif
#ifndef __get_psw
#define __get_psw()                        _builtin_get_psw()
#endif
#ifndef __set_fpsw
#define __set_fpsw(data)                   _builtin_set_fpsw(data)
#endif
#ifndef __get_fpsw
#define __get_fpsw()                       _builtin_get_fpsw()
#endif
#ifndef __set_usp
#define __set_usp(data)                    _builtin_set_usp(data)
#endif
#ifndef __get_usp
#define __get_usp()                        _builtin_get_usp()
#endif
#ifndef __set_isp
#define __set_isp(data)                    _builtin_set_isp(data)
#endif
#ifndef __get_isp
#define __get_isp()                        _builtin_get_isp()
#endif
#ifndef __set_intb
#define __set_intb(data)                   _builtin_set_intb(data)
#endif
#ifndef __get_intb
#define __get_intb()                       _builtin_get_intb()
#endif
#ifndef __set_bpsw
#define __set_bpsw(data)                   _builtin_set_bpsw(data)
#endif
#ifndef __get_bpsw
#define __get_bpsw()                       _builtin_get_bpsw()
#endif
#ifndef __set_bpc
#define __set_bpc(data)                    _builtin_set_bpc(data)
#endif
#ifndef __get_bpc
#define __get_bpc()                        _builtin_get_bpc()
#endif
#ifndef __set_fintv
#define __set_fintv(data)                  _builtin_set_fintv(data)
#endif
#ifndef __get_fintv
#define __get_fintv()                      _builtin_get_fintv()
#endif
#ifndef __emul
#define __emul(data1, data2)               _builtin_emul(data1, data2)
#endif
#ifndef __emulu
#define __emulu(data1, data2)              _builtin_emulu(data1, data2)
#endif
#ifndef __macw1
#define __macw1(data1, data2, count)       _builtin_macw1(data1, data2, count)
#endif
#ifndef __macw2
#define __macw2(data1, data2, count)       _builtin_macw2(data1, data2, count)
#endif
#ifndef __macl
#define __macl(data1, data2, count)        _builtin_macl(data1, data2, count)
#endif
#ifndef __chg_pmusr
#define __chg_pmusr()                      _builtin_chg_pmusr()
#endif
#ifndef __set_acc
#define __set_acc(data)                    _builtin_set_acc(data)
#endif
#ifndef __get_acc
#define __get_acc()                        _builtin_get_acc()
#endif
#ifndef __setpsw_i
#define __setpsw_i()                       _builtin_setpsw_i()
#endif
#ifndef __clrpsw_i
#define __clrpsw_i()                       _builtin_clrpsw_i()
#endif
#ifndef __set_extb
#define __set_extb(data)                   _builtin_set_extb(data)
#endif
#ifndef __get_extb
#define __get_extb()                       _builtin_get_extb()
#endif

#ifndef __sectop
#define __sectop(section) (void * volatile)0x2000
#endif
#ifndef __secend
#define __secend(section) (void * volatile)0x3000
#endif
#ifndef __secsize
#define __secsize(section) 0x1000UL
#endif

#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* __TMW_COMPILER_RENESAS__ && __TMW_TARGET_RX__ */

#endif /* _RENESAS_BUILTINS_RX_H_ */
