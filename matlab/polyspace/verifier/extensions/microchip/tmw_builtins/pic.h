/*
 * Copyright 2019-2022 The MathWorks, Inc.
 */

#ifndef _MICROCHIP_PIC_H_
#define _MICROCHIP_PIC_H_


#if defined(__TMW_COMPILER_MICROCHIP__) && defined(__TMW_TARGET_PIC__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

#undef __GNUC__
#define __CLANG__ 1

PST_LINK_C void __builtin_enum_label(const char *, int);

#if !defined __PICC__ && !defined __PICCLITE__ && !defined __PICC18__
#define __PICC__
#endif

#pragma tmw code_instrumentation on
#pragma tmw emit

#endif

#endif /* _MICROCHIP_PIC_H_ */
