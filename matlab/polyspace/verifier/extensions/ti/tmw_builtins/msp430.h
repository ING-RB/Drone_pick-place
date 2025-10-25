/*
 * Copyright 2017-2022 The MathWorks, Inc.
 */

#ifndef _TI_BUILTINS_MSP430_H_
#define _TI_BUILTINS_MSP430_H_

#if defined(__TMW_COMPILER_TI__) && defined(__TMW_TARGET_MSP430__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

PST_LINK_C unsigned short __bcd_add_short(unsigned short, unsigned short);
PST_LINK_C unsigned long __bcd_add_long(unsigned long, unsigned long);
PST_LINK_C unsigned short __bic_SR_register(unsigned short);
PST_LINK_C unsigned short __bic_SR_register_on_exit(unsigned short);
PST_LINK_C unsigned short __bis_SR_register(unsigned short);
PST_LINK_C unsigned short __bis_SR_register_on_exit(unsigned short);
PST_LINK_C unsigned long __data16_read_addr(unsigned short);
PST_LINK_C void __data16_write_addr(unsigned short, unsigned long);
PST_LINK_C unsigned char __data20_read_char(unsigned long);
PST_LINK_C unsigned long __data20_read_long(unsigned long);
PST_LINK_C unsigned short __data20_read_short(unsigned long);
PST_LINK_C void __data20_write_char(unsigned long, unsigned char);
PST_LINK_C void __data20_write_long(unsigned long, unsigned long);
PST_LINK_C void __data20_write_short(unsigned long, unsigned short);
PST_LINK_C void __delay_cycles(unsigned long);
PST_LINK_C void __disable_interrupt(void);
PST_LINK_C void __enable_interrupt(void);
PST_LINK_C unsigned int __even_in_range(unsigned int, unsigned int);
PST_LINK_C unsigned short __get_R4_register(void);
PST_LINK_C unsigned short __get_R5_register(void);
PST_LINK_C unsigned short __get_SP_register(void);
PST_LINK_C unsigned short __get_SR_register(void);
PST_LINK_C unsigned short __get_SR_register_on_exit(void);
PST_LINK_C void __no_operation(void);
PST_LINK_C void __op_code(unsigned short);
PST_LINK_C short __saturated_add_signed_short(short src1, short);
PST_LINK_C long __saturated_add_signed_long(long src1, long);
PST_LINK_C short __saturated_sub_signed_short(short src1, short);
PST_LINK_C long __saturated_sub_signed_long(long src1, long);
PST_LINK_C void __set_interrupt_state(unsigned short);
PST_LINK_C void __set_R4_register(unsigned short);
PST_LINK_C void __set_R5_register(unsigned short);
PST_LINK_C void __set_SP_register(unsigned short);

PST_LINK_C unsigned long __f32_bits_as_u32(float);
PST_LINK_C unsigned long long __f64_bits_as_u64(long double);
PST_LINK_C float __u32_bits_as_f32(unsigned long);
PST_LINK_C long double __u64_bits_as_f64(unsigned long long);

#ifndef __cplusplus
PST_LINK_C int abs(int);
PST_LINK_C long labs(long);
PST_LINK_C double fabs(double);
#endif

#pragma tmw code_instrumentation on
#pragma tmw emit

#endif

#endif /* _TI_BUILTINS_MSP430_H_ */
