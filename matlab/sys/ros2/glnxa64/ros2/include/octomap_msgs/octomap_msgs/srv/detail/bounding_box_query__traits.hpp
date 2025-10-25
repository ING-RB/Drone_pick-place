// generated from rosidl_generator_cpp/resource/idl__traits.hpp.em
// with input from octomap_msgs:srv/BoundingBoxQuery.idl
// generated code does not contain a copyright notice

// IWYU pragma: private, include "octomap_msgs/srv/bounding_box_query.hpp"


#ifndef OCTOMAP_MSGS__SRV__DETAIL__BOUNDING_BOX_QUERY__TRAITS_HPP_
#define OCTOMAP_MSGS__SRV__DETAIL__BOUNDING_BOX_QUERY__TRAITS_HPP_

#include <stdint.h>

#include <sstream>
#include <string>
#include <type_traits>

#include "octomap_msgs/srv/detail/bounding_box_query__struct.hpp"
#include "rosidl_runtime_cpp/traits.hpp"

// Include directives for member types
// Member 'min'
// Member 'max'
#include "geometry_msgs/msg/detail/point__traits.hpp"

namespace octomap_msgs
{

namespace srv
{

inline void to_flow_style_yaml(
  const BoundingBoxQuery_Request & msg,
  std::ostream & out)
{
  out << "{";
  // member: min
  {
    out << "min: ";
    to_flow_style_yaml(msg.min, out);
    out << ", ";
  }

  // member: max
  {
    out << "max: ";
    to_flow_style_yaml(msg.max, out);
  }
  out << "}";
}  // NOLINT(readability/fn_size)

inline void to_block_style_yaml(
  const BoundingBoxQuery_Request & msg,
  std::ostream & out, size_t indentation = 0)
{
  // member: min
  {
    if (indentation > 0) {
      out << std::string(indentation, ' ');
    }
    out << "min:\n";
    to_block_style_yaml(msg.min, out, indentation + 2);
  }

  // member: max
  {
    if (indentation > 0) {
      out << std::string(indentation, ' ');
    }
    out << "max:\n";
    to_block_style_yaml(msg.max, out, indentation + 2);
  }
}  // NOLINT(readability/fn_size)

inline std::string to_yaml(const BoundingBoxQuery_Request & msg, bool use_flow_style = false)
{
  std::ostringstream out;
  if (use_flow_style) {
    to_flow_style_yaml(msg, out);
  } else {
    to_block_style_yaml(msg, out);
  }
  return out.str();
}

}  // namespace srv

}  // namespace octomap_msgs

namespace rosidl_generator_traits
{

[[deprecated("use octomap_msgs::srv::to_block_style_yaml() instead")]]
inline void to_yaml(
  const octomap_msgs::srv::BoundingBoxQuery_Request & msg,
  std::ostream & out, size_t indentation = 0)
{
  octomap_msgs::srv::to_block_style_yaml(msg, out, indentation);
}

[[deprecated("use octomap_msgs::srv::to_yaml() instead")]]
inline std::string to_yaml(const octomap_msgs::srv::BoundingBoxQuery_Request & msg)
{
  return octomap_msgs::srv::to_yaml(msg);
}

template<>
inline const char * data_type<octomap_msgs::srv::BoundingBoxQuery_Request>()
{
  return "octomap_msgs::srv::BoundingBoxQuery_Request";
}

template<>
inline const char * name<octomap_msgs::srv::BoundingBoxQuery_Request>()
{
  return "octomap_msgs/srv/BoundingBoxQuery_Request";
}

template<>
struct has_fixed_size<octomap_msgs::srv::BoundingBoxQuery_Request>
  : std::integral_constant<bool, has_fixed_size<geometry_msgs::msg::Point>::value> {};

template<>
struct has_bounded_size<octomap_msgs::srv::BoundingBoxQuery_Request>
  : std::integral_constant<bool, has_bounded_size<geometry_msgs::msg::Point>::value> {};

template<>
struct is_message<octomap_msgs::srv::BoundingBoxQuery_Request>
  : std::true_type {};

}  // namespace rosidl_generator_traits

namespace octomap_msgs
{

namespace srv
{

inline void to_flow_style_yaml(
  const BoundingBoxQuery_Response & msg,
  std::ostream & out)
{
  (void)msg;
  out << "null";
}  // NOLINT(readability/fn_size)

inline void to_block_style_yaml(
  const BoundingBoxQuery_Response & msg,
  std::ostream & out, size_t indentation = 0)
{
  (void)msg;
  (void)indentation;
  out << "null\n";
}  // NOLINT(readability/fn_size)

inline std::string to_yaml(const BoundingBoxQuery_Response & msg, bool use_flow_style = false)
{
  std::ostringstream out;
  if (use_flow_style) {
    to_flow_style_yaml(msg, out);
  } else {
    to_block_style_yaml(msg, out);
  }
  return out.str();
}

}  // namespace srv

}  // namespace octomap_msgs

namespace rosidl_generator_traits
{

[[deprecated("use octomap_msgs::srv::to_block_style_yaml() instead")]]
inline void to_yaml(
  const octomap_msgs::srv::BoundingBoxQuery_Response & msg,
  std::ostream & out, size_t indentation = 0)
{
  octomap_msgs::srv::to_block_style_yaml(msg, out, indentation);
}

[[deprecated("use octomap_msgs::srv::to_yaml() instead")]]
inline std::string to_yaml(const octomap_msgs::srv::BoundingBoxQuery_Response & msg)
{
  return octomap_msgs::srv::to_yaml(msg);
}

template<>
inline const char * data_type<octomap_msgs::srv::BoundingBoxQuery_Response>()
{
  return "octomap_msgs::srv::BoundingBoxQuery_Response";
}

template<>
inline const char * name<octomap_msgs::srv::BoundingBoxQuery_Response>()
{
  return "octomap_msgs/srv/BoundingBoxQuery_Response";
}

template<>
struct has_fixed_size<octomap_msgs::srv::BoundingBoxQuery_Response>
  : std::integral_constant<bool, true> {};

template<>
struct has_bounded_size<octomap_msgs::srv::BoundingBoxQuery_Response>
  : std::integral_constant<bool, true> {};

template<>
struct is_message<octomap_msgs::srv::BoundingBoxQuery_Response>
  : std::true_type {};

}  // namespace rosidl_generator_traits

// Include directives for member types
// Member 'info'
#include "service_msgs/msg/detail/service_event_info__traits.hpp"

namespace octomap_msgs
{

namespace srv
{

inline void to_flow_style_yaml(
  const BoundingBoxQuery_Event & msg,
  std::ostream & out)
{
  out << "{";
  // member: info
  {
    out << "info: ";
    to_flow_style_yaml(msg.info, out);
    out << ", ";
  }

  // member: request
  {
    if (msg.request.size() == 0) {
      out << "request: []";
    } else {
      out << "request: [";
      size_t pending_items = msg.request.size();
      for (auto item : msg.request) {
        to_flow_style_yaml(item, out);
        if (--pending_items > 0) {
          out << ", ";
        }
      }
      out << "]";
    }
    out << ", ";
  }

  // member: response
  {
    if (msg.response.size() == 0) {
      out << "response: []";
    } else {
      out << "response: [";
      size_t pending_items = msg.response.size();
      for (auto item : msg.response) {
        to_flow_style_yaml(item, out);
        if (--pending_items > 0) {
          out << ", ";
        }
      }
      out << "]";
    }
  }
  out << "}";
}  // NOLINT(readability/fn_size)

inline void to_block_style_yaml(
  const BoundingBoxQuery_Event & msg,
  std::ostream & out, size_t indentation = 0)
{
  // member: info
  {
    if (indentation > 0) {
      out << std::string(indentation, ' ');
    }
    out << "info:\n";
    to_block_style_yaml(msg.info, out, indentation + 2);
  }

  // member: request
  {
    if (indentation > 0) {
      out << std::string(indentation, ' ');
    }
    if (msg.request.size() == 0) {
      out << "request: []\n";
    } else {
      out << "request:\n";
      for (auto item : msg.request) {
        if (indentation > 0) {
          out << std::string(indentation, ' ');
        }
        out << "-\n";
        to_block_style_yaml(item, out, indentation + 2);
      }
    }
  }

  // member: response
  {
    if (indentation > 0) {
      out << std::string(indentation, ' ');
    }
    if (msg.response.size() == 0) {
      out << "response: []\n";
    } else {
      out << "response:\n";
      for (auto item : msg.response) {
        if (indentation > 0) {
          out << std::string(indentation, ' ');
        }
        out << "-\n";
        to_block_style_yaml(item, out, indentation + 2);
      }
    }
  }
}  // NOLINT(readability/fn_size)

inline std::string to_yaml(const BoundingBoxQuery_Event & msg, bool use_flow_style = false)
{
  std::ostringstream out;
  if (use_flow_style) {
    to_flow_style_yaml(msg, out);
  } else {
    to_block_style_yaml(msg, out);
  }
  return out.str();
}

}  // namespace srv

}  // namespace octomap_msgs

namespace rosidl_generator_traits
{

[[deprecated("use octomap_msgs::srv::to_block_style_yaml() instead")]]
inline void to_yaml(
  const octomap_msgs::srv::BoundingBoxQuery_Event & msg,
  std::ostream & out, size_t indentation = 0)
{
  octomap_msgs::srv::to_block_style_yaml(msg, out, indentation);
}

[[deprecated("use octomap_msgs::srv::to_yaml() instead")]]
inline std::string to_yaml(const octomap_msgs::srv::BoundingBoxQuery_Event & msg)
{
  return octomap_msgs::srv::to_yaml(msg);
}

template<>
inline const char * data_type<octomap_msgs::srv::BoundingBoxQuery_Event>()
{
  return "octomap_msgs::srv::BoundingBoxQuery_Event";
}

template<>
inline const char * name<octomap_msgs::srv::BoundingBoxQuery_Event>()
{
  return "octomap_msgs/srv/BoundingBoxQuery_Event";
}

template<>
struct has_fixed_size<octomap_msgs::srv::BoundingBoxQuery_Event>
  : std::integral_constant<bool, false> {};

template<>
struct has_bounded_size<octomap_msgs::srv::BoundingBoxQuery_Event>
  : std::integral_constant<bool, has_bounded_size<octomap_msgs::srv::BoundingBoxQuery_Request>::value && has_bounded_size<octomap_msgs::srv::BoundingBoxQuery_Response>::value && has_bounded_size<service_msgs::msg::ServiceEventInfo>::value> {};

template<>
struct is_message<octomap_msgs::srv::BoundingBoxQuery_Event>
  : std::true_type {};

}  // namespace rosidl_generator_traits

namespace rosidl_generator_traits
{

template<>
inline const char * data_type<octomap_msgs::srv::BoundingBoxQuery>()
{
  return "octomap_msgs::srv::BoundingBoxQuery";
}

template<>
inline const char * name<octomap_msgs::srv::BoundingBoxQuery>()
{
  return "octomap_msgs/srv/BoundingBoxQuery";
}

template<>
struct has_fixed_size<octomap_msgs::srv::BoundingBoxQuery>
  : std::integral_constant<
    bool,
    has_fixed_size<octomap_msgs::srv::BoundingBoxQuery_Request>::value &&
    has_fixed_size<octomap_msgs::srv::BoundingBoxQuery_Response>::value
  >
{
};

template<>
struct has_bounded_size<octomap_msgs::srv::BoundingBoxQuery>
  : std::integral_constant<
    bool,
    has_bounded_size<octomap_msgs::srv::BoundingBoxQuery_Request>::value &&
    has_bounded_size<octomap_msgs::srv::BoundingBoxQuery_Response>::value
  >
{
};

template<>
struct is_service<octomap_msgs::srv::BoundingBoxQuery>
  : std::true_type
{
};

template<>
struct is_service_request<octomap_msgs::srv::BoundingBoxQuery_Request>
  : std::true_type
{
};

template<>
struct is_service_response<octomap_msgs::srv::BoundingBoxQuery_Response>
  : std::true_type
{
};

}  // namespace rosidl_generator_traits

#endif  // OCTOMAP_MSGS__SRV__DETAIL__BOUNDING_BOX_QUERY__TRAITS_HPP_
