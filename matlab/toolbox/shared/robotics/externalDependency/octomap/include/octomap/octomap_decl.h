/***
  * Copyright (C) 2017-2023 The MathWorks, Inc.
  * MathWorks-specific modifications have been made to the original source. 
  */

#ifndef OCTOMAP_DECL_H_
#define OCTOMAP_DECL_H_

#include "octomap_shared_decl.h"

#pragma warning( disable: 4251 )

#ifdef octomap_EXPORTS // we are building a shared lib/dll
    #define OCTOMAP_DECL OCTOMAP_HELPER_EXPORT
#else // we are using shared lib/dll
    #define OCTOMAP_DECL OCTOMAP_HELPER_IMPORT
#endif

#endif
