/* 
 *  Copyright (C) 2017 The MathWorks, Inc.
 */

#ifndef MATLAB_ROSBAG_DECL_H_
#define MATLAB_ROSBAG_DECL_H_

// Import/export for windows dll's and visibility for gcc shared libraries.
#if defined(_MSC_VER)
    #define MLROSBAG_HELPER_IMPORT __declspec(dllimport)
    #define MLROSBAG_HELPER_EXPORT __declspec(dllexport)
#elif __GNUC__ >= 4
    #define MLROSBAG_HELPER_IMPORT __attribute__ ((visibility("default")))
    #define MLROSBAG_HELPER_EXPORT __attribute__ ((visibility("default")))
#else
    #define MLROSBAG_HELPER_IMPORT
    #define MLROSBAG_HELPER_EXPORT
#endif

#ifdef matlab_rosbag_EXPORTS // we are building a shared lib/dll
    #define MLROSBAG_DECL MLROSBAG_HELPER_EXPORT
#else // we are using shared lib/dll
    #define MLROSBAG_DECL MLROSBAG_HELPER_IMPORT
#endif

#endif
