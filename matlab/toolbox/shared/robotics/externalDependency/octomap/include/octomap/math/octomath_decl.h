/* 
 *  Copyright (C) 2017-2023 The MathWorks, Inc.
 */

#ifndef OCTOMATH_DECL_H_
#define OCTOMATH_DECL_H_

#ifdef BUILDING_3P_OCTOMAP
#include "../octomap_shared_decl.h"
#else
#include "octomap_shared_decl.h"
#endif

#ifdef octomath_EXPORTS // we are building a shared lib/dll
    #define OCTOMATH_DECL OCTOMAP_HELPER_EXPORT
#else // we are using shared lib/dll
    #define OCTOMATH_DECL OCTOMAP_HELPER_IMPORT
#endif

#endif
