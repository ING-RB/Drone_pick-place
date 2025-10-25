/*
 * Copyright 2016-2022 The MathWorks, Inc.
 */

#ifndef _TASKING_BUILTINS_C166_H_
#define _TASKING_BUILTINS_C166_H_

#ifdef __cplusplus
extern "C" {
#endif

/*
   Intrinsic Functions, see Section 1.14.5 of the Tasking C166 v4.0 User's Guide.
*/

#if defined(__TMW_COMPILER_TASKING__) && defined(__TMW_TARGET_C166__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

#ifndef __cplusplus
typedef char * __dotdotdot_t;
typedef void __near * volatile __alloc_t;
typedef void __far * __mkfp_t;
typedef __near void * volatile __getsetsp_t;
#endif

#define __mksp(sof,seg) ((void __shuge *)((unsigned long)(sof) | ((unsigned long)(seg) << 16)))
#define __mkhp(sof,seg) ((void __huge *)((unsigned long)(sof) | ((unsigned long)(seg) << 16)))
#define __pag(address) ((unsigned int)(((unsigned long)(address)) >> 14))
#define __pof(address) (((unsigned int)(address)) & 0x3fff)
#define __seg(address) ((unsigned int)(((unsigned long)(address)) >> 16))
#define __sof(address) ((unsigned int)((unsigned long)(address)))
#define __mul32(a,b) ((signed long)((signed int)(a)) * (signed int)(b))
#define __mulu32(a,b) ((unsigned long)((unsigned int)(a)) *(unsigned int)(b))
#define __getbit(obj,offset) _Pragma("getbit on") ((__bit)(((obj) >> (offset)) & 1)) _Pragma("getbit off")
#define __putbit(value,obj,offset) _Pragma("putbit on") ((obj) = (((obj) & ~((__typeof__((obj)))1 << (offset))) | ((__typeof__((obj)))((__bit)(value)) << (offset)))) _Pragma("putbit off")
#define __testclear(obj) _Pragma("trace -block") _Pragma("profiling off") ((obj) != 1 ? 0 : ((obj) = 0, 1)) _Pragma("profiling restore") _Pragma("trace restore")
#define __testset(obj) _Pragma("trace -block") _Pragma("profiling off") ((obj) != 0 ? 0 : ((obj) = 1, 1)) _Pragma("profiling restore") _Pragma("trace restore")

#ifdef __cplusplus
__builtin char * __dotdotdot__( void );
__builtin void __near * volatile __alloc( __size_t size );
__builtin void __free( void __near * buffer );
__builtin void __far * __mkfp( unsigned int pof, unsigned int pag );
__builtin  __near void * volatile __getsp( void );
__builtin void __setsp(  __near void * volatile stack );
__builtin void __bfld( unsigned int * operand, unsigned short mask, unsigned short value );
#else
__builtin __dotdotdot_t __dotdotdot__( void );
__builtin __alloc_t __alloc( __size_t size );
__builtin void __free( void __unaligned __near * buffer );
__builtin __mkfp_t __mkfp( unsigned int pof, unsigned int pag );
__builtin __getsetsp_t __getsp( void );
__builtin void __setsp( __getsetsp_t stack );
__builtin void __bfld( unsigned int __unaligned * operand, unsigned short mask, unsigned short value );
#endif

__builtin __codeptr __get_return_address( void );
__builtin unsigned int __rol( unsigned int operand, unsigned int count );
__builtin unsigned int __ror( unsigned int operand, unsigned int count );
__builtin signed int __div32( signed long numerator, signed int denominator );
__builtin signed int __mod32( signed long numerator, signed int denominator );
__builtin unsigned int __divu32( unsigned long numerator, unsigned int denominator );
__builtin unsigned int __modu32( unsigned long numerator, unsigned int denominator );
__builtin void __int166( unsigned char trapno );
__builtin void __idle( void );
__builtin void __nop( void );
__builtin unsigned int __prior( unsigned int value );
__builtin void __pwrdn( void );
__builtin void __srvwdt( void );
__builtin void __diswdt( void );
__builtin void __enwdt( void ); /* only supported for super10 / xc16x cores */
__builtin void __einit( void );
__builtin void __sat( void );
__builtin void __nosat( void );
__builtin void __scale( void );
__builtin void __noscale( void );
__builtin void __CoNOP( void );
__builtin void __CoLOAD( signed long value );
__builtin void __CoLOAD2( signed long value );
__builtin void __CoADD( signed long value );
__builtin void __CoADD2( signed long value );
__builtin void __CoSUB( signed long value );
__builtin void __CoSUB2( signed long value );
__builtin void __CoMIN( signed long value );
__builtin void __CoMAX( signed long value );
__builtin void __CoMAC( signed int a, signed int b );
__builtin void __CoMACsu( signed int a, unsigned int b );
__builtin void __CoMACus( unsigned int a, signed int b );
__builtin void __CoMACu( unsigned int a, unsigned int b );
__builtin void __CoMAC_min( signed int a, signed int b );
__builtin void __CoMACsu_min( signed int a, unsigned int b );
__builtin void __CoMACus_min( unsigned int a, signed int b );
__builtin void __CoMACu_min( unsigned int a, unsigned int b );
__builtin void __CoMUL( signed int a, signed int b );
__builtin void __CoMULsu( signed int a, unsigned int b );
__builtin void __CoMULus( unsigned int a, signed int b );
__builtin void __CoMULu( unsigned int a, unsigned int b );
__builtin void __CoMUL_min( signed int a, signed int b );
__builtin void __CoMULsu_min( signed int a, unsigned int b );
__builtin void __CoMULus_min( unsigned int a, signed int b );
__builtin void __CoMULu_min( unsigned int a, unsigned int b );
__builtin void __CoASHR( unsigned int count );
__builtin void __CoSHR( unsigned int count );
__builtin void __CoSHL( unsigned int count );
__builtin void __CoABS( void );
__builtin void __CoNEG( void );
__builtin void __CoRND( void );
__builtin unsigned int __CoCMP( signed long value );
__builtin long __CoSTORE( void );
__builtin int __CoSTOREMAL( void );
__builtin int __CoSTOREMAH( void );
__builtin int __CoSTOREMSW( void );
__builtin int __CoSTOREMAS( void );

#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* __TMW_COMPILER_TASKING__ && __TMW_TARGET_C166__ */

#ifdef __cplusplus
};
#endif

#endif /* _TASKING_BUILTINS_C166_H_ */
