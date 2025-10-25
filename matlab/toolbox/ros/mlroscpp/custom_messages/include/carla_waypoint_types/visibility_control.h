#ifndef CARLA_WAYPOINT_TYPES__VISIBILITY_CONTROL_H_
#define CARLA_WAYPOINT_TYPES__VISIBILITY_CONTROL_H_
#if defined _WIN32 || defined __CYGWIN__
  #ifdef __GNUC__
    #define CARLA_WAYPOINT_TYPES_EXPORT __attribute__ ((dllexport))
    #define CARLA_WAYPOINT_TYPES_IMPORT __attribute__ ((dllimport))
  #else
    #define CARLA_WAYPOINT_TYPES_EXPORT __declspec(dllexport)
    #define CARLA_WAYPOINT_TYPES_IMPORT __declspec(dllimport)
  #endif
  #ifdef CARLA_WAYPOINT_TYPES_BUILDING_LIBRARY
    #define CARLA_WAYPOINT_TYPES_PUBLIC CARLA_WAYPOINT_TYPES_EXPORT
  #else
    #define CARLA_WAYPOINT_TYPES_PUBLIC CARLA_WAYPOINT_TYPES_IMPORT
  #endif
  #define CARLA_WAYPOINT_TYPES_PUBLIC_TYPE CARLA_WAYPOINT_TYPES_PUBLIC
  #define CARLA_WAYPOINT_TYPES_LOCAL
#else
  #define CARLA_WAYPOINT_TYPES_EXPORT __attribute__ ((visibility("default")))
  #define CARLA_WAYPOINT_TYPES_IMPORT
  #if __GNUC__ >= 4
    #define CARLA_WAYPOINT_TYPES_PUBLIC __attribute__ ((visibility("default")))
    #define CARLA_WAYPOINT_TYPES_LOCAL  __attribute__ ((visibility("hidden")))
  #else
    #define CARLA_WAYPOINT_TYPES_PUBLIC
    #define CARLA_WAYPOINT_TYPES_LOCAL
  #endif
  #define CARLA_WAYPOINT_TYPES_PUBLIC_TYPE
#endif
#endif  // CARLA_WAYPOINT_TYPES__VISIBILITY_CONTROL_H_
// Generated 05-Sep-2022 12:18:18
// Copyright 2019-2020 The MathWorks, Inc.
