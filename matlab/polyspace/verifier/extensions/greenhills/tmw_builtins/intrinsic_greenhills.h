/*
 * Copyright 2017-2022 The MathWorks, Inc.
 */

#ifndef _GREENHILLS_BUILTINS_GLOBAL_H_
#define _GREENHILLS_BUILTINS_GLOBAL_H_

#if defined(__TMW_COMPILER_GREENHILLS__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

extern volatile int __va_ansiarg;
extern volatile int __va_intreg;

extern char __va_iargnum(const char*);
extern char __va_dargnum(const char*);

#define __va_regtyp(atype) __va_ansiarg
#define __va_float(atype)  __va_ansiarg
#define __va_vector(atype)  __va_ansiarg
#define __va_align(atype)  __va_ansiarg

typedef int __ghs_c_int__;

PST_LINK_C void __ghs_noprofile_func(void);
PST_LINK_C void __DI(void);
PST_LINK_C void __EI(void);

#pragma tmw code_instrumentation off
#pragma tmw emit

#endif

#endif /* _GREENHILLS_BUILTINS_GLOBAL_H_ */
