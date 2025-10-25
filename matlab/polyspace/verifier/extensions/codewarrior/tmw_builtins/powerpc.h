/*
 * Copyright 2017-2022 The MathWorks, Inc.
 */

#ifndef _CODEWARRIOR_BUILTINS_POWERPC_H_
#define _CODEWARRIOR_BUILTINS_POWERPC_H_

#if defined(__TMW_COMPILER_CODEWARRIOR__) && defined(__TMW_TARGET_POWERPC__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

#ifdef __cplusplus
extern "C" {
#endif

unsigned int __builtin___count_leading_zero32(unsigned int) __attribute__((nothrow)) __attribute__((const));
unsigned int __builtin___count_leading_zero64(unsigned long long) __attribute__((nothrow)) __attribute__((const));
unsigned int __builtin___count_trailing_zero32(unsigned int) __attribute__((nothrow)) __attribute__((const));
unsigned int __builtin___count_trailing_zero64(unsigned long long) __attribute__((nothrow)) __attribute__((const));
double __builtin_fma(double, double, double) __attribute__((nothrow)) __attribute__((const));
float __builtin_fmaf(float, float, float) __attribute__((nothrow)) __attribute__((const));
unsigned int __builtin___rotate_left32(unsigned int, int) __attribute__((nothrow)) __attribute__((const));
unsigned int __builtin___rotate_right32(unsigned int, int) __attribute__((nothrow)) __attribute__((const));

void __eieio(void);
void __sync(void);
void __isync(void);

int __abs(int);
double __fabs(double);                                /* fix documentation */
double __fnabs(double);                               /* fix documentation */
long __labs(long);

unsigned int __lhbrx(const void *, int);
unsigned int __lwbrx(const void *, int);
void __sthbrx(unsigned short, const void *, int);
void __stwbrx(unsigned int, const void *, int);

double __setflm(double);                              /* fix documentation */

int __rlwinm(int, int, int, int);
int __rlwnm(int, int, int, int);
int __rlwimi(int, int, int, int, int);
int __cntlzw(unsigned int);                           /* fix documentation */

void __dcbf(const void *, int);
void __dcbt(const void *, int);
void __dcbst(const void *, int);
void __dcbtst(const void *, int);
void __dcbz(const void *, int);
void __dcba(const void *, int);

int __mulhw(int, int);
unsigned int __mulhwu(unsigned int, unsigned int);
double __fmadd(double, double, double);
double __fmsub(double, double, double);
double __fnmadd(double, double, double);
double __fnmsub(double, double, double);
float __fmadds(float, float, float);
float __fmsubs(float, float, float);
float __fnmadds(float, float, float);
float __fnmsubs(float, float, float);
double __mffs(void);
float __fabsf(float);
float __fnabsf(float);

void *__alloca(unsigned int);                         /* fix documentation */
char *__strcpy(char *, const char *);
void *__memcpy(void *, const void *, unsigned long);

#ifdef __cplusplus
};
#endif

#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* __TMW_COMPILER_CODEWARRIOR__ && __TMW_TARGET_POWERPC__ */

#endif /* _CODEWARRIOR_BUILTINS_POWERPC_H_ */
