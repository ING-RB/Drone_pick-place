/* Copyright 1999-2023 The MathWorks, Inc. */

/*
 * This include is designed for Polyspace compilation pass. It is included
 * automatically.
 */
#if !defined(_STDARG_H) || (defined(__PST_POLYSPACE_MODE) && (!defined(va_start) || !defined(va_arg) || !defined(va_end)|| !defined(va_copy)))


#ifdef __cplusplus
extern "C" {
#endif

#if defined(__TMW_COMPILER_IAREW__) && !defined(_DLIB_SMALL_TARGET) && defined(__VER__)
/* On iccrl78 versions before v4.0 _DLIB_SMALL_TARGET must be defined */
#if defined(__TMW_TARGET_RL78__) && (__VER__ < 400)
#define _DLIB_SMALL_TARGET 1
#endif
/* On iccrh850 versions before v2.0 _DLIB_SMALL_TARGET must be defined */
#if defined(__TMW_TARGET_RH850__) && (__VER__ < 200)
#define _DLIB_SMALL_TARGET 1
#endif
#endif // __TMW_COMPILER_IAREW__ && !_DLIB_SMALL_TARGET && __VER__

/* Prevent other libs from defining the types and macros about varargs */
#define _STDARG_H
#define _STDARG_H_
#define _SYS_VA_LIST_H
#define _ANSI_STDARG_H_
#define __GNUC_VA_LIST
#define __INCstdargh
#define _STDARG_INCLUDED
#define _STDARG

#ifdef __MW_CODER_CLANG_TOOLING_COMPILER
typedef __builtin_va_list __gnuc_va_list;
typedef __gnuc_va_list va_list;
#endif

#if defined(__TMW_COMPILER_IAREW__) || defined(__PST_IAR_COMPILER__)
#define _VA_DEFINED
#define _VA_LIST va_list
#else
#define _VA_LIST
#endif // __TMW_COMPILER_IAREW__

#if defined (__DCC__)
typedef va_list _va_list;
#endif // __DCC__

#define _VA_LIST_DEFINED
#define __Iva_list

#define MAX_VARARGS 64

#undef va_start
#undef va_arg
#undef va_end
#undef va_copy
#undef __va_copy

#ifndef __PST_POLYSPACE_MODE
/* Embedded Coder mode */

#ifdef __TMW_EC_CODE_METRICS
/* Embedded Coder Static Code Metrics mode.
   Do not override definitions from installed compilers.
*/
#ifndef va_arg
#ifdef _MSC_VER
#define va_start(ap,name) __crt_va_start(&(ap), name)
#define va_arg(ap,mode) *((mode*)(ap))
#define va_end(ap) __crt_va_end(&(ap))
#define va_copy(to, from) ((to) = (from))
#else /* !_MSC_VER */
/* In Gnu and Clang modes, the front-end declares the proper built-ins. */
#define va_start(ap, name) __builtin_va_start(ap, name)
#define va_arg(ap,mode) *((mode*)(ap))
#define va_end(ap) __builtin_va_end(ap)
#define __va_copy(to, from)  va_copy((to),(from))
#define va_copy(to, from) __builtin_va_copy(to, from)
#endif /* _MSC_VER */
#endif /* va_arg */

/* Ensure the extern declaration of __builtin_va_start/end is done only once. */
#ifndef __TMW_STDARGS_BUILTINS_DECLARED
#define __TMW_STDARGS_BUILTINS_DECLARED

/* The EDG generic compiler and Microsoft mode do not define the following builtins. */
#if defined(__cplusplus) && !defined(__GNUC__) && !defined(__MW_GNU__) && !defined(__clang__)
#ifdef _MSC_VER
extern void __crt_va_start(void*, ...);
extern void __crt_va_end(void*);
#else
extern void __builtin_va_start(va_list, ...);
extern void __builtin_va_end(va_list, ...);
#endif /* _MSC_VER */
#endif /* __cplusplus && !__GNUC__ && !__MW_GNU__ && !__clang__ */

#endif /* __TMW_STDARGS_BUILTINS_DECLARED */

#else /* !__TMW_EC_CODE_METRICS */

#define va_start(ap, name) __builtin_va_start(ap, name)
#define va_arg(ap, mode) __builtin_va_arg(ap, mode)
#define va_end(ap) __builtin_va_end(ap)
#define __va_copy(to, from)  va_copy((to),(from))
#define va_copy(to, from) __builtin_va_copy(to, from)

/* Ensure the extern declaration of __builtin_va_start/end is only performed once. */
#ifndef _STDARGS_BUILTIN_DECLARED
#define _STDARGS_BUILTIN_DECLARED

/* The EDG generic compiler does not define any builtins. */
#if defined(__cplusplus) && !defined(__GNUC__) && !defined(__MW_GNU__) && !defined(__clang__) && !defined(_MSC_VER)
extern void __builtin_va_start(...);
extern void __builtin_va_end(...);
#endif

#endif // _STDARGS_BUILTIN_DECLARED

#endif /* __TMW_EC_CODE_METRICS */

#else // __PST_POLYSPACE_MODE
/* Polyspace mode */

#define va_start(ap, name) (void) (__polyspace_va_start_property_check(name), \
    __polyspace_va_arg_start(), \
    ap  = (va_list) __polyspace_vararg, \
    _polyspace_vararg_position=0)
#define va_arg(ap, mode) (*(mode*)__polyspace_va_arg_deref(__polyspace_vararg, ap, __polyspace_nb_varargs, sizeof(mode)))
#define va_end(ap)  (__polyspace_va_arg_end(ap), \
    ((void)(_polyspace_vararg_position=0)))
#define __va_copy(to, from) va_copy((to),(from))
#define va_copy(to, from) (__polyspace_va_arg_copy(from), \
    (to) = (from))

#if defined __cplusplus && defined __PST_IMPLICIT_USING_STD
/* Implicitly include a using directive for the "std" namespace when option -using-std is active. */
using namespace std;
#endif // __PST_IMPLICIT_USING_STD

#endif // __PST_POLYSPACE_MODE

#ifdef __cplusplus
}
#endif

#endif // !defined(_STDARG_H) || ...
