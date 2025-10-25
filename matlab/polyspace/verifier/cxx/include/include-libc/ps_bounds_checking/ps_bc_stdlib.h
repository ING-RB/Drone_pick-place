#if defined(_STDLIB_H) && !defined(PS_BC_STDLIB_H)

#ifndef __STDC_LIB_EXT1__
#define __STDC_LIB_EXT1__ 1
#endif /* __STDC_LIB_EXT1__ */

#if __STDC_WANT_LIB_EXT1__
#define PS_BC_STDLIB_H

#include "./ps_bc_base.h"

#include "./ps_bc_errno.h"
#include "./ps_bc_stddef.h"

typedef void (*constraint_handler_t)(const char * restrict msg,void * restrict ptr,errno_t error);

/* Runtime-constraint handling */
constraint_handler_t set_constraint_handler_s(constraint_handler_t handler);
void abort_handler_s(const char * restrict msg,void * restrict ptr,errno_t error);
void ignore_handler_s(const char * restrict msg,void * restrict ptr,errno_t error);

/* Communication with the environment */
errno_t getenv_s(size_t * restrict len,char * restrict value, rsize_t maxsize,const char * restrict name);

/* Searching and sorting utilities */
void *bsearch_s(const void *key, const void *base,rsize_t nmemb, rsize_t size,int (*compar)(const void *k, const void *y,void *context),void *context);
errno_t qsort_s(void *base, rsize_t nmemb, rsize_t size,int (*compar)(const void *x, const void *y,void *context),void *context);

/* Multibyte/wide character conversion functions */
errno_t wctomb_s(int * restrict status,char * restrict s,rsize_t smax,wchar_t wc);

/*  Multibyte/wide string conversion functions */
errno_t mbstowcs_s(size_t * restrict retval,wchar_t * restrict dst, rsize_t dstmax,const char * restrict src, rsize_t len);
errno_t wcstombs_s(size_t * restrict retval,char * restrict dst, rsize_t dstmax,const wchar_t * restrict src, rsize_t len);

#endif /* __STDC_WANT_LIB_EXT1__ */

#endif /* defined(_STDLIB_H) && !defined(PS_BC_STDLIB_H) */
