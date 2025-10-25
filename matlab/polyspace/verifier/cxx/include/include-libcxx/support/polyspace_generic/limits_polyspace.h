/* Copyright 2017 The MathWorks, Inc. */

#ifndef _LIBCPP_SUPPORT_POLYSPACE_GENERIC_LIMITS_POLYSPACE_H
#define _LIBCPP_SUPPORT_POLYSPACE_GENERIC_LIMITS_POLYSPACE_H

#include <limits.h> // libc include
#include <float.h> // limit constants
#ifndef __DBL_DENORM_MIN__
#define __DBL_DENORM_MIN__ double(4.94065645841246544177e-324L)
#endif
#ifndef __FLT_DENORM_MIN__
#define __FLT_DENORM_MIN__ 1.40129846432481707092e-45F
#endif
#ifndef LDBL_DENORM_MIN__
#define __LDBL_DENORM_MIN__ 3.64519953188247460253e-4951L
#endif

#if  0 && ! defined(__clang__)
#define __CHAR_BIT__       CHAR_BIT

#define __FLT_MANT_DIG__   FLT_MANT_DIG
#define __FLT_DIG__        FLT_DIG
#define __FLT_RADIX__      FLT_RADIX
#define __FLT_MIN_EXP__    FLT_MIN_EXP
#define __FLT_MIN_10_EXP__ FLT_MIN_10_EXP
#define __FLT_MAX_EXP__    FLT_MAX_EXP
#define __FLT_MAX_10_EXP__ FLT_MAX_10_EXP
#define __FLT_MIN__        FLT_MIN
#define __FLT_MAX__        FLT_MAX
#define __FLT_EPSILON__    FLT_EPSILON
// predefined by MinGW GCC
#define __FLT_DENORM_MIN__ 1.40129846432481707092e-45F

#define __DBL_MANT_DIG__   DBL_MANT_DIG
#define __DBL_DIG__        DBL_DIG
#define __DBL_RADIX__      DBL_RADIX
#define __DBL_MIN_EXP__    DBL_MIN_EXP
#define __DBL_MIN_10_EXP__ DBL_MIN_10_EXP
#define __DBL_MAX_EXP__    DBL_MAX_EXP
#define __DBL_MAX_10_EXP__ DBL_MAX_10_EXP
#define __DBL_MIN__        DBL_MIN
#define __DBL_MAX__        DBL_MAX
#define __DBL_EPSILON__    DBL_EPSILON
// predefined by MinGW GCC
#define __DBL_DENORM_MIN__ double(4.94065645841246544177e-324L)

#define __LDBL_MANT_DIG__   LDBL_MANT_DIG
#define __LDBL_DIG__        LDBL_DIG
#define __LDBL_RADIX__      LDBL_RADIX
#define __LDBL_MIN_EXP__    LDBL_MIN_EXP
#define __LDBL_MIN_10_EXP__ LDBL_MIN_10_EXP
#define __LDBL_MAX_EXP__    LDBL_MAX_EXP
#define __LDBL_MAX_10_EXP__ LDBL_MAX_10_EXP
#define __LDBL_MIN__        LDBL_MIN
#define __LDBL_MAX__        LDBL_MAX
#define __LDBL_EPSILON__    LDBL_EPSILON
// predefined by MinGW GCC
#define __LDBL_DENORM_MIN__ 3.64519953188247460253e-4951L
#endif // ! defined(__clang__)

#endif // _LIBCPP_SUPPORT_WIN32_LIMITS_WIN32_H
