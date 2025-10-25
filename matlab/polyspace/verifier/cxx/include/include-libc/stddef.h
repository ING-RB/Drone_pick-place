/* Copyright 2012-2020 The MathWorks, Inc. */

#ifndef _STDDEF_H
#define _STDDEF_H
/* Convenience macros to test the versions of glibc and gcc.
   Use them like this:
   #if __GNUC_PREREQ (2,8)
   ... code requiring gcc 2.8 or later ...
   #endif
   Note - they won't work for gcc1 or glibc1, since the _MINOR macros
   were not defined then.  */
#if defined __GNUC__ && defined __GNUC_MINOR__
# define __GNUC_PREREQ(maj, min) \
        ((__GNUC__ << 16) + __GNUC_MINOR__ >= ((maj) << 16) + (min))
#else
# define __GNUC_PREREQ(maj, min) 0
#endif

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __cplusplus
#  define NULL 0
#else
#  define NULL ((void *)0)
#endif
typedef __SIZE_TYPE__ size_t;

#ifndef __cplusplus
typedef __WCHAR_TYPE__ wchar_t;
#endif

typedef __PTRDIFF_TYPE__ ptrdiff_t;
#if (! defined(__cplusplus)) || (! defined(PST_GNU))
# define offsetof(type, field) ((size_t) &((type *)0)->field)
#else
  /* Polyspace: prefere __builtin_offsetof for gnu */
#if __GNUC_PREREQ (4, 0) && defined PST_GNU
/* Offset of member MEMBER in a struct of type TYPE. */
#define offsetof(TYPE, MEMBER) __builtin_offsetof (TYPE, MEMBER)
#else
# define offsetof(type, field)                            \
  (__offsetof__(reinterpret_cast<size_t>                  \
                (&reinterpret_cast<const volatile char &> \
                 (static_cast<type *>(0)->field))))
#endif
#endif

#if __STDC_VERSION__ >= 201112L || __cplusplus >= 201103L

#if !defined(__CLANG_MAX_ALIGN_T_DEFINED) && !defined(_GCC_MAX_ALIGN_T) && \
    !defined(__DEFINED_max_align_t)
#define __DEFINED_max_align_t
  typedef long double max_align_t;
#endif
#endif

#ifdef __cplusplus
} /* extern "C" */
#endif

/* Polyspace Bounds-checking interfaces - C11 Annex K */
#include <ps_bounds_checking/ps_bc_stddef.h>

#endif /* _STDDEF_H */
