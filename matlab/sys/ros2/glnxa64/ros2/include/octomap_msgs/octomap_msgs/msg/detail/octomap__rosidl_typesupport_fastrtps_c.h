// generated from rosidl_typesupport_fastrtps_c/resource/idl__rosidl_typesupport_fastrtps_c.h.em
// with input from octomap_msgs:msg/Octomap.idl
// generated code does not contain a copyright notice
#ifndef OCTOMAP_MSGS__MSG__DETAIL__OCTOMAP__ROSIDL_TYPESUPPORT_FASTRTPS_C_H_
#define OCTOMAP_MSGS__MSG__DETAIL__OCTOMAP__ROSIDL_TYPESUPPORT_FASTRTPS_C_H_


#include <stddef.h>
#include "rosidl_runtime_c/message_type_support_struct.h"
#include "rosidl_typesupport_interface/macros.h"
#include "octomap_msgs/msg/rosidl_typesupport_fastrtps_c__visibility_control.h"
#include "octomap_msgs/msg/detail/octomap__struct.h"
#include "fastcdr/Cdr.h"

#ifdef __cplusplus
extern "C"
{
#endif

ROSIDL_TYPESUPPORT_FASTRTPS_C_PUBLIC_octomap_msgs
bool cdr_serialize_octomap_msgs__msg__Octomap(
  const octomap_msgs__msg__Octomap * ros_message,
  eprosima::fastcdr::Cdr & cdr);

ROSIDL_TYPESUPPORT_FASTRTPS_C_PUBLIC_octomap_msgs
bool cdr_deserialize_octomap_msgs__msg__Octomap(
  eprosima::fastcdr::Cdr &,
  octomap_msgs__msg__Octomap * ros_message);

ROSIDL_TYPESUPPORT_FASTRTPS_C_PUBLIC_octomap_msgs
size_t get_serialized_size_octomap_msgs__msg__Octomap(
  const void * untyped_ros_message,
  size_t current_alignment);

ROSIDL_TYPESUPPORT_FASTRTPS_C_PUBLIC_octomap_msgs
size_t max_serialized_size_octomap_msgs__msg__Octomap(
  bool & full_bounded,
  bool & is_plain,
  size_t current_alignment);

ROSIDL_TYPESUPPORT_FASTRTPS_C_PUBLIC_octomap_msgs
bool cdr_serialize_key_octomap_msgs__msg__Octomap(
  const octomap_msgs__msg__Octomap * ros_message,
  eprosima::fastcdr::Cdr & cdr);

ROSIDL_TYPESUPPORT_FASTRTPS_C_PUBLIC_octomap_msgs
size_t get_serialized_size_key_octomap_msgs__msg__Octomap(
  const void * untyped_ros_message,
  size_t current_alignment);

ROSIDL_TYPESUPPORT_FASTRTPS_C_PUBLIC_octomap_msgs
size_t max_serialized_size_key_octomap_msgs__msg__Octomap(
  bool & full_bounded,
  bool & is_plain,
  size_t current_alignment);

ROSIDL_TYPESUPPORT_FASTRTPS_C_PUBLIC_octomap_msgs
const rosidl_message_type_support_t *
ROSIDL_TYPESUPPORT_INTERFACE__MESSAGE_SYMBOL_NAME(rosidl_typesupport_fastrtps_c, octomap_msgs, msg, Octomap)();

#ifdef __cplusplus
}
#endif

#endif  // OCTOMAP_MSGS__MSG__DETAIL__OCTOMAP__ROSIDL_TYPESUPPORT_FASTRTPS_C_H_
