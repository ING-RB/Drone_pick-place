#ifndef CARLA_ACKERMANN_MSGS__VISIBILITY_CONTROL_H_
#define CARLA_ACKERMANN_MSGS__VISIBILITY_CONTROL_H_
#if defined _WIN32 || defined __CYGWIN__
  #ifdef __GNUC__
    #define CARLA_ACKERMANN_MSGS_EXPORT __attribute__ ((dllexport))
    #define CARLA_ACKERMANN_MSGS_IMPORT __attribute__ ((dllimport))
  #else
    #define CARLA_ACKERMANN_MSGS_EXPORT __declspec(dllexport)
    #define CARLA_ACKERMANN_MSGS_IMPORT __declspec(dllimport)
  #endif
  #ifdef CARLA_ACKERMANN_MSGS_BUILDING_LIBRARY
    #define CARLA_ACKERMANN_MSGS_PUBLIC CARLA_ACKERMANN_MSGS_EXPORT
  #else
    #define CARLA_ACKERMANN_MSGS_PUBLIC CARLA_ACKERMANN_MSGS_IMPORT
  #endif
  #define CARLA_ACKERMANN_MSGS_PUBLIC_TYPE CARLA_ACKERMANN_MSGS_PUBLIC
  #define CARLA_ACKERMANN_MSGS_LOCAL
#else
  #define CARLA_ACKERMANN_MSGS_EXPORT __attribute__ ((visibility("default")))
  #define CARLA_ACKERMANN_MSGS_IMPORT
  #if __GNUC__ >= 4
    #define CARLA_ACKERMANN_MSGS_PUBLIC __attribute__ ((visibility("default")))
    #define CARLA_ACKERMANN_MSGS_LOCAL  __attribute__ ((visibility("hidden")))
  #else
    #define CARLA_ACKERMANN_MSGS_PUBLIC
    #define CARLA_ACKERMANN_MSGS_LOCAL
  #endif
  #define CARLA_ACKERMANN_MSGS_PUBLIC_TYPE
#endif
#endif  // CARLA_ACKERMANN_MSGS__VISIBILITY_CONTROL_H_
// Generated 05-Sep-2022 12:18:11
// Copyright 2019-2020 The MathWorks, Inc.
