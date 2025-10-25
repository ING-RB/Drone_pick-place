// generated from rosidl_typesupport_introspection_c/resource/idl__type_support.c.em
// with input from octomap_msgs:srv/BoundingBoxQuery.idl
// generated code does not contain a copyright notice

#include <stddef.h>
#include "octomap_msgs/srv/detail/bounding_box_query__rosidl_typesupport_introspection_c.h"
#include "octomap_msgs/msg/rosidl_typesupport_introspection_c__visibility_control.h"
#include "rosidl_typesupport_introspection_c/field_types.h"
#include "rosidl_typesupport_introspection_c/identifier.h"
#include "rosidl_typesupport_introspection_c/message_introspection.h"
#include "octomap_msgs/srv/detail/bounding_box_query__functions.h"
#include "octomap_msgs/srv/detail/bounding_box_query__struct.h"


// Include directives for member types
// Member `min`
// Member `max`
#include "geometry_msgs/msg/point.h"
// Member `min`
// Member `max`
#include "geometry_msgs/msg/detail/point__rosidl_typesupport_introspection_c.h"

#ifdef __cplusplus
extern "C"
{
#endif

void octomap_msgs__srv__BoundingBoxQuery_Request__rosidl_typesupport_introspection_c__BoundingBoxQuery_Request_init_function(
  void * message_memory, enum rosidl_runtime_c__message_initialization _init)
{
  // TODO(karsten1987): initializers are not yet implemented for typesupport c
  // see https://github.com/ros2/ros2/issues/397
  (void) _init;
  octomap_msgs__srv__BoundingBoxQuery_Request__init(message_memory);
}

void octomap_msgs__srv__BoundingBoxQuery_Request__rosidl_typesupport_introspection_c__BoundingBoxQuery_Request_fini_function(void * message_memory)
{
  octomap_msgs__srv__BoundingBoxQuery_Request__fini(message_memory);
}

static rosidl_typesupport_introspection_c__MessageMember octomap_msgs__srv__BoundingBoxQuery_Request__rosidl_typesupport_introspection_c__BoundingBoxQuery_Request_message_member_array[2] = {
  {
    "min",  // name
    rosidl_typesupport_introspection_c__ROS_TYPE_MESSAGE,  // type
    0,  // upper bound of string
    NULL,  // members of sub message (initialized later)
    false,  // is key
    false,  // is array
    0,  // array size
    false,  // is upper bound
    offsetof(octomap_msgs__srv__BoundingBoxQuery_Request, min),  // bytes offset in struct
    NULL,  // default value
    NULL,  // size() function pointer
    NULL,  // get_const(index) function pointer
    NULL,  // get(index) function pointer
    NULL,  // fetch(index, &value) function pointer
    NULL,  // assign(index, value) function pointer
    NULL  // resize(index) function pointer
  },
  {
    "max",  // name
    rosidl_typesupport_introspection_c__ROS_TYPE_MESSAGE,  // type
    0,  // upper bound of string
    NULL,  // members of sub message (initialized later)
    false,  // is key
    false,  // is array
    0,  // array size
    false,  // is upper bound
    offsetof(octomap_msgs__srv__BoundingBoxQuery_Request, max),  // bytes offset in struct
    NULL,  // default value
    NULL,  // size() function pointer
    NULL,  // get_const(index) function pointer
    NULL,  // get(index) function pointer
    NULL,  // fetch(index, &value) function pointer
    NULL,  // assign(index, value) function pointer
    NULL  // resize(index) function pointer
  }
};

static const rosidl_typesupport_introspection_c__MessageMembers octomap_msgs__srv__BoundingBoxQuery_Request__rosidl_typesupport_introspection_c__BoundingBoxQuery_Request_message_members = {
  "octomap_msgs__srv",  // message namespace
  "BoundingBoxQuery_Request",  // message name
  2,  // number of fields
  sizeof(octomap_msgs__srv__BoundingBoxQuery_Request),
  false,  // has_any_key_member_
  octomap_msgs__srv__BoundingBoxQuery_Request__rosidl_typesupport_introspection_c__BoundingBoxQuery_Request_message_member_array,  // message members
  octomap_msgs__srv__BoundingBoxQuery_Request__rosidl_typesupport_introspection_c__BoundingBoxQuery_Request_init_function,  // function to initialize message memory (memory has to be allocated)
  octomap_msgs__srv__BoundingBoxQuery_Request__rosidl_typesupport_introspection_c__BoundingBoxQuery_Request_fini_function  // function to terminate message instance (will not free memory)
};

// this is not const since it must be initialized on first access
// since C does not allow non-integral compile-time constants
static rosidl_message_type_support_t octomap_msgs__srv__BoundingBoxQuery_Request__rosidl_typesupport_introspection_c__BoundingBoxQuery_Request_message_type_support_handle = {
  0,
  &octomap_msgs__srv__BoundingBoxQuery_Request__rosidl_typesupport_introspection_c__BoundingBoxQuery_Request_message_members,
  get_message_typesupport_handle_function,
  &octomap_msgs__srv__BoundingBoxQuery_Request__get_type_hash,
  &octomap_msgs__srv__BoundingBoxQuery_Request__get_type_description,
  &octomap_msgs__srv__BoundingBoxQuery_Request__get_type_description_sources,
};

ROSIDL_TYPESUPPORT_INTROSPECTION_C_EXPORT_octomap_msgs
const rosidl_message_type_support_t *
ROSIDL_TYPESUPPORT_INTERFACE__MESSAGE_SYMBOL_NAME(rosidl_typesupport_introspection_c, octomap_msgs, srv, BoundingBoxQuery_Request)() {
  octomap_msgs__srv__BoundingBoxQuery_Request__rosidl_typesupport_introspection_c__BoundingBoxQuery_Request_message_member_array[0].members_ =
    ROSIDL_TYPESUPPORT_INTERFACE__MESSAGE_SYMBOL_NAME(rosidl_typesupport_introspection_c, geometry_msgs, msg, Point)();
  octomap_msgs__srv__BoundingBoxQuery_Request__rosidl_typesupport_introspection_c__BoundingBoxQuery_Request_message_member_array[1].members_ =
    ROSIDL_TYPESUPPORT_INTERFACE__MESSAGE_SYMBOL_NAME(rosidl_typesupport_introspection_c, geometry_msgs, msg, Point)();
  if (!octomap_msgs__srv__BoundingBoxQuery_Request__rosidl_typesupport_introspection_c__BoundingBoxQuery_Request_message_type_support_handle.typesupport_identifier) {
    octomap_msgs__srv__BoundingBoxQuery_Request__rosidl_typesupport_introspection_c__BoundingBoxQuery_Request_message_type_support_handle.typesupport_identifier =
      rosidl_typesupport_introspection_c__identifier;
  }
  return &octomap_msgs__srv__BoundingBoxQuery_Request__rosidl_typesupport_introspection_c__BoundingBoxQuery_Request_message_type_support_handle;
}
#ifdef __cplusplus
}
#endif

// already included above
// #include <stddef.h>
// already included above
// #include "octomap_msgs/srv/detail/bounding_box_query__rosidl_typesupport_introspection_c.h"
// already included above
// #include "octomap_msgs/msg/rosidl_typesupport_introspection_c__visibility_control.h"
// already included above
// #include "rosidl_typesupport_introspection_c/field_types.h"
// already included above
// #include "rosidl_typesupport_introspection_c/identifier.h"
// already included above
// #include "rosidl_typesupport_introspection_c/message_introspection.h"
// already included above
// #include "octomap_msgs/srv/detail/bounding_box_query__functions.h"
// already included above
// #include "octomap_msgs/srv/detail/bounding_box_query__struct.h"


#ifdef __cplusplus
extern "C"
{
#endif

void octomap_msgs__srv__BoundingBoxQuery_Response__rosidl_typesupport_introspection_c__BoundingBoxQuery_Response_init_function(
  void * message_memory, enum rosidl_runtime_c__message_initialization _init)
{
  // TODO(karsten1987): initializers are not yet implemented for typesupport c
  // see https://github.com/ros2/ros2/issues/397
  (void) _init;
  octomap_msgs__srv__BoundingBoxQuery_Response__init(message_memory);
}

void octomap_msgs__srv__BoundingBoxQuery_Response__rosidl_typesupport_introspection_c__BoundingBoxQuery_Response_fini_function(void * message_memory)
{
  octomap_msgs__srv__BoundingBoxQuery_Response__fini(message_memory);
}

static rosidl_typesupport_introspection_c__MessageMember octomap_msgs__srv__BoundingBoxQuery_Response__rosidl_typesupport_introspection_c__BoundingBoxQuery_Response_message_member_array[1] = {
  {
    "structure_needs_at_least_one_member",  // name
    rosidl_typesupport_introspection_c__ROS_TYPE_UINT8,  // type
    0,  // upper bound of string
    NULL,  // members of sub message
    false,  // is key
    false,  // is array
    0,  // array size
    false,  // is upper bound
    offsetof(octomap_msgs__srv__BoundingBoxQuery_Response, structure_needs_at_least_one_member),  // bytes offset in struct
    NULL,  // default value
    NULL,  // size() function pointer
    NULL,  // get_const(index) function pointer
    NULL,  // get(index) function pointer
    NULL,  // fetch(index, &value) function pointer
    NULL,  // assign(index, value) function pointer
    NULL  // resize(index) function pointer
  }
};

static const rosidl_typesupport_introspection_c__MessageMembers octomap_msgs__srv__BoundingBoxQuery_Response__rosidl_typesupport_introspection_c__BoundingBoxQuery_Response_message_members = {
  "octomap_msgs__srv",  // message namespace
  "BoundingBoxQuery_Response",  // message name
  1,  // number of fields
  sizeof(octomap_msgs__srv__BoundingBoxQuery_Response),
  false,  // has_any_key_member_
  octomap_msgs__srv__BoundingBoxQuery_Response__rosidl_typesupport_introspection_c__BoundingBoxQuery_Response_message_member_array,  // message members
  octomap_msgs__srv__BoundingBoxQuery_Response__rosidl_typesupport_introspection_c__BoundingBoxQuery_Response_init_function,  // function to initialize message memory (memory has to be allocated)
  octomap_msgs__srv__BoundingBoxQuery_Response__rosidl_typesupport_introspection_c__BoundingBoxQuery_Response_fini_function  // function to terminate message instance (will not free memory)
};

// this is not const since it must be initialized on first access
// since C does not allow non-integral compile-time constants
static rosidl_message_type_support_t octomap_msgs__srv__BoundingBoxQuery_Response__rosidl_typesupport_introspection_c__BoundingBoxQuery_Response_message_type_support_handle = {
  0,
  &octomap_msgs__srv__BoundingBoxQuery_Response__rosidl_typesupport_introspection_c__BoundingBoxQuery_Response_message_members,
  get_message_typesupport_handle_function,
  &octomap_msgs__srv__BoundingBoxQuery_Response__get_type_hash,
  &octomap_msgs__srv__BoundingBoxQuery_Response__get_type_description,
  &octomap_msgs__srv__BoundingBoxQuery_Response__get_type_description_sources,
};

ROSIDL_TYPESUPPORT_INTROSPECTION_C_EXPORT_octomap_msgs
const rosidl_message_type_support_t *
ROSIDL_TYPESUPPORT_INTERFACE__MESSAGE_SYMBOL_NAME(rosidl_typesupport_introspection_c, octomap_msgs, srv, BoundingBoxQuery_Response)() {
  if (!octomap_msgs__srv__BoundingBoxQuery_Response__rosidl_typesupport_introspection_c__BoundingBoxQuery_Response_message_type_support_handle.typesupport_identifier) {
    octomap_msgs__srv__BoundingBoxQuery_Response__rosidl_typesupport_introspection_c__BoundingBoxQuery_Response_message_type_support_handle.typesupport_identifier =
      rosidl_typesupport_introspection_c__identifier;
  }
  return &octomap_msgs__srv__BoundingBoxQuery_Response__rosidl_typesupport_introspection_c__BoundingBoxQuery_Response_message_type_support_handle;
}
#ifdef __cplusplus
}
#endif

// already included above
// #include <stddef.h>
// already included above
// #include "octomap_msgs/srv/detail/bounding_box_query__rosidl_typesupport_introspection_c.h"
// already included above
// #include "octomap_msgs/msg/rosidl_typesupport_introspection_c__visibility_control.h"
// already included above
// #include "rosidl_typesupport_introspection_c/field_types.h"
// already included above
// #include "rosidl_typesupport_introspection_c/identifier.h"
// already included above
// #include "rosidl_typesupport_introspection_c/message_introspection.h"
// already included above
// #include "octomap_msgs/srv/detail/bounding_box_query__functions.h"
// already included above
// #include "octomap_msgs/srv/detail/bounding_box_query__struct.h"


// Include directives for member types
// Member `info`
#include "service_msgs/msg/service_event_info.h"
// Member `info`
#include "service_msgs/msg/detail/service_event_info__rosidl_typesupport_introspection_c.h"
// Member `request`
// Member `response`
#include "octomap_msgs/srv/bounding_box_query.h"
// Member `request`
// Member `response`
// already included above
// #include "octomap_msgs/srv/detail/bounding_box_query__rosidl_typesupport_introspection_c.h"

#ifdef __cplusplus
extern "C"
{
#endif

void octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__BoundingBoxQuery_Event_init_function(
  void * message_memory, enum rosidl_runtime_c__message_initialization _init)
{
  // TODO(karsten1987): initializers are not yet implemented for typesupport c
  // see https://github.com/ros2/ros2/issues/397
  (void) _init;
  octomap_msgs__srv__BoundingBoxQuery_Event__init(message_memory);
}

void octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__BoundingBoxQuery_Event_fini_function(void * message_memory)
{
  octomap_msgs__srv__BoundingBoxQuery_Event__fini(message_memory);
}

size_t octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__size_function__BoundingBoxQuery_Event__request(
  const void * untyped_member)
{
  const octomap_msgs__srv__BoundingBoxQuery_Request__Sequence * member =
    (const octomap_msgs__srv__BoundingBoxQuery_Request__Sequence *)(untyped_member);
  return member->size;
}

const void * octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__get_const_function__BoundingBoxQuery_Event__request(
  const void * untyped_member, size_t index)
{
  const octomap_msgs__srv__BoundingBoxQuery_Request__Sequence * member =
    (const octomap_msgs__srv__BoundingBoxQuery_Request__Sequence *)(untyped_member);
  return &member->data[index];
}

void * octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__get_function__BoundingBoxQuery_Event__request(
  void * untyped_member, size_t index)
{
  octomap_msgs__srv__BoundingBoxQuery_Request__Sequence * member =
    (octomap_msgs__srv__BoundingBoxQuery_Request__Sequence *)(untyped_member);
  return &member->data[index];
}

void octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__fetch_function__BoundingBoxQuery_Event__request(
  const void * untyped_member, size_t index, void * untyped_value)
{
  const octomap_msgs__srv__BoundingBoxQuery_Request * item =
    ((const octomap_msgs__srv__BoundingBoxQuery_Request *)
    octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__get_const_function__BoundingBoxQuery_Event__request(untyped_member, index));
  octomap_msgs__srv__BoundingBoxQuery_Request * value =
    (octomap_msgs__srv__BoundingBoxQuery_Request *)(untyped_value);
  *value = *item;
}

void octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__assign_function__BoundingBoxQuery_Event__request(
  void * untyped_member, size_t index, const void * untyped_value)
{
  octomap_msgs__srv__BoundingBoxQuery_Request * item =
    ((octomap_msgs__srv__BoundingBoxQuery_Request *)
    octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__get_function__BoundingBoxQuery_Event__request(untyped_member, index));
  const octomap_msgs__srv__BoundingBoxQuery_Request * value =
    (const octomap_msgs__srv__BoundingBoxQuery_Request *)(untyped_value);
  *item = *value;
}

bool octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__resize_function__BoundingBoxQuery_Event__request(
  void * untyped_member, size_t size)
{
  octomap_msgs__srv__BoundingBoxQuery_Request__Sequence * member =
    (octomap_msgs__srv__BoundingBoxQuery_Request__Sequence *)(untyped_member);
  octomap_msgs__srv__BoundingBoxQuery_Request__Sequence__fini(member);
  return octomap_msgs__srv__BoundingBoxQuery_Request__Sequence__init(member, size);
}

size_t octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__size_function__BoundingBoxQuery_Event__response(
  const void * untyped_member)
{
  const octomap_msgs__srv__BoundingBoxQuery_Response__Sequence * member =
    (const octomap_msgs__srv__BoundingBoxQuery_Response__Sequence *)(untyped_member);
  return member->size;
}

const void * octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__get_const_function__BoundingBoxQuery_Event__response(
  const void * untyped_member, size_t index)
{
  const octomap_msgs__srv__BoundingBoxQuery_Response__Sequence * member =
    (const octomap_msgs__srv__BoundingBoxQuery_Response__Sequence *)(untyped_member);
  return &member->data[index];
}

void * octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__get_function__BoundingBoxQuery_Event__response(
  void * untyped_member, size_t index)
{
  octomap_msgs__srv__BoundingBoxQuery_Response__Sequence * member =
    (octomap_msgs__srv__BoundingBoxQuery_Response__Sequence *)(untyped_member);
  return &member->data[index];
}

void octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__fetch_function__BoundingBoxQuery_Event__response(
  const void * untyped_member, size_t index, void * untyped_value)
{
  const octomap_msgs__srv__BoundingBoxQuery_Response * item =
    ((const octomap_msgs__srv__BoundingBoxQuery_Response *)
    octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__get_const_function__BoundingBoxQuery_Event__response(untyped_member, index));
  octomap_msgs__srv__BoundingBoxQuery_Response * value =
    (octomap_msgs__srv__BoundingBoxQuery_Response *)(untyped_value);
  *value = *item;
}

void octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__assign_function__BoundingBoxQuery_Event__response(
  void * untyped_member, size_t index, const void * untyped_value)
{
  octomap_msgs__srv__BoundingBoxQuery_Response * item =
    ((octomap_msgs__srv__BoundingBoxQuery_Response *)
    octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__get_function__BoundingBoxQuery_Event__response(untyped_member, index));
  const octomap_msgs__srv__BoundingBoxQuery_Response * value =
    (const octomap_msgs__srv__BoundingBoxQuery_Response *)(untyped_value);
  *item = *value;
}

bool octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__resize_function__BoundingBoxQuery_Event__response(
  void * untyped_member, size_t size)
{
  octomap_msgs__srv__BoundingBoxQuery_Response__Sequence * member =
    (octomap_msgs__srv__BoundingBoxQuery_Response__Sequence *)(untyped_member);
  octomap_msgs__srv__BoundingBoxQuery_Response__Sequence__fini(member);
  return octomap_msgs__srv__BoundingBoxQuery_Response__Sequence__init(member, size);
}

static rosidl_typesupport_introspection_c__MessageMember octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__BoundingBoxQuery_Event_message_member_array[3] = {
  {
    "info",  // name
    rosidl_typesupport_introspection_c__ROS_TYPE_MESSAGE,  // type
    0,  // upper bound of string
    NULL,  // members of sub message (initialized later)
    false,  // is key
    false,  // is array
    0,  // array size
    false,  // is upper bound
    offsetof(octomap_msgs__srv__BoundingBoxQuery_Event, info),  // bytes offset in struct
    NULL,  // default value
    NULL,  // size() function pointer
    NULL,  // get_const(index) function pointer
    NULL,  // get(index) function pointer
    NULL,  // fetch(index, &value) function pointer
    NULL,  // assign(index, value) function pointer
    NULL  // resize(index) function pointer
  },
  {
    "request",  // name
    rosidl_typesupport_introspection_c__ROS_TYPE_MESSAGE,  // type
    0,  // upper bound of string
    NULL,  // members of sub message (initialized later)
    false,  // is key
    true,  // is array
    1,  // array size
    true,  // is upper bound
    offsetof(octomap_msgs__srv__BoundingBoxQuery_Event, request),  // bytes offset in struct
    NULL,  // default value
    octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__size_function__BoundingBoxQuery_Event__request,  // size() function pointer
    octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__get_const_function__BoundingBoxQuery_Event__request,  // get_const(index) function pointer
    octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__get_function__BoundingBoxQuery_Event__request,  // get(index) function pointer
    octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__fetch_function__BoundingBoxQuery_Event__request,  // fetch(index, &value) function pointer
    octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__assign_function__BoundingBoxQuery_Event__request,  // assign(index, value) function pointer
    octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__resize_function__BoundingBoxQuery_Event__request  // resize(index) function pointer
  },
  {
    "response",  // name
    rosidl_typesupport_introspection_c__ROS_TYPE_MESSAGE,  // type
    0,  // upper bound of string
    NULL,  // members of sub message (initialized later)
    false,  // is key
    true,  // is array
    1,  // array size
    true,  // is upper bound
    offsetof(octomap_msgs__srv__BoundingBoxQuery_Event, response),  // bytes offset in struct
    NULL,  // default value
    octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__size_function__BoundingBoxQuery_Event__response,  // size() function pointer
    octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__get_const_function__BoundingBoxQuery_Event__response,  // get_const(index) function pointer
    octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__get_function__BoundingBoxQuery_Event__response,  // get(index) function pointer
    octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__fetch_function__BoundingBoxQuery_Event__response,  // fetch(index, &value) function pointer
    octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__assign_function__BoundingBoxQuery_Event__response,  // assign(index, value) function pointer
    octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__resize_function__BoundingBoxQuery_Event__response  // resize(index) function pointer
  }
};

static const rosidl_typesupport_introspection_c__MessageMembers octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__BoundingBoxQuery_Event_message_members = {
  "octomap_msgs__srv",  // message namespace
  "BoundingBoxQuery_Event",  // message name
  3,  // number of fields
  sizeof(octomap_msgs__srv__BoundingBoxQuery_Event),
  false,  // has_any_key_member_
  octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__BoundingBoxQuery_Event_message_member_array,  // message members
  octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__BoundingBoxQuery_Event_init_function,  // function to initialize message memory (memory has to be allocated)
  octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__BoundingBoxQuery_Event_fini_function  // function to terminate message instance (will not free memory)
};

// this is not const since it must be initialized on first access
// since C does not allow non-integral compile-time constants
static rosidl_message_type_support_t octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__BoundingBoxQuery_Event_message_type_support_handle = {
  0,
  &octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__BoundingBoxQuery_Event_message_members,
  get_message_typesupport_handle_function,
  &octomap_msgs__srv__BoundingBoxQuery_Event__get_type_hash,
  &octomap_msgs__srv__BoundingBoxQuery_Event__get_type_description,
  &octomap_msgs__srv__BoundingBoxQuery_Event__get_type_description_sources,
};

ROSIDL_TYPESUPPORT_INTROSPECTION_C_EXPORT_octomap_msgs
const rosidl_message_type_support_t *
ROSIDL_TYPESUPPORT_INTERFACE__MESSAGE_SYMBOL_NAME(rosidl_typesupport_introspection_c, octomap_msgs, srv, BoundingBoxQuery_Event)() {
  octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__BoundingBoxQuery_Event_message_member_array[0].members_ =
    ROSIDL_TYPESUPPORT_INTERFACE__MESSAGE_SYMBOL_NAME(rosidl_typesupport_introspection_c, service_msgs, msg, ServiceEventInfo)();
  octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__BoundingBoxQuery_Event_message_member_array[1].members_ =
    ROSIDL_TYPESUPPORT_INTERFACE__MESSAGE_SYMBOL_NAME(rosidl_typesupport_introspection_c, octomap_msgs, srv, BoundingBoxQuery_Request)();
  octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__BoundingBoxQuery_Event_message_member_array[2].members_ =
    ROSIDL_TYPESUPPORT_INTERFACE__MESSAGE_SYMBOL_NAME(rosidl_typesupport_introspection_c, octomap_msgs, srv, BoundingBoxQuery_Response)();
  if (!octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__BoundingBoxQuery_Event_message_type_support_handle.typesupport_identifier) {
    octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__BoundingBoxQuery_Event_message_type_support_handle.typesupport_identifier =
      rosidl_typesupport_introspection_c__identifier;
  }
  return &octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__BoundingBoxQuery_Event_message_type_support_handle;
}
#ifdef __cplusplus
}
#endif

#include "rosidl_runtime_c/service_type_support_struct.h"
// already included above
// #include "octomap_msgs/msg/rosidl_typesupport_introspection_c__visibility_control.h"
// already included above
// #include "octomap_msgs/srv/detail/bounding_box_query__rosidl_typesupport_introspection_c.h"
// already included above
// #include "rosidl_typesupport_introspection_c/identifier.h"
#include "rosidl_typesupport_introspection_c/service_introspection.h"

// this is intentionally not const to allow initialization later to prevent an initialization race
static rosidl_typesupport_introspection_c__ServiceMembers octomap_msgs__srv__detail__bounding_box_query__rosidl_typesupport_introspection_c__BoundingBoxQuery_service_members = {
  "octomap_msgs__srv",  // service namespace
  "BoundingBoxQuery",  // service name
  // the following fields are initialized below on first access
  NULL,  // request message
  // octomap_msgs__srv__detail__bounding_box_query__rosidl_typesupport_introspection_c__BoundingBoxQuery_Request_message_type_support_handle,
  NULL,  // response message
  // octomap_msgs__srv__detail__bounding_box_query__rosidl_typesupport_introspection_c__BoundingBoxQuery_Response_message_type_support_handle
  NULL  // event_message
  // octomap_msgs__srv__detail__bounding_box_query__rosidl_typesupport_introspection_c__BoundingBoxQuery_Response_message_type_support_handle
};


static rosidl_service_type_support_t octomap_msgs__srv__detail__bounding_box_query__rosidl_typesupport_introspection_c__BoundingBoxQuery_service_type_support_handle = {
  0,
  &octomap_msgs__srv__detail__bounding_box_query__rosidl_typesupport_introspection_c__BoundingBoxQuery_service_members,
  get_service_typesupport_handle_function,
  &octomap_msgs__srv__BoundingBoxQuery_Request__rosidl_typesupport_introspection_c__BoundingBoxQuery_Request_message_type_support_handle,
  &octomap_msgs__srv__BoundingBoxQuery_Response__rosidl_typesupport_introspection_c__BoundingBoxQuery_Response_message_type_support_handle,
  &octomap_msgs__srv__BoundingBoxQuery_Event__rosidl_typesupport_introspection_c__BoundingBoxQuery_Event_message_type_support_handle,
  ROSIDL_TYPESUPPORT_INTERFACE__SERVICE_CREATE_EVENT_MESSAGE_SYMBOL_NAME(
    rosidl_typesupport_c,
    octomap_msgs,
    srv,
    BoundingBoxQuery
  ),
  ROSIDL_TYPESUPPORT_INTERFACE__SERVICE_DESTROY_EVENT_MESSAGE_SYMBOL_NAME(
    rosidl_typesupport_c,
    octomap_msgs,
    srv,
    BoundingBoxQuery
  ),
  &octomap_msgs__srv__BoundingBoxQuery__get_type_hash,
  &octomap_msgs__srv__BoundingBoxQuery__get_type_description,
  &octomap_msgs__srv__BoundingBoxQuery__get_type_description_sources,
};

// Forward declaration of message type support functions for service members
const rosidl_message_type_support_t *
ROSIDL_TYPESUPPORT_INTERFACE__MESSAGE_SYMBOL_NAME(rosidl_typesupport_introspection_c, octomap_msgs, srv, BoundingBoxQuery_Request)(void);

const rosidl_message_type_support_t *
ROSIDL_TYPESUPPORT_INTERFACE__MESSAGE_SYMBOL_NAME(rosidl_typesupport_introspection_c, octomap_msgs, srv, BoundingBoxQuery_Response)(void);

const rosidl_message_type_support_t *
ROSIDL_TYPESUPPORT_INTERFACE__MESSAGE_SYMBOL_NAME(rosidl_typesupport_introspection_c, octomap_msgs, srv, BoundingBoxQuery_Event)(void);

ROSIDL_TYPESUPPORT_INTROSPECTION_C_EXPORT_octomap_msgs
const rosidl_service_type_support_t *
ROSIDL_TYPESUPPORT_INTERFACE__SERVICE_SYMBOL_NAME(rosidl_typesupport_introspection_c, octomap_msgs, srv, BoundingBoxQuery)(void) {
  if (!octomap_msgs__srv__detail__bounding_box_query__rosidl_typesupport_introspection_c__BoundingBoxQuery_service_type_support_handle.typesupport_identifier) {
    octomap_msgs__srv__detail__bounding_box_query__rosidl_typesupport_introspection_c__BoundingBoxQuery_service_type_support_handle.typesupport_identifier =
      rosidl_typesupport_introspection_c__identifier;
  }
  rosidl_typesupport_introspection_c__ServiceMembers * service_members =
    (rosidl_typesupport_introspection_c__ServiceMembers *)octomap_msgs__srv__detail__bounding_box_query__rosidl_typesupport_introspection_c__BoundingBoxQuery_service_type_support_handle.data;

  if (!service_members->request_members_) {
    service_members->request_members_ =
      (const rosidl_typesupport_introspection_c__MessageMembers *)
      ROSIDL_TYPESUPPORT_INTERFACE__MESSAGE_SYMBOL_NAME(rosidl_typesupport_introspection_c, octomap_msgs, srv, BoundingBoxQuery_Request)()->data;
  }
  if (!service_members->response_members_) {
    service_members->response_members_ =
      (const rosidl_typesupport_introspection_c__MessageMembers *)
      ROSIDL_TYPESUPPORT_INTERFACE__MESSAGE_SYMBOL_NAME(rosidl_typesupport_introspection_c, octomap_msgs, srv, BoundingBoxQuery_Response)()->data;
  }
  if (!service_members->event_members_) {
    service_members->event_members_ =
      (const rosidl_typesupport_introspection_c__MessageMembers *)
      ROSIDL_TYPESUPPORT_INTERFACE__MESSAGE_SYMBOL_NAME(rosidl_typesupport_introspection_c, octomap_msgs, srv, BoundingBoxQuery_Event)()->data;
  }

  return &octomap_msgs__srv__detail__bounding_box_query__rosidl_typesupport_introspection_c__BoundingBoxQuery_service_type_support_handle;
}
