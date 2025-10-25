#if defined(_WCHAR_H) && !defined(PS_BC_WCHAR_H)

#ifndef __STDC_LIB_EXT1__
#define __STDC_LIB_EXT1__ 1
#endif /* __STDC_LIB_EXT1__ */

#if __STDC_WANT_LIB_EXT1__
#define PS_BC_WCHAR_H

#include "./ps_bc_base.h"

#include "./ps_bc_errno.h"
#include "./ps_bc_stddef.h"

/* Formatted wide character input/output functions */
int fwprintf_s(FILE * restrict stream,const wchar_t * restrict format, ...);
int fwscanf_s(FILE * restrict stream,const wchar_t * restrict format, ...);
int snwprintf_s(wchar_t * restrict s,rsize_t n,const wchar_t * restrict format, ...);
int swprintf_s(wchar_t * restrict s, rsize_t n,const wchar_t * restrict format, ...);
int swscanf_s(const wchar_t * restrict s,const wchar_t * restrict format, ...);
int vfwprintf_s(FILE * restrict stream,const wchar_t * restrict format,va_list arg);
int vfwscanf_s(FILE * restrict stream,const wchar_t * restrict format, va_list arg);
int vsnwprintf_s(wchar_t * restrict s,rsize_t n,const wchar_t * restrict format,va_list arg);
int vswprintf_s(wchar_t * restrict s,rsize_t n,const wchar_t * restrict format,va_list arg);
int vswscanf_s(const wchar_t * restrict s,const wchar_t * restrict format,va_list arg);
int vwprintf_s(const wchar_t * restrict format,va_list arg);
int vwscanf_s(const wchar_t * restrict format,va_list arg);
int wprintf_s(const wchar_t * restrict format, ...);
int wscanf_s(const wchar_t * restrict format, ...);

/* General wide string utilities */
 /* Wide string copying functions */
errno_t wcscpy_s(wchar_t * restrict s1,rsize_t s1max,const wchar_t * restrict s2);
errno_t wcsncpy_s(wchar_t * restrict s1,rsize_t s1max,const wchar_t * restrict s2,rsize_t n);
errno_t wmemcpy_s(wchar_t * restrict s1,rsize_t s1max,const wchar_t * restrict s2,rsize_t n);
errno_t wmemmove_s(wchar_t *s1, rsize_t s1max,const wchar_t *s2, rsize_t n);

 /* Wide string concatenation functions */
errno_t wcscat_s(wchar_t * restrict s1,rsize_t s1max,const wchar_t * restrict s2);
errno_t wcsncat_s(wchar_t * restrict s1,rsize_t s1max,const wchar_t * restrict s2,rsize_t n);

 /* Wide string search functions */
wchar_t *wcstok_s(wchar_t * restrict s1,rsize_t * restrict s1max,const wchar_t * restrict s2,wchar_t ** restrict ptr);

 /* Miscellaneous functions */
size_t wcsnlen_s(const wchar_t *s, size_t maxsize);

/* Extended multibyte/wide character conversion utilities */
 /* Restartable multibyte/wide character conversion functions */
errno_t wcrtomb_s(size_t * restrict retval,char * restrict s, rsize_t smax,wchar_t wc, mbstate_t * restrict ps);

 /* Restartable multibyte/wide string conversion functions */
errno_t mbsrtowcs_s(size_t * restrict retval,wchar_t * restrict dst, rsize_t dstmax,const char ** restrict src, rsize_t len,mbstate_t * restrict ps);
errno_t wcsrtombs_s(size_t * restrict retval,char * restrict dst, rsize_t dstmax,const wchar_t ** restrict src, rsize_t len,mbstate_t * restrict ps);

#endif /* __STDC_WANT_LIB_EXT1__ */

#endif /* defined(_WCHAR_H) && !defined(PS_BC_WCHAR_H) */
