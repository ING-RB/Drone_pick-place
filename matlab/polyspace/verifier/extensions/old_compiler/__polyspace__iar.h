/* Copyright 2017-2019 The MathWorks, Inc. */

/* Used with IAR compiler only */

#ifndef __POLYSPACE__IAR_H
#define __POLYSPACE__IAR_H


#define __attribute__(x)

#ifndef __PST_IAR_NO_FLAG__

#ifndef __IAR_SYSTEMS_ICC__
#define __IAR_SYSTEMS_ICC__ 1
#endif /* __IAR_SYSTEMS_ICC__ */

#ifndef __TID__
#define __TID__ 14
#endif /* __TID__ */

/* Those defines are set automatically by the IAR compiler.
 * They should be set manually if they are used in your project.
 */
/* #define __STDC__ 1 */
/* #define __VER__ 334 */

#endif /* __PST_IAR_NO_FLAG__ */

#ifndef __PST_IAR_NO_KEYWORDS__

/* Those defines are used to remove some non-standard keywords */
#define __no_init no_init
#define saddr
#define reentrant
#define reentrant_idata
#define non_banked
#define plm
#define bdata
#define idata
#define pdata
#define __intrinsic
#if __TID__ == 14
#define code
#define xdata
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
#define _monitor monitor
#define __monitor monitor
#define _monitor_ monitor
#define __monitor__ monitor

#endif /*__PST_IAR_NO_KEYWORDS__*/

#endif /* __POLYSPACE__IAR_H */
