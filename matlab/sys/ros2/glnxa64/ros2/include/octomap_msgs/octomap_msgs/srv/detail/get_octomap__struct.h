// generated from rosidl_generator_c/resource/idl__struct.h.em
// with input from octomap_msgs:srv/GetOctomap.idl
// generated code does not contain a copyright notice

// IWYU pragma: private, include "octomap_msgs/srv/get_octomap.h"


#ifndef OCTOMAP_MSGS__SRV__DETAIL__GET_OCTOMAP__STRUCT_H_
#define OCTOMAP_MSGS__SRV__DETAIL__GET_OCTOMAP__STRUCT_H_

#ifdef __cplusplus
extern "C"
{
#endif

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>


// Constants defined in the message

/// Struct defined in srv/GetOctomap in the package octomap_msgs.
typedef struct octomap_msgs__srv__GetOctomap_Request
{
  uint8_t structure_needs_at_least_one_member;
} octomap_msgs__srv__GetOctomap_Request;

// Struct for a sequence of octomap_msgs__srv__GetOctomap_Request.
typedef struct octomap_msgs__srv__GetOctomap_Request__Sequence
{
  octomap_msgs__srv__GetOctomap_Request * data;
  /// The number of valid items in data
  size_t size;
  /// The number of allocated items in data
  size_t capacity;
} octomap_msgs__srv__GetOctomap_Request__Sequence;

// Constants defined in the message

// Include directives for member types
// Member 'map'
#include "octomap_msgs/msg/detail/octomap__struct.h"

/// Struct defined in srv/GetOctomap in the package octomap_msgs.
typedef struct octomap_msgs__srv__GetOctomap_Response
{
  octomap_msgs__msg__Octomap map;
} octomap_msgs__srv__GetOctomap_Response;

// Struct for a sequence of octomap_msgs__srv__GetOctomap_Response.
typedef struct octomap_msgs__srv__GetOctomap_Response__Sequence
{
  octomap_msgs__srv__GetOctomap_Response * data;
  /// The number of valid items in data
  size_t size;
  /// The number of allocated items in data
  size_t capacity;
} octomap_msgs__srv__GetOctomap_Response__Sequence;

// Constants defined in the message

// Include directives for member types
// Member 'info'
#include "service_msgs/msg/detail/service_event_info__struct.h"

// constants for array fields with an upper bound
// request
enum
{
  octomap_msgs__srv__GetOctomap_Event__request__MAX_SIZE = 1
};
// response
enum
{
  octomap_msgs__srv__GetOctomap_Event__response__MAX_SIZE = 1
};

/// Struct defined in srv/GetOctomap in the package octomap_msgs.
typedef struct octomap_msgs__srv__GetOctomap_Event
{
  service_msgs__msg__ServiceEventInfo info;
  octomap_msgs__srv__GetOctomap_Request__Sequence request;
  octomap_msgs__srv__GetOctomap_Response__Sequence response;
} octomap_msgs__srv__GetOctomap_Event;

// Struct for a sequence of octomap_msgs__srv__GetOctomap_Event.
typedef struct octomap_msgs__srv__GetOctomap_Event__Sequence
{
  octomap_msgs__srv__GetOctomap_Event * data;
  /// The number of valid items in data
  size_t size;
  /// The number of allocated items in data
  size_t capacity;
} octomap_msgs__srv__GetOctomap_Event__Sequence;

#ifdef __cplusplus
}
#endif

#endif  // OCTOMAP_MSGS__SRV__DETAIL__GET_OCTOMAP__STRUCT_H_
