/* Copyright 1999-2024 The MathWorks, Inc. */

/* Used with Visual compiler only */

#ifndef _WIN32
#define _WIN32
#endif

/* Avoid collisions with Visual C++ 2022 C++ headers */
#undef __EDG__

#ifndef STRICT
#define STRICT
#endif
#ifndef _STDCALL_SUPPORTED
#define _STDCALL_SUPPORTED
#endif
#ifndef _INTEGRAL_MAX_BITS
#define _INTEGRAL_MAX_BITS 64
#endif
#ifndef PST_DECL_C
#define PST_DECL_C __cdecl
#endif

#ifndef _WIN64
#ifndef _M_IX86
#define _M_IX86 300
#endif
#else /* _WIN64 */
#ifndef _M_AMD64
#define _M_AMD64
#endif
#ifndef _M_X64
#define _M_X64
#endif
#endif /* _WIN64 */

#if ! defined __cplusplus || ! defined PST_VISUAL
#define __inline inline
#define _inline inline
#define __cdecl
#define _cdecl
#define __stdcall
#define _stdcall
#define __fastcall
#define __int64 long long
#endif

#if (_MSC_VER >= 1400)
#define __PST_CRTNOALIAS __declspec(noalias)
#else
#define __PST_CRTNOALIAS
#endif /* (_MSC_VER >= 1400) */

#ifdef _DLL
#define PST_IMPORT __declspec(dllimport)
#else /* _DLL */
#define PST_IMPORT
#endif /* _DLL */

#ifndef _STDARG_H
#define _STDARG_H_
#if (defined PST_VISUAL) && (_MSC_VER>=1400)
/* Visual 2005 defines va_list stuff in vadefs.h, bypass it */
#define _crt_va_end va_end
#define _crt_va_arg va_arg
#define _crt_va_start va_start
#define _INC_VADEFS
#endif
#endif /* _STDARG_H */

#ifdef __cplusplus
#if (!defined __PST_NO_SEH) && (!defined PST_BUG_FINDER)
namespace /* C++/4971 : need throw (int) somewhere */
{
  inline void __SEH_support()
  {
    throw ((int) 0) ;
  }
}
#endif

/*
 * These macros are set when /GR and /GX Visual command line options
 * are used. Because Polyspace does not have options to deactivate RTTI and
 * exceptions, macros are always defined.
 * User is free to forbid it with -D __PST_NO_CPPRTTI or -D __PST_NO_CPPUNWIND
 * Polyspace command line options.
 */
#ifndef __PST_NO_CPPRTTI
#ifndef _CPPRTTI
#define _CPPRTTI
#endif /* _CPPRTTI */
#endif /* __PST_NO_CPPRTTI */

#ifndef __PST_NO_CPPUNWIND
#define _CPPUNWIND
#endif

/*
 * This set of macros should be defined in top of each file included by
 * <stdafx.h>. Failing to do so can generate a link error.
 * User is free to override these defines by setting them on the Polyspace
 * command line but it is advised in this case to override all of them.
 */

#ifndef WINVER
#define WINVER 0x0600
#endif

#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0600
#endif

#ifndef _WIN32_WINDOWS
#define _WIN32_WINDOWS 0x0600
#endif

#ifndef _WIN32_IE
#define _WIN32_IE 0x0600
#endif

/*
 * wchar.h declares some functions and defines inline for its purposes,
 * ctype.h performs the declaration but not the definition, which may lead to
 * a link error.
 * This define prevents the inline definition.
 * The other choice is to force inclusion of <cwchar>
 */
#define _WCTYPE_INLINE_DEFINED

/* C++17 */
#if _MSC_VER>=1900
#if defined(_M_IX86) || defined(_M_X64) || defined(_M_ARM) || defined(_M_ARM64)
constexpr size_t hardware_constructive_interference_size = 64;
constexpr size_t hardware_destructive_interference_size = 64;
#else /* _M_IX86 || _M_X64 || _M_ARM || _M_ARM64 */
#error Unsupported architecture
#endif /* _M_IX86 || _M_X64 || _M_ARM || _M_ARM64 */
#endif /* _MSC_VER>=1900 */

#endif /* __cplusplus */
