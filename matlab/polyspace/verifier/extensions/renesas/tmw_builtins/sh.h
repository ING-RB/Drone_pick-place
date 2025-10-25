/*
 * Copyright 2019-2022 The MathWorks, Inc.
 */

#ifndef _RENESAS_BUILTINS_SH_H_
#define _RENESAS_BUILTINS_SH_H_

/*
 * Intrinsic Functions from Renesas CC-RL version V1.05.00.
 */

#if defined(__TMW_COMPILER_RENESAS__) && defined(__TMW_TARGET_SH__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

/* At least one family should be selected */
#if !defined _SH1 && !defined _SH2 && !defined _SH2E && !defined _SH2A && !defined _SH2AFPU && !defined _SH2DSP && !defined _SH3 && !defined _SH3DSP && !defined _SH4 && !defined _SH4A && !defined _SH4ALDSP
#define _SH4ALDSP
#endif

PST_LINK_C void _builtin_add4(float[], float[], float[]);
PST_LINK_C long _builtin_addc(long, long);
PST_LINK_C long _builtin_addv(long, long);
PST_LINK_C void _builtin_bclr(unsigned char *, unsigned char);
PST_LINK_C void _builtin_bcopy(unsigned char *, unsigned char, unsigned char *, unsigned char);
PST_LINK_C void _builtin_bnotcopy(unsigned char *, unsigned char, unsigned char *, unsigned char);
PST_LINK_C void _builtin_bset(unsigned char *, unsigned char);
PST_LINK_C long _builtin_clipsb(long);
PST_LINK_C long _builtin_clipsw(long);
PST_LINK_C unsigned long _builtin_clipub(unsigned long);
PST_LINK_C unsigned long _builtin_clipuw(unsigned long);
PST_LINK_C void _builtin_clr_circ(void);
PST_LINK_C void _builtin_clrt(void);
PST_LINK_C int _builtin_div0s(long, long);
PST_LINK_C void _builtin_div0u(void);
PST_LINK_C unsigned long _builtin_div1(unsigned long, unsigned long);
PST_LINK_C long _builtin_dmuls_h(long, long);
PST_LINK_C unsigned long _builtin_dmuls_l(long, long);
PST_LINK_C unsigned long _builtin_dmulu_h(unsigned long, unsigned long);
PST_LINK_C unsigned long _builtin_dmulu_l(unsigned long, unsigned long);
PST_LINK_C unsigned long _builtin_end_cnvl(unsigned long);
PST_LINK_C double _builtin_fabs(double);
PST_LINK_C float _builtin_fabsf(float);
PST_LINK_C float _builtin_fcosa(int);
PST_LINK_C float _builtin_fipr(float a1[], float b1[]);
PST_LINK_C void _builtin_fsca(long ,float *,float *);
PST_LINK_C float _builtin_fsina(int);
PST_LINK_C float _builtin_fsrra(float);
PST_LINK_C void _builtin_ftrv(float a1[], float b1[]);
PST_LINK_C void _builtin_ftrvadd(float a1[], float b1[], float c1[]);
PST_LINK_C void _builtin_ftrvsub(float a1[], float b1[], float c1[]);
PST_LINK_C void _builtin_gbr_and_byte(int, unsigned char);
PST_LINK_C void _builtin_gbr_or_byte(int, unsigned char);
PST_LINK_C unsigned char _builtin_gbr_read_byte(int);
PST_LINK_C unsigned short _builtin_gbr_read_word(int);
PST_LINK_C unsigned long _builtin_gbr_read_long(int);
PST_LINK_C int _builtin_gbr_tst_byte(int, unsigned char);
PST_LINK_C void _builtin_gbr_write_byte(int, unsigned char);
PST_LINK_C void _builtin_gbr_write_word(int, unsigned short);
PST_LINK_C void _builtin_gbr_write_long(int, unsigned long);
PST_LINK_C void _builtin_gbr_xor_byte(int, unsigned char);
PST_LINK_C int _builtin_get_cr(void);
PST_LINK_C int _builtin_get_fpscr(void);
PST_LINK_C void *_builtin_get_gbr(void);
PST_LINK_C int _builtin_get_imask(void);
PST_LINK_C void *_builtin_get_tbr(void);
PST_LINK_C void *_builtin_get_vbr(void);
PST_LINK_C void _builtin_icbi(void *);
PST_LINK_C void _builtin_ld_ext(float [][4]);
PST_LINK_C void _builtin_ldtlb(void);
PST_LINK_C int _builtin_macl(int *, int *, unsigned int);
PST_LINK_C int _builtin_macll(int *, int *, unsigned int, unsigned int);
PST_LINK_C int _builtin_macw(short *, short *, unsigned int);
PST_LINK_C int _builtin_macwl(short *, short *, unsigned int, unsigned int);
PST_LINK_C int _builtin_movt(void);
PST_LINK_C void _builtin_mtrx4mul(float [][4], float [][4]);
PST_LINK_C void _builtin_mtrx4muladd(float [][4], float [][4], float [][4]);
PST_LINK_C void _builtin_mtrx4mulsub(float [][4], float [][4], float [][4]);
PST_LINK_C long _builtin_negc(long);
PST_LINK_C void _builtin_nop(void);
PST_LINK_C void _builtin_ocbi(void *);
PST_LINK_C void _builtin_ocbp(void *);
PST_LINK_C void _builtin_ocbwb(void *);
PST_LINK_C int _builtin_ovf_addc(long, long);
PST_LINK_C int _builtin_ovf_addv(long, long);
PST_LINK_C void _builtin_prefetch(void *);
PST_LINK_C void _builtin_prefi(void *);
PST_LINK_C unsigned long _builtin_rotl(unsigned long);
PST_LINK_C unsigned long _builtin_rotr(unsigned long);
PST_LINK_C unsigned long _builtin_rotcl(unsigned long);
PST_LINK_C unsigned long _builtin_rotcr(unsigned long);
PST_LINK_C void _builtin_set_cr(int);
PST_LINK_C void set_cs(unsigned int);
PST_LINK_C void _builtin_set_fpscr(int);
PST_LINK_C void _builtin_set_gbr(void *);
PST_LINK_C void _builtin_set_imask(int);
PST_LINK_C void _builtin_set_tbr(void *);
PST_LINK_C void _builtin_set_vbr(void *);
PST_LINK_C void _builtin_sett(void);
PST_LINK_C long _builtin_shar(long);
PST_LINK_C unsigned long _builtin_shll(unsigned long);
PST_LINK_C unsigned long _builtin_shlr(unsigned long);
PST_LINK_C void _builtin_sleep(void);
PST_LINK_C void _builtin_sleep_i(unsigned int);
PST_LINK_C double _builtin_sqrt(double);
PST_LINK_C float _builtin_sqrtf(float);
PST_LINK_C void _builtin_sr_jsr(void *, int);
PST_LINK_C void _builtin_st_ext(float [][4]);
PST_LINK_C int _builtin_strcmp(const char *, const char *);
PST_LINK_C char *_builtin_strcpy(char *, const char *);
PST_LINK_C void _builtin_sub4(float a1[], float b1[], float c1[]);
PST_LINK_C long _builtin_subc(long, long);
PST_LINK_C long _builtin_subv(long, long);
PST_LINK_C unsigned short _builtin_swapb(unsigned short);
PST_LINK_C unsigned long _builtin_swapw(unsigned long);
PST_LINK_C void _builtin_synco(void);
PST_LINK_C int _builtin_tas(char *);
PST_LINK_C void _builtin_trace(long);
PST_LINK_C int _builtin_trapa(int);
PST_LINK_C int _builtin_trapa_svc(int, int, ...);
PST_LINK_C int _builtin_unf_subc(long, long);
PST_LINK_C int _builtin_unf_subv(long, long);
PST_LINK_C unsigned long _builtin_xtrct(unsigned long, unsigned long);

/*
 * These are available only if -dspc option is used.
 */
#ifdef _DSPC
PST_LINK_C long lfixed_as_long(long __fixed);
PST_LINK_C long __fixed long_as_lfixed(long);
PST_LINK_C long __accum pabs_la(long __accum);
PST_LINK_C __fixed pdmsb_lf(long __fixed);
PST_LINK_C __fixed pdmsb_la(long __accum);
PST_LINK_C __fixed pdmsb_lf(long __fixed);
PST_LINK_C long __accum psha_la(long __accum,int);
PST_LINK_C long __fixed psha_lf(long __fixed, int);
PST_LINK_C __accum rndtoa(long __accum);
PST_LINK_C __fixed rndtof(long __fixed);
#endif

/*
 * Helper macros.
 */

#ifndef __sectop
#define __sectop(section) (void * volatile)0x2000
#endif
#ifndef __secend
#define __secend(section) (void * volatile)0x3000
#endif
#ifndef __secsize
#define __secsize(section) 0x1000U
#endif
#ifndef __inline
#define __inline __pst_inline
#endif

#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* __TMW_COMPILER_RENESAS__ && __TMW_TARGET_SH__ */

#endif /* _RENESAS_BUILTINS_SH_H_ */
