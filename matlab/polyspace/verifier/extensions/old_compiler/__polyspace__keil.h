/* Copyright 2017-2019 The MathWorks, Inc. */

/* Used with KEIL compiler only */

#ifndef __POLYSPACE__KEIL_H
#define __POLYSPACE__KEIL_H

#define __attribute__(x)

/* Those defines are set automatically by the Keil compiler.
 * They should be set manually if they are used in your project.
 */

/* #define __C166__ 300 */
/* #define __FLOAT64__ 0 */
/* #define __MOD167__ 1 */
/* #define __MODEL__ 6 */
/* #define __STDC__ 1 */

#ifndef __PST_KEIL_NO_KEYWORDS__

/* Those defines are used to remove some non-standard keywords */
#define bdata
#define far
#define huge
#define idata
#define near
#define sdata
#define reentrant
#ifdef __C51__
#define large
#define code
#define data
#define xdata
#define pdata
#define xhuge
#endif

#define _interrupt interrupt
#define __interrupt interrupt
#define _interrupt_ interrupt
#define __interrupt__ interrupt
#define _using using
#define __using using
#define _using_ using
#define __using__ using

#endif /* __PST_KEIL_NO_KEYWORDS__ */

#endif /* __POLYSPACE__KEIL_H */
