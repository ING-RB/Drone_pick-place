// Copyright 2019 MathWorks, Inc.

#ifndef BRIDGE__VISIBILITY_CONTROL_H_
#define BRIDGE__VISIBILITY_CONTROL_H_

#ifdef __cplusplus
extern "C"
{
#endif

// This logic was borrowed (then namespaced) from the examples on the gcc wiki:
//     https://gcc.gnu.org/wiki/Visibility

#if defined _WIN32 || defined __CYGWIN__
  #ifdef __GNUC__
    #define BRIDGE_EXPORT __attribute__ ((dllexport))
    #define BRIDGE_IMPORT __attribute__ ((dllimport))
  #else
    #define BRIDGE_EXPORT __declspec(dllexport)
    #define BRIDGE_IMPORT __declspec(dllimport)
  #endif
  #ifdef BRIDGE_BUILDING_DLL
    #define BRIDGE_PUBLIC BRIDGE_EXPORT
  #else
    #define BRIDGE_PUBLIC BRIDGE_IMPORT
  #endif
  #define BRIDGE_PUBLIC_TYPE BRIDGE_PUBLIC
  #define BRIDGE_LOCAL
#else
  #define BRIDGE_EXPORT __attribute__ ((visibility("default")))
  #define BRIDGE_IMPORT
  #if __GNUC__ >= 4
    #define BRIDGE_PUBLIC __attribute__ ((visibility("default")))
    #define BRIDGE_LOCAL  __attribute__ ((visibility("hidden")))
  #else
    #define BRIDGE_PUBLIC
    #define BRIDGE_LOCAL
  #endif
  #define BRIDGE_PUBLIC_TYPE
#endif


#ifdef __cplusplus
}
#endif

#endif  // BRIDGE__VISIBILITY_CONTROL_H_
