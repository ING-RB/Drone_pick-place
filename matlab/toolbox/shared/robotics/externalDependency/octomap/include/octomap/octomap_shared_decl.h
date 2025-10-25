/* 
 *  Copyright (C) 2017 The MathWorks, Inc.
 */

 
#ifndef OCTOMAP_SHARED_DECL_H_
#define OCTOMAP_SHARED_DECL_H_

// Import/export for windows dll's and visibility for gcc shared libraries.
#if defined(_MSC_VER)
    #define OCTOMAP_HELPER_IMPORT __declspec(dllimport)
    #define OCTOMAP_HELPER_EXPORT __declspec(dllexport)
#elif __GNUC__ >= 4
    #define OCTOMAP_HELPER_IMPORT __attribute__ ((visibility("default")))
    #define OCTOMAP_HELPER_EXPORT __attribute__ ((visibility("default")))
#else
    #define OCTOMAP_HELPER_IMPORT
    #define OCTOMAP_HELPER_EXPORT
#endif

#endif
