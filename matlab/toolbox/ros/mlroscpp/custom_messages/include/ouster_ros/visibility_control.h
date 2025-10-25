#ifndef OUSTER_ROS__VISIBILITY_CONTROL_H_
#define OUSTER_ROS__VISIBILITY_CONTROL_H_
#if defined _WIN32 || defined __CYGWIN__
  #ifdef __GNUC__
    #define OUSTER_ROS_EXPORT __attribute__ ((dllexport))
    #define OUSTER_ROS_IMPORT __attribute__ ((dllimport))
  #else
    #define OUSTER_ROS_EXPORT __declspec(dllexport)
    #define OUSTER_ROS_IMPORT __declspec(dllimport)
  #endif
  #ifdef OUSTER_ROS_BUILDING_LIBRARY
    #define OUSTER_ROS_PUBLIC OUSTER_ROS_EXPORT
  #else
    #define OUSTER_ROS_PUBLIC OUSTER_ROS_IMPORT
  #endif
  #define OUSTER_ROS_PUBLIC_TYPE OUSTER_ROS_PUBLIC
  #define OUSTER_ROS_LOCAL
#else
  #define OUSTER_ROS_EXPORT __attribute__ ((visibility("default")))
  #define OUSTER_ROS_IMPORT
  #if __GNUC__ >= 4
    #define OUSTER_ROS_PUBLIC __attribute__ ((visibility("default")))
    #define OUSTER_ROS_LOCAL  __attribute__ ((visibility("hidden")))
  #else
    #define OUSTER_ROS_PUBLIC
    #define OUSTER_ROS_LOCAL
  #endif
  #define OUSTER_ROS_PUBLIC_TYPE
#endif
#endif  // OUSTER_ROS__VISIBILITY_CONTROL_H_
// Generated 21-Aug-2023 14:16:52
// Copyright 2019-2020 The MathWorks, Inc.
