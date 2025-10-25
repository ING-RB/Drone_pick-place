/*
 * Copyright 2017-2022 The MathWorks, Inc.
 */

#ifndef _CODEWARRIOR_BUILTINS_S12Z_H_
#define _CODEWARRIOR_BUILTINS_S12Z_H_

#if defined(__TMW_COMPILER_CODEWARRIOR__) && defined(__TMW_TARGET_S12Z__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

#ifdef __cplusplus
extern "C" {
#endif

signed int      __abs16         (const signed int op);
signed long     __abs32         (const signed long op);
signed char     __abs8          (const signed char op);
signed int      __clb16_16      (const signed int op);
signed int      __clb16_32      (const signed long op);
signed int      __clb16_8       (const signed char op);
signed long     __clb32_16      (const signed int op);
signed long     __clb32_32      (const signed long op);
signed long     __clb32_8       (const signed char op);
signed char     __clb8_16       (const signed int op);
signed char     __clb8_32       (const signed long op);
signed char     __clb8_8        (const signed char op);
void            __clear         (void *src, unsigned long size);
#ifndef __cplusplus
void            __copy          (char *to,char *from, unsigned long size);
#endif
signed int      __qmuls16       (const signed int op1, const signed int op2);
signed long     __qmuls32       (const signed long op1, const signed long op2);
signed long     __qmuls32_16_16 (const signed int op1, const signed int op2);
signed char     __qmuls8        (const signed char op1, const signed char op2);
unsigned int    __qmulu16       (const unsigned int op1, const unsigned int op2);
unsigned long   __qmulu32       (const unsigned long op1, const unsigned long op2);
unsigned long   __qmulu32_16_16 (const unsigned int op1, const unsigned int op2);
unsigned char   __qmulu8        (const unsigned char op1, const unsigned char op2);
signed int      __sat16         (const signed int op);
signed long     __sat32         (const signed long op);
signed char     __sat8          (const signed char op);

#ifdef __cplusplus
}
#endif

#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* __TMW_COMPILER_CODEWARRIOR__ && __TMW_TARGET_S12Z__ */

#endif /* _CODEWARRIOR_BUILTINS_S12Z_H_ */
