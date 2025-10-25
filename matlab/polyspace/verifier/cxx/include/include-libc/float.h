/* Copyright 2012-2020 The MathWorks, Inc. */

#ifndef _FLOAT_H___
#define _FLOAT_H___ _FLOAT_H___

#ifndef __FLT_RADIX__
#define __FLT_RADIX__         2
#endif

#ifndef __FLT_MANT_DIG__
#define __FLT_MANT_DIG__      24
#endif

#ifndef __FLT_DIG__
#define __FLT_DIG__           6
#endif

#ifndef __FLT_EPSILON__
#define __FLT_EPSILON__       1.19209290e-7F
#endif

#ifndef __FLT_MIN_EXP__
#define __FLT_MIN_EXP__       (-125)
#endif

#ifndef __FLT_MIN__
#define __FLT_MIN__           1.17549435e-38F
#endif

#if !defined(FLT_MIN_10_EXP) || !defined(__FLT_MIN_10_EXP__)
#define __FLT_MIN_10_EXP__    (-37)
#endif

#if !defined(FLT_MAX_EXP) || !defined(__FLT_MAX_EXP__)
#define __FLT_MAX_EXP__       128
#endif

#if !defined(FLT_MAX) || !defined(__FLT_MAX__)
#define __FLT_MAX__           3.40282347e+38F
#endif

#if !defined(FLT_MAX_10_EXP) || !defined(__FLT_MAX_10_EXP__)
#define __FLT_MAX_10_EXP__    38
#endif


#if __DBL_DIG__ == __FLT_DIG__

#ifndef __DBL_EPSILON__
# define __DBL_EPSILON__       __FLT_EPSILON__
#endif

#ifndef __DBL_MANT_DIG__
# define __DBL_MANT_DIG__      __FLT_MANT_DIG__
#endif

#ifndef __DBL_MIN_EXP__
# define __DBL_MIN_EXP__       __FLT_MIN_EXP__
#endif

#ifndef __DBL_MAX_EXP__
# define __DBL_MAX_EXP__       __FLT_MAX_EXP__
#endif

#ifndef __DBL_MIN__
# define __DBL_MIN__           __FLT_MIN__
#endif

#ifndef __DBL_MAX__
# define __DBL_MAX__           __FLT_MAX__
#endif

#ifndef __DBL_MIN_10_EXP__
# define __DBL_MIN_10_EXP__    __FLT_MIN_10_EXP__
#endif

#ifndef __DBL_MAX_10_EXP__
# define __DBL_MAX_10_EXP__    __FLT_MAX_10_EXP__
#endif

#else /* if __DBL_DIG__ == 15 */

#ifndef __DBL_EPSILON__
# define __DBL_EPSILON__       2.2204460492503131e-16
#endif

#ifndef __DBL_MANT_DIG__
# define __DBL_MANT_DIG__      53
#endif

#ifndef __DBL_MIN_EXP__
# define __DBL_MIN_EXP__       (-1021)
#endif

#ifndef __DBL_MAX_EXP__
# define __DBL_MAX_EXP__       1024
#endif

#ifndef __DBL_MIN__
# define __DBL_MIN__           2.2250738585072014e-308
#endif

#ifndef __DBL_MAX__
# define __DBL_MAX__           1.7976931348623157e+308
#endif

#ifndef __DBL_MIN_10_EXP__
# define __DBL_MIN_10_EXP__    (-307)
#endif

#ifndef __DBL_MAX_10_EXP__
# define __DBL_MAX_10_EXP__    308
#endif

#endif /* __DBL_DIG__ == __FLT_DIG__ */



#if __LDBL_DIG__ == __FLT_DIG__

#ifndef __LDBL_EPSILON__
# define __LDBL_EPSILON__       __FLT_EPSILON__
#endif

#ifndef __LDBL_MANT_DIG__
# define __LDBL_MANT_DIG__      __FLT_MANT_DIG__
#endif

#ifndef __LDBL_MIN_10_EXP__
# define __LDBL_MIN_10_EXP__    __FLT_MIN_10_EXP__
#endif

#ifndef __LDBL_MAX_10_EXP__
# define __LDBL_MAX_10_EXP__    __FLT_MAX_10_EXP__
#endif

#ifndef __LDBL_MIN_EXP__
# define __LDBL_MIN_EXP__       __FLT_MIN_EXP__
#endif

#ifndef __LDBL_MAX_EXP__
# define __LDBL_MAX_EXP__       __FLT_MAX_EXP__
#endif

#ifndef __LDBL_MIN__
# define __LDBL_MIN__           __FLT_MIN__
#endif

#ifndef __LDBL_MAX__
# define __LDBL_MAX__           __FLT_MAX__
#endif

#elif __LDBL_DIG__ == __DBL_DIG__

#ifndef  __LDBL_EPSILON__
# define __LDBL_EPSILON__       __DBL_EPSILON__
#endif

#ifndef __LDBL_MANT_DIG__
# define __LDBL_MANT_DIG__      __DBL_MANT_DIG__
#endif

#ifndef __LDBL_MIN_10_EXP__
# define __LDBL_MIN_10_EXP__    __DBL_MIN_10_EXP__
#endif

#ifndef __LDBL_MAX_10_EXP__
# define __LDBL_MAX_10_EXP__    __DBL_MAX_10_EXP__
#endif

#ifndef __LDBL_MIN_EXP__
# define __LDBL_MIN_EXP__       __DBL_MIN_EXP__
#endif

#ifndef __LDBL_MAX_EXP__
# define __LDBL_MAX_EXP__       __DBL_MAX_EXP__
#endif

#ifndef __LDBL_MIN__
# define __LDBL_MIN__           __DBL_MIN__
#endif

#ifndef __LDBL_MAX__
# define __LDBL_MAX__           __DBL_MAX__
#endif

#else /* if __LDBL_DIG__ == 18 */

#ifndef __LDBL_EPSILON__
# define __LDBL_EPSILON__       1.08420217248550443401e-19L
#endif

#ifndef __LDBL_MANT_DIG__
# define __LDBL_MANT_DIG__      64
#endif

#ifndef __LDBL_MIN_10_EXP__
# define __LDBL_MIN_10_EXP__    (-4931)
#endif

#ifndef __LDBL_MAX_10_EXP__
# define __LDBL_MAX_10_EXP__    4932
#endif

#ifndef __LDBL_MIN_EXP__
# define __LDBL_MIN_EXP__       (-16381)
#endif

#ifndef __LDBL_MAX_EXP__
# define __LDBL_MAX_EXP__       16384
#endif

#ifndef __LDBL_MIN__
# define __LDBL_MIN__           3.36210314311209350626e-4932L
#endif

#ifndef __LDBL_MAX__
# define __LDBL_MAX__           1.18973149535723176502e+4932L
#endif

#endif /* __LDBL_DIG__ == __FLT_DIG__ */


#undef FLT_ROUNDS
#define FLT_ROUNDS 1
#undef FLT_RADIX
#define FLT_RADIX __FLT_RADIX__
#undef FLT_MANT_DIG
#define FLT_MANT_DIG __FLT_MANT_DIG__
#undef FLT_DIG
#define FLT_DIG __FLT_DIG__
#undef FLT_EPSILON
#define FLT_EPSILON __FLT_EPSILON__
#undef FLT_MIN_EXP
#define FLT_MIN_EXP __FLT_MIN_EXP__
#undef FLT_MIN
#define FLT_MIN __FLT_MIN__
#undef FLT_MIN_10_EXP
#define FLT_MIN_10_EXP __FLT_MIN_10_EXP__
#undef FLT_MAX_EXP
#define FLT_MAX_EXP __FLT_MAX_EXP__
#undef FLT_MAX
#define FLT_MAX __FLT_MAX__
#undef FLT_MAX_10_EXP
#define FLT_MAX_10_EXP __FLT_MAX_10_EXP__

#undef DBL_MANT_DIG
#define DBL_MANT_DIG __DBL_MANT_DIG__
#undef DBL_DIG
#define DBL_DIG __DBL_DIG__
#undef DBL_EPSILON
#define DBL_EPSILON __DBL_EPSILON__
#undef DBL_MIN_EXP
#define DBL_MIN_EXP __DBL_MIN_EXP__
#undef DBL_MIN
#define DBL_MIN __DBL_MIN__
#undef DBL_MIN_10_EXP
#define DBL_MIN_10_EXP __DBL_MIN_10_EXP__
#undef DBL_MAX_EXP
#define DBL_MAX_EXP __DBL_MAX_EXP__
#undef DBL_MAX
#define DBL_MAX __DBL_MAX__
#undef DBL_MAX_10_EXP
#define DBL_MAX_10_EXP __DBL_MAX_10_EXP__

#undef LDBL_MANT_DIG
#define LDBL_MANT_DIG __LDBL_MANT_DIG__
#undef LDBL_DIG
#define LDBL_DIG __LDBL_DIG__
#undef LDBL_EPSILON
#define LDBL_EPSILON __LDBL_EPSILON__
#undef LDBL_MIN_EXP
#define LDBL_MIN_EXP __LDBL_MIN_EXP__
#undef LDBL_MIN
#define LDBL_MIN __LDBL_MIN__
#undef LDBL_MIN_10_EXP
#define LDBL_MIN_10_EXP __LDBL_MIN_10_EXP__
#undef LDBL_MAX_EXP
#define LDBL_MAX_EXP __LDBL_MAX_EXP__
#undef LDBL_MAX
#define LDBL_MAX __LDBL_MAX__
#undef LDBL_MAX_10_EXP
#define LDBL_MAX_10_EXP __LDBL_MAX_10_EXP__

#endif /* _FLOAT_H___ */
