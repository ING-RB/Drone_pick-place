#if defined(_STDIO_H) && !defined(PS_BC_STDIO_H)

#ifndef __STDC_LIB_EXT1__
#define __STDC_LIB_EXT1__ 1
#endif /* __STDC_LIB_EXT1__ */

#if __STDC_WANT_LIB_EXT1__
#define PS_BC_STDIO_H

#include "./ps_bc_base.h"

#include "./ps_bc_errno.h"
#include "./ps_bc_stddef.h"

#define L_tmpnam_s L_tmpnam
#define TMP_MAX_S TMP_MAX

/* Operations on files */
errno_t tmpfile_s(FILE * restrict * restrict streamptr);
errno_t tmpnam_s(char *s, rsize_t maxsize);

/* File access functions */
errno_t fopen_s(FILE * restrict * restrict streamptr,const char * restrict filename,const char * restrict mode);
errno_t freopen_s(FILE * restrict * restrict newstreamptr,const char * restrict filename,const char * restrict mode,FILE * restrict stream);

/* Formatted input/output functions */
int fprintf_s(FILE * restrict stream,const char * restrict format, ...);
int fscanf_s(FILE * restrict stream,const char * restrict format, ...);
int printf_s(const char * restrict format, ...);
int scanf_s(const char * restrict format, ...);
int snprintf_s(char * restrict s, rsize_t n,const char * restrict format, ...);
int sprintf_s(char * restrict s, rsize_t n,const char * restrict format, ...);
int sscanf_s(const char * restrict s,const char * restrict format, ...);
int vfprintf_s(FILE * restrict stream,const char * restrict format,va_list arg);
int vfscanf_s(FILE * restrict stream,const char * restrict format,va_list arg);
int vprintf_s(const char * restrict format,va_list arg);
int vscanf_s(const char * restrict format,va_list arg);
int vsnprintf_s(char * restrict s, rsize_t n,const char * restrict format,va_list arg);
int vsprintf_s(char * restrict s, rsize_t n,const char * restrict format,va_list arg);
int vsscanf_s(const char * restrict s,const char * restrict format,va_list arg);

/* Character input/output functions */
char *gets_s(char *s, rsize_t n);

#endif /* __STDC_WANT_LIB_EXT1__ */

#endif /* defined(_STDIO_H) && !defined(PS_BC_STDIO_H) */
