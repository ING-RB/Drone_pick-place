#if defined(_TIME_H) && !defined(PS_BC_TIME_H)

#ifndef __STDC_LIB_EXT1__
#define __STDC_LIB_EXT1__ 1
#endif /* __STDC_LIB_EXT1__ */

#if __STDC_WANT_LIB_EXT1__
#define PS_BC_TIME_H

#include "./ps_bc_base.h"

#include "./ps_bc_errno.h"
#include "./ps_bc_stddef.h"

/* Time conversion functions */
errno_t asctime_s(char *s, rsize_t maxsize,const struct tm *timeptr);
errno_t ctime_s(char *s, rsize_t maxsize,const time_t *timer);
struct tm *localtime_s(const time_t * restrict timer,struct tm * restrict result);

#endif /* __STDC_WANT_LIB_EXT1__ */

#endif /* defined(_TIME_H) && !defined(PS_BC_TIME_H) */
