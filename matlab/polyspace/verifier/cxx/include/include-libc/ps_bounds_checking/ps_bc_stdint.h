#if defined(_STDINT_H) && !defined(PS_BC_STDINT_H)

#ifndef __STDC_LIB_EXT1__
#define __STDC_LIB_EXT1__ 1
#endif /* __STDC_LIB_EXT1__ */

#if __STDC_WANT_LIB_EXT1__
#define PS_BC_STDINT_H

#include "./ps_bc_base.h"

#define RSIZE_MAX (SIZE_MAX >>1)
#endif /* __STDC_WANT_LIB_EXT1__ */

#endif /* defined(_STDINT_H) && !defined(PS_BC_STDINT_H) */
