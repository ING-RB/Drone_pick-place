// generated from rosidl_generator_c/resource/idl__functions.h.em
// with input from octomap_msgs:srv/BoundingBoxQuery.idl
// generated code does not contain a copyright notice

// IWYU pragma: private, include "octomap_msgs/srv/bounding_box_query.h"


#ifndef OCTOMAP_MSGS__SRV__DETAIL__BOUNDING_BOX_QUERY__FUNCTIONS_H_
#define OCTOMAP_MSGS__SRV__DETAIL__BOUNDING_BOX_QUERY__FUNCTIONS_H_

#ifdef __cplusplus
extern "C"
{
#endif

#include <stdbool.h>
#include <stdlib.h>

#include "rosidl_runtime_c/action_type_support_struct.h"
#include "rosidl_runtime_c/message_type_support_struct.h"
#include "rosidl_runtime_c/service_type_support_struct.h"
#include "rosidl_runtime_c/type_description/type_description__struct.h"
#include "rosidl_runtime_c/type_description/type_source__struct.h"
#include "rosidl_runtime_c/type_hash.h"
#include "rosidl_runtime_c/visibility_control.h"
#include "octomap_msgs/msg/rosidl_generator_c__visibility_control.h"

#include "octomap_msgs/srv/detail/bounding_box_query__struct.h"

/// Retrieve pointer to the hash of the description of this type.
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_type_hash_t *
octomap_msgs__srv__BoundingBoxQuery__get_type_hash(
  const rosidl_service_type_support_t * type_support);

/// Retrieve pointer to the description of this type.
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_runtime_c__type_description__TypeDescription *
octomap_msgs__srv__BoundingBoxQuery__get_type_description(
  const rosidl_service_type_support_t * type_support);

/// Retrieve pointer to the single raw source text that defined this type.
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_runtime_c__type_description__TypeSource *
octomap_msgs__srv__BoundingBoxQuery__get_individual_type_description_source(
  const rosidl_service_type_support_t * type_support);

/// Retrieve pointer to the recursive raw sources that defined the description of this type.
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_runtime_c__type_description__TypeSource__Sequence *
octomap_msgs__srv__BoundingBoxQuery__get_type_description_sources(
  const rosidl_service_type_support_t * type_support);

/// Initialize srv/BoundingBoxQuery message.
/**
 * If the init function is called twice for the same message without
 * calling fini inbetween previously allocated memory will be leaked.
 * \param[in,out] msg The previously allocated message pointer.
 * Fields without a default value will not be initialized by this function.
 * You might want to call memset(msg, 0, sizeof(
 * octomap_msgs__srv__BoundingBoxQuery_Request
 * )) before or use
 * octomap_msgs__srv__BoundingBoxQuery_Request__create()
 * to allocate and initialize the message.
 * \return true if initialization was successful, otherwise false
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
bool
octomap_msgs__srv__BoundingBoxQuery_Request__init(octomap_msgs__srv__BoundingBoxQuery_Request * msg);

/// Finalize srv/BoundingBoxQuery message.
/**
 * \param[in,out] msg The allocated message pointer.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
void
octomap_msgs__srv__BoundingBoxQuery_Request__fini(octomap_msgs__srv__BoundingBoxQuery_Request * msg);

/// Create srv/BoundingBoxQuery message.
/**
 * It allocates the memory for the message, sets the memory to zero, and
 * calls
 * octomap_msgs__srv__BoundingBoxQuery_Request__init().
 * \return The pointer to the initialized message if successful,
 * otherwise NULL
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
octomap_msgs__srv__BoundingBoxQuery_Request *
octomap_msgs__srv__BoundingBoxQuery_Request__create(void);

/// Destroy srv/BoundingBoxQuery message.
/**
 * It calls
 * octomap_msgs__srv__BoundingBoxQuery_Request__fini()
 * and frees the memory of the message.
 * \param[in,out] msg The allocated message pointer.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
void
octomap_msgs__srv__BoundingBoxQuery_Request__destroy(octomap_msgs__srv__BoundingBoxQuery_Request * msg);

/// Check for srv/BoundingBoxQuery message equality.
/**
 * \param[in] lhs The message on the left hand size of the equality operator.
 * \param[in] rhs The message on the right hand size of the equality operator.
 * \return true if messages are equal, otherwise false.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
bool
octomap_msgs__srv__BoundingBoxQuery_Request__are_equal(const octomap_msgs__srv__BoundingBoxQuery_Request * lhs, const octomap_msgs__srv__BoundingBoxQuery_Request * rhs);

/// Copy a srv/BoundingBoxQuery message.
/**
 * This functions performs a deep copy, as opposed to the shallow copy that
 * plain assignment yields.
 *
 * \param[in] input The source message pointer.
 * \param[out] output The target message pointer, which must
 *   have been initialized before calling this function.
 * \return true if successful, or false if either pointer is null
 *   or memory allocation fails.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
bool
octomap_msgs__srv__BoundingBoxQuery_Request__copy(
  const octomap_msgs__srv__BoundingBoxQuery_Request * input,
  octomap_msgs__srv__BoundingBoxQuery_Request * output);

/// Retrieve pointer to the hash of the description of this type.
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_type_hash_t *
octomap_msgs__srv__BoundingBoxQuery_Request__get_type_hash(
  const rosidl_message_type_support_t * type_support);

/// Retrieve pointer to the description of this type.
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_runtime_c__type_description__TypeDescription *
octomap_msgs__srv__BoundingBoxQuery_Request__get_type_description(
  const rosidl_message_type_support_t * type_support);

/// Retrieve pointer to the single raw source text that defined this type.
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_runtime_c__type_description__TypeSource *
octomap_msgs__srv__BoundingBoxQuery_Request__get_individual_type_description_source(
  const rosidl_message_type_support_t * type_support);

/// Retrieve pointer to the recursive raw sources that defined the description of this type.
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_runtime_c__type_description__TypeSource__Sequence *
octomap_msgs__srv__BoundingBoxQuery_Request__get_type_description_sources(
  const rosidl_message_type_support_t * type_support);

/// Initialize array of srv/BoundingBoxQuery messages.
/**
 * It allocates the memory for the number of elements and calls
 * octomap_msgs__srv__BoundingBoxQuery_Request__init()
 * for each element of the array.
 * \param[in,out] array The allocated array pointer.
 * \param[in] size The size / capacity of the array.
 * \return true if initialization was successful, otherwise false
 * If the array pointer is valid and the size is zero it is guaranteed
 # to return true.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
bool
octomap_msgs__srv__BoundingBoxQuery_Request__Sequence__init(octomap_msgs__srv__BoundingBoxQuery_Request__Sequence * array, size_t size);

/// Finalize array of srv/BoundingBoxQuery messages.
/**
 * It calls
 * octomap_msgs__srv__BoundingBoxQuery_Request__fini()
 * for each element of the array and frees the memory for the number of
 * elements.
 * \param[in,out] array The initialized array pointer.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
void
octomap_msgs__srv__BoundingBoxQuery_Request__Sequence__fini(octomap_msgs__srv__BoundingBoxQuery_Request__Sequence * array);

/// Create array of srv/BoundingBoxQuery messages.
/**
 * It allocates the memory for the array and calls
 * octomap_msgs__srv__BoundingBoxQuery_Request__Sequence__init().
 * \param[in] size The size / capacity of the array.
 * \return The pointer to the initialized array if successful, otherwise NULL
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
octomap_msgs__srv__BoundingBoxQuery_Request__Sequence *
octomap_msgs__srv__BoundingBoxQuery_Request__Sequence__create(size_t size);

/// Destroy array of srv/BoundingBoxQuery messages.
/**
 * It calls
 * octomap_msgs__srv__BoundingBoxQuery_Request__Sequence__fini()
 * on the array,
 * and frees the memory of the array.
 * \param[in,out] array The initialized array pointer.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
void
octomap_msgs__srv__BoundingBoxQuery_Request__Sequence__destroy(octomap_msgs__srv__BoundingBoxQuery_Request__Sequence * array);

/// Check for srv/BoundingBoxQuery message array equality.
/**
 * \param[in] lhs The message array on the left hand size of the equality operator.
 * \param[in] rhs The message array on the right hand size of the equality operator.
 * \return true if message arrays are equal in size and content, otherwise false.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
bool
octomap_msgs__srv__BoundingBoxQuery_Request__Sequence__are_equal(const octomap_msgs__srv__BoundingBoxQuery_Request__Sequence * lhs, const octomap_msgs__srv__BoundingBoxQuery_Request__Sequence * rhs);

/// Copy an array of srv/BoundingBoxQuery messages.
/**
 * This functions performs a deep copy, as opposed to the shallow copy that
 * plain assignment yields.
 *
 * \param[in] input The source array pointer.
 * \param[out] output The target array pointer, which must
 *   have been initialized before calling this function.
 * \return true if successful, or false if either pointer
 *   is null or memory allocation fails.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
bool
octomap_msgs__srv__BoundingBoxQuery_Request__Sequence__copy(
  const octomap_msgs__srv__BoundingBoxQuery_Request__Sequence * input,
  octomap_msgs__srv__BoundingBoxQuery_Request__Sequence * output);

/// Initialize srv/BoundingBoxQuery message.
/**
 * If the init function is called twice for the same message without
 * calling fini inbetween previously allocated memory will be leaked.
 * \param[in,out] msg The previously allocated message pointer.
 * Fields without a default value will not be initialized by this function.
 * You might want to call memset(msg, 0, sizeof(
 * octomap_msgs__srv__BoundingBoxQuery_Response
 * )) before or use
 * octomap_msgs__srv__BoundingBoxQuery_Response__create()
 * to allocate and initialize the message.
 * \return true if initialization was successful, otherwise false
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
bool
octomap_msgs__srv__BoundingBoxQuery_Response__init(octomap_msgs__srv__BoundingBoxQuery_Response * msg);

/// Finalize srv/BoundingBoxQuery message.
/**
 * \param[in,out] msg The allocated message pointer.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
void
octomap_msgs__srv__BoundingBoxQuery_Response__fini(octomap_msgs__srv__BoundingBoxQuery_Response * msg);

/// Create srv/BoundingBoxQuery message.
/**
 * It allocates the memory for the message, sets the memory to zero, and
 * calls
 * octomap_msgs__srv__BoundingBoxQuery_Response__init().
 * \return The pointer to the initialized message if successful,
 * otherwise NULL
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
octomap_msgs__srv__BoundingBoxQuery_Response *
octomap_msgs__srv__BoundingBoxQuery_Response__create(void);

/// Destroy srv/BoundingBoxQuery message.
/**
 * It calls
 * octomap_msgs__srv__BoundingBoxQuery_Response__fini()
 * and frees the memory of the message.
 * \param[in,out] msg The allocated message pointer.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
void
octomap_msgs__srv__BoundingBoxQuery_Response__destroy(octomap_msgs__srv__BoundingBoxQuery_Response * msg);

/// Check for srv/BoundingBoxQuery message equality.
/**
 * \param[in] lhs The message on the left hand size of the equality operator.
 * \param[in] rhs The message on the right hand size of the equality operator.
 * \return true if messages are equal, otherwise false.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
bool
octomap_msgs__srv__BoundingBoxQuery_Response__are_equal(const octomap_msgs__srv__BoundingBoxQuery_Response * lhs, const octomap_msgs__srv__BoundingBoxQuery_Response * rhs);

/// Copy a srv/BoundingBoxQuery message.
/**
 * This functions performs a deep copy, as opposed to the shallow copy that
 * plain assignment yields.
 *
 * \param[in] input The source message pointer.
 * \param[out] output The target message pointer, which must
 *   have been initialized before calling this function.
 * \return true if successful, or false if either pointer is null
 *   or memory allocation fails.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
bool
octomap_msgs__srv__BoundingBoxQuery_Response__copy(
  const octomap_msgs__srv__BoundingBoxQuery_Response * input,
  octomap_msgs__srv__BoundingBoxQuery_Response * output);

/// Retrieve pointer to the hash of the description of this type.
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_type_hash_t *
octomap_msgs__srv__BoundingBoxQuery_Response__get_type_hash(
  const rosidl_message_type_support_t * type_support);

/// Retrieve pointer to the description of this type.
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_runtime_c__type_description__TypeDescription *
octomap_msgs__srv__BoundingBoxQuery_Response__get_type_description(
  const rosidl_message_type_support_t * type_support);

/// Retrieve pointer to the single raw source text that defined this type.
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_runtime_c__type_description__TypeSource *
octomap_msgs__srv__BoundingBoxQuery_Response__get_individual_type_description_source(
  const rosidl_message_type_support_t * type_support);

/// Retrieve pointer to the recursive raw sources that defined the description of this type.
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_runtime_c__type_description__TypeSource__Sequence *
octomap_msgs__srv__BoundingBoxQuery_Response__get_type_description_sources(
  const rosidl_message_type_support_t * type_support);

/// Initialize array of srv/BoundingBoxQuery messages.
/**
 * It allocates the memory for the number of elements and calls
 * octomap_msgs__srv__BoundingBoxQuery_Response__init()
 * for each element of the array.
 * \param[in,out] array The allocated array pointer.
 * \param[in] size The size / capacity of the array.
 * \return true if initialization was successful, otherwise false
 * If the array pointer is valid and the size is zero it is guaranteed
 # to return true.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
bool
octomap_msgs__srv__BoundingBoxQuery_Response__Sequence__init(octomap_msgs__srv__BoundingBoxQuery_Response__Sequence * array, size_t size);

/// Finalize array of srv/BoundingBoxQuery messages.
/**
 * It calls
 * octomap_msgs__srv__BoundingBoxQuery_Response__fini()
 * for each element of the array and frees the memory for the number of
 * elements.
 * \param[in,out] array The initialized array pointer.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
void
octomap_msgs__srv__BoundingBoxQuery_Response__Sequence__fini(octomap_msgs__srv__BoundingBoxQuery_Response__Sequence * array);

/// Create array of srv/BoundingBoxQuery messages.
/**
 * It allocates the memory for the array and calls
 * octomap_msgs__srv__BoundingBoxQuery_Response__Sequence__init().
 * \param[in] size The size / capacity of the array.
 * \return The pointer to the initialized array if successful, otherwise NULL
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
octomap_msgs__srv__BoundingBoxQuery_Response__Sequence *
octomap_msgs__srv__BoundingBoxQuery_Response__Sequence__create(size_t size);

/// Destroy array of srv/BoundingBoxQuery messages.
/**
 * It calls
 * octomap_msgs__srv__BoundingBoxQuery_Response__Sequence__fini()
 * on the array,
 * and frees the memory of the array.
 * \param[in,out] array The initialized array pointer.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
void
octomap_msgs__srv__BoundingBoxQuery_Response__Sequence__destroy(octomap_msgs__srv__BoundingBoxQuery_Response__Sequence * array);

/// Check for srv/BoundingBoxQuery message array equality.
/**
 * \param[in] lhs The message array on the left hand size of the equality operator.
 * \param[in] rhs The message array on the right hand size of the equality operator.
 * \return true if message arrays are equal in size and content, otherwise false.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
bool
octomap_msgs__srv__BoundingBoxQuery_Response__Sequence__are_equal(const octomap_msgs__srv__BoundingBoxQuery_Response__Sequence * lhs, const octomap_msgs__srv__BoundingBoxQuery_Response__Sequence * rhs);

/// Copy an array of srv/BoundingBoxQuery messages.
/**
 * This functions performs a deep copy, as opposed to the shallow copy that
 * plain assignment yields.
 *
 * \param[in] input The source array pointer.
 * \param[out] output The target array pointer, which must
 *   have been initialized before calling this function.
 * \return true if successful, or false if either pointer
 *   is null or memory allocation fails.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
bool
octomap_msgs__srv__BoundingBoxQuery_Response__Sequence__copy(
  const octomap_msgs__srv__BoundingBoxQuery_Response__Sequence * input,
  octomap_msgs__srv__BoundingBoxQuery_Response__Sequence * output);

/// Initialize srv/BoundingBoxQuery message.
/**
 * If the init function is called twice for the same message without
 * calling fini inbetween previously allocated memory will be leaked.
 * \param[in,out] msg The previously allocated message pointer.
 * Fields without a default value will not be initialized by this function.
 * You might want to call memset(msg, 0, sizeof(
 * octomap_msgs__srv__BoundingBoxQuery_Event
 * )) before or use
 * octomap_msgs__srv__BoundingBoxQuery_Event__create()
 * to allocate and initialize the message.
 * \return true if initialization was successful, otherwise false
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
bool
octomap_msgs__srv__BoundingBoxQuery_Event__init(octomap_msgs__srv__BoundingBoxQuery_Event * msg);

/// Finalize srv/BoundingBoxQuery message.
/**
 * \param[in,out] msg The allocated message pointer.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
void
octomap_msgs__srv__BoundingBoxQuery_Event__fini(octomap_msgs__srv__BoundingBoxQuery_Event * msg);

/// Create srv/BoundingBoxQuery message.
/**
 * It allocates the memory for the message, sets the memory to zero, and
 * calls
 * octomap_msgs__srv__BoundingBoxQuery_Event__init().
 * \return The pointer to the initialized message if successful,
 * otherwise NULL
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
octomap_msgs__srv__BoundingBoxQuery_Event *
octomap_msgs__srv__BoundingBoxQuery_Event__create(void);

/// Destroy srv/BoundingBoxQuery message.
/**
 * It calls
 * octomap_msgs__srv__BoundingBoxQuery_Event__fini()
 * and frees the memory of the message.
 * \param[in,out] msg The allocated message pointer.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
void
octomap_msgs__srv__BoundingBoxQuery_Event__destroy(octomap_msgs__srv__BoundingBoxQuery_Event * msg);

/// Check for srv/BoundingBoxQuery message equality.
/**
 * \param[in] lhs The message on the left hand size of the equality operator.
 * \param[in] rhs The message on the right hand size of the equality operator.
 * \return true if messages are equal, otherwise false.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
bool
octomap_msgs__srv__BoundingBoxQuery_Event__are_equal(const octomap_msgs__srv__BoundingBoxQuery_Event * lhs, const octomap_msgs__srv__BoundingBoxQuery_Event * rhs);

/// Copy a srv/BoundingBoxQuery message.
/**
 * This functions performs a deep copy, as opposed to the shallow copy that
 * plain assignment yields.
 *
 * \param[in] input The source message pointer.
 * \param[out] output The target message pointer, which must
 *   have been initialized before calling this function.
 * \return true if successful, or false if either pointer is null
 *   or memory allocation fails.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
bool
octomap_msgs__srv__BoundingBoxQuery_Event__copy(
  const octomap_msgs__srv__BoundingBoxQuery_Event * input,
  octomap_msgs__srv__BoundingBoxQuery_Event * output);

/// Retrieve pointer to the hash of the description of this type.
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_type_hash_t *
octomap_msgs__srv__BoundingBoxQuery_Event__get_type_hash(
  const rosidl_message_type_support_t * type_support);

/// Retrieve pointer to the description of this type.
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_runtime_c__type_description__TypeDescription *
octomap_msgs__srv__BoundingBoxQuery_Event__get_type_description(
  const rosidl_message_type_support_t * type_support);

/// Retrieve pointer to the single raw source text that defined this type.
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_runtime_c__type_description__TypeSource *
octomap_msgs__srv__BoundingBoxQuery_Event__get_individual_type_description_source(
  const rosidl_message_type_support_t * type_support);

/// Retrieve pointer to the recursive raw sources that defined the description of this type.
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_runtime_c__type_description__TypeSource__Sequence *
octomap_msgs__srv__BoundingBoxQuery_Event__get_type_description_sources(
  const rosidl_message_type_support_t * type_support);

/// Initialize array of srv/BoundingBoxQuery messages.
/**
 * It allocates the memory for the number of elements and calls
 * octomap_msgs__srv__BoundingBoxQuery_Event__init()
 * for each element of the array.
 * \param[in,out] array The allocated array pointer.
 * \param[in] size The size / capacity of the array.
 * \return true if initialization was successful, otherwise false
 * If the array pointer is valid and the size is zero it is guaranteed
 # to return true.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
bool
octomap_msgs__srv__BoundingBoxQuery_Event__Sequence__init(octomap_msgs__srv__BoundingBoxQuery_Event__Sequence * array, size_t size);

/// Finalize array of srv/BoundingBoxQuery messages.
/**
 * It calls
 * octomap_msgs__srv__BoundingBoxQuery_Event__fini()
 * for each element of the array and frees the memory for the number of
 * elements.
 * \param[in,out] array The initialized array pointer.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
void
octomap_msgs__srv__BoundingBoxQuery_Event__Sequence__fini(octomap_msgs__srv__BoundingBoxQuery_Event__Sequence * array);

/// Create array of srv/BoundingBoxQuery messages.
/**
 * It allocates the memory for the array and calls
 * octomap_msgs__srv__BoundingBoxQuery_Event__Sequence__init().
 * \param[in] size The size / capacity of the array.
 * \return The pointer to the initialized array if successful, otherwise NULL
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
octomap_msgs__srv__BoundingBoxQuery_Event__Sequence *
octomap_msgs__srv__BoundingBoxQuery_Event__Sequence__create(size_t size);

/// Destroy array of srv/BoundingBoxQuery messages.
/**
 * It calls
 * octomap_msgs__srv__BoundingBoxQuery_Event__Sequence__fini()
 * on the array,
 * and frees the memory of the array.
 * \param[in,out] array The initialized array pointer.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
void
octomap_msgs__srv__BoundingBoxQuery_Event__Sequence__destroy(octomap_msgs__srv__BoundingBoxQuery_Event__Sequence * array);

/// Check for srv/BoundingBoxQuery message array equality.
/**
 * \param[in] lhs The message array on the left hand size of the equality operator.
 * \param[in] rhs The message array on the right hand size of the equality operator.
 * \return true if message arrays are equal in size and content, otherwise false.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
bool
octomap_msgs__srv__BoundingBoxQuery_Event__Sequence__are_equal(const octomap_msgs__srv__BoundingBoxQuery_Event__Sequence * lhs, const octomap_msgs__srv__BoundingBoxQuery_Event__Sequence * rhs);

/// Copy an array of srv/BoundingBoxQuery messages.
/**
 * This functions performs a deep copy, as opposed to the shallow copy that
 * plain assignment yields.
 *
 * \param[in] input The source array pointer.
 * \param[out] output The target array pointer, which must
 *   have been initialized before calling this function.
 * \return true if successful, or false if either pointer
 *   is null or memory allocation fails.
 */
ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
bool
octomap_msgs__srv__BoundingBoxQuery_Event__Sequence__copy(
  const octomap_msgs__srv__BoundingBoxQuery_Event__Sequence * input,
  octomap_msgs__srv__BoundingBoxQuery_Event__Sequence * output);
#ifdef __cplusplus
}
#endif

#endif  // OCTOMAP_MSGS__SRV__DETAIL__BOUNDING_BOX_QUERY__FUNCTIONS_H_
