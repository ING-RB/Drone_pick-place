#if defined(_STRING_H) && !defined(PS_BC_STRING_H)

#ifndef __STDC_LIB_EXT1__
#define __STDC_LIB_EXT1__ 1
#endif /* __STDC_LIB_EXT1__ */

#if __STDC_WANT_LIB_EXT1__
#define PS_BC_STRING_H

#include "./ps_bc_base.h"

#include "./ps_bc_errno.h"
#include "./ps_bc_stddef.h"

/* Copying functions */
errno_t memcpy_s(void * restrict s1, rsize_t s1max,const void * restrict s2, rsize_t n);
errno_t memmove_s(void *s1, rsize_t s1max,const void *s2, rsize_t n);
errno_t strcpy_s(char * restrict s1,rsize_t s1max,const char * restrict s2);
errno_t strncpy_s(char * restrict s1,rsize_t s1max,const char * restrict s2,rsize_t n);

/* Concatenation functions */
errno_t strcat_s(char * restrict s1,rsize_t s1max,const char * restrict s2);
errno_t strncat_s(char * restrict s1,rsize_t s1max,const char * restrict s2,rsize_t n);

/* Search functions */
char *strtok_s(char * restrict s1,rsize_t * restrict s1max,const char * restrict s2,char ** restrict ptr);

/* Miscellaneous functions */
errno_t memset_s(void *s, rsize_t smax, int c, rsize_t n);
errno_t strerror_s(char *s, rsize_t maxsize,errno_t errnum);
size_t strerrorlen_s(errno_t errnum);
size_t strnlen_s(const char *s, size_t maxsize);

#endif /* __STDC_WANT_LIB_EXT1__ */

#endif /* defined(_STRING_H) && !defined(PS_BC_STRING_H) */
