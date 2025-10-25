// generated from rosidl_generator_c/resource/idl__struct.h.em
// with input from octomap_msgs:srv/BoundingBoxQuery.idl
// generated code does not contain a copyright notice

// IWYU pragma: private, include "octomap_msgs/srv/bounding_box_query.h"


#ifndef OCTOMAP_MSGS__SRV__DETAIL__BOUNDING_BOX_QUERY__STRUCT_H_
#define OCTOMAP_MSGS__SRV__DETAIL__BOUNDING_BOX_QUERY__STRUCT_H_

#ifdef __cplusplus
extern "C"
{
#endif

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>


// Constants defined in the message

// Include directives for member types
// Member 'min'
// Member 'max'
#include "geometry_msgs/msg/detail/point__struct.h"

/// Struct defined in srv/BoundingBoxQuery in the package octomap_msgs.
typedef struct octomap_msgs__srv__BoundingBoxQuery_Request
{
  /// minimum corner point of axis-aligned bounding box in global frame
  geometry_msgs__msg__Point min;
  /// maximum corner point of axis-aligned bounding box in global frame
  geometry_msgs__msg__Point max;
} octomap_msgs__srv__BoundingBoxQuery_Request;

// Struct for a sequence of octomap_msgs__srv__BoundingBoxQuery_Request.
typedef struct octomap_msgs__srv__BoundingBoxQuery_Request__Sequence
{
  octomap_msgs__srv__BoundingBoxQuery_Request * data;
  /// The number of valid items in data
  size_t size;
  /// The number of allocated items in data
  size_t capacity;
} octomap_msgs__srv__BoundingBoxQuery_Request__Sequence;

// Constants defined in the message

/// Struct defined in srv/BoundingBoxQuery in the package octomap_msgs.
typedef struct octomap_msgs__srv__BoundingBoxQuery_Response
{
  uint8_t structure_needs_at_least_one_member;
} octomap_msgs__srv__BoundingBoxQuery_Response;

// Struct for a sequence of octomap_msgs__srv__BoundingBoxQuery_Response.
typedef struct octomap_msgs__srv__BoundingBoxQuery_Response__Sequence
{
  octomap_msgs__srv__BoundingBoxQuery_Response * data;
  /// The number of valid items in data
  size_t size;
  /// The number of allocated items in data
  size_t capacity;
} octomap_msgs__srv__BoundingBoxQuery_Response__Sequence;

// Constants defined in the message

// Include directives for member types
// Member 'info'
#include "service_msgs/msg/detail/service_event_info__struct.h"

// constants for array fields with an upper bound
// request
enum
{
  octomap_msgs__srv__BoundingBoxQuery_Event__request__MAX_SIZE = 1
};
// response
enum
{
  octomap_msgs__srv__BoundingBoxQuery_Event__response__MAX_SIZE = 1
};

/// Struct defined in srv/BoundingBoxQuery in the package octomap_msgs.
typedef struct octomap_msgs__srv__BoundingBoxQuery_Event
{
  service_msgs__msg__ServiceEventInfo info;
  octomap_msgs__srv__BoundingBoxQuery_Request__Sequence request;
  octomap_msgs__srv__BoundingBoxQuery_Response__Sequence response;
} octomap_msgs__srv__BoundingBoxQuery_Event;

// Struct for a sequence of octomap_msgs__srv__BoundingBoxQuery_Event.
typedef struct octomap_msgs__srv__BoundingBoxQuery_Event__Sequence
{
  octomap_msgs__srv__BoundingBoxQuery_Event * data;
  /// The number of valid items in data
  size_t size;
  /// The number of allocated items in data
  size_t capacity;
} octomap_msgs__srv__BoundingBoxQuery_Event__Sequence;

#ifdef __cplusplus
}
#endif

#endif  // OCTOMAP_MSGS__SRV__DETAIL__BOUNDING_BOX_QUERY__STRUCT_H_
