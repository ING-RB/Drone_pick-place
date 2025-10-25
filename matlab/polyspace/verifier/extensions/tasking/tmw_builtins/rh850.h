/*
 * Copyright 2016-2022 The MathWorks, Inc.
 */

#ifndef _TASKING_BUILTINS_RH850_H_
#define _TASKING_BUILTINS_RH850_H_

/*
   Intrinsic Functions, see Section 1.10.5 of the Tasking RH850 v2.2 User's Guide.
*/

#if defined(__TMW_COMPILER_TASKING__) && defined(__TMW_TARGET_RH850__)

#pragma tmw no_emit
#pragma tmw code_instrumentation off

__builtin void * __alloc ( __size_t );
__builtin void __free ( void * );
__builtin __codeptr volatile __get_return_address(void);

__builtin unsigned int volatile __get_psw(void);
__builtin unsigned int volatile __get_eipsw(void);
__builtin unsigned int volatile __get_fepsw(void);
__builtin unsigned int volatile __get_dbpsw(void);
__builtin unsigned int volatile __get_eipc(void);
__builtin unsigned int volatile __get_fepc(void);
__builtin unsigned int volatile __get_dbpc(void);
__builtin unsigned int volatile __get_eiic(void);
__builtin unsigned int volatile __get_fpsr(void);
__builtin unsigned int volatile __get_fpepc(void);

__builtin void volatile __set_psw(unsigned int);
__builtin void volatile __set_eipsw(unsigned int);
__builtin void volatile __set_fepsw(unsigned int);
__builtin void volatile __set_dbpsw(unsigned int);
__builtin void volatile __set_eipc(unsigned int);
__builtin void volatile __set_fepc(unsigned int);
__builtin void volatile __set_dbpc(unsigned int);
__builtin void volatile __set_eiic(unsigned int);
__builtin void volatile __set_fpsr(unsigned int);
__builtin void volatile __set_fpepc(unsigned int);

__builtin void volatile __ldsr_rh(unsigned int, unsigned int, unsigned int);
__builtin unsigned int volatile __stsr_rh(unsigned int, unsigned int);
__builtin void volatile __nop(void);
__builtin void volatile __halt(void);
__builtin void volatile __ei(void);
__builtin void volatile __di(void);
__builtin void volatile __synce(void);
__builtin void volatile __synci(void);
__builtin void volatile __syncm(void);
__builtin void volatile __syncp(void);
__builtin void volatile __dbtrap(void);
__builtin void volatile __syscall(unsigned int);
__builtin void volatile __trap(unsigned int);
__builtin void volatile __fetrap(unsigned int);

#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* __TMW_COMPILER_TASKING__ && __TMW_TARGET_RH850__ */

#endif /* _TASKING_BUILTINS_RH850_H_ */
