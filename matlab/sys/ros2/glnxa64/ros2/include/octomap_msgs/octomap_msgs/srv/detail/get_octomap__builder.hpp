// generated from rosidl_generator_cpp/resource/idl__builder.hpp.em
// with input from octomap_msgs:srv/GetOctomap.idl
// generated code does not contain a copyright notice

// IWYU pragma: private, include "octomap_msgs/srv/get_octomap.hpp"


#ifndef OCTOMAP_MSGS__SRV__DETAIL__GET_OCTOMAP__BUILDER_HPP_
#define OCTOMAP_MSGS__SRV__DETAIL__GET_OCTOMAP__BUILDER_HPP_

#include <algorithm>
#include <utility>

#include "octomap_msgs/srv/detail/get_octomap__struct.hpp"
#include "rosidl_runtime_cpp/message_initialization.hpp"


namespace octomap_msgs
{

namespace srv
{


}  // namespace srv

template<typename MessageType>
auto build();

template<>
inline
auto build<::octomap_msgs::srv::GetOctomap_Request>()
{
  return ::octomap_msgs::srv::GetOctomap_Request(rosidl_runtime_cpp::MessageInitialization::ZERO);
}

}  // namespace octomap_msgs


namespace octomap_msgs
{

namespace srv
{

namespace builder
{

class Init_GetOctomap_Response_map
{
public:
  Init_GetOctomap_Response_map()
  : msg_(::rosidl_runtime_cpp::MessageInitialization::SKIP)
  {}
  ::octomap_msgs::srv::GetOctomap_Response map(::octomap_msgs::srv::GetOctomap_Response::_map_type arg)
  {
    msg_.map = std::move(arg);
    return std::move(msg_);
  }

private:
  ::octomap_msgs::srv::GetOctomap_Response msg_;
};

}  // namespace builder

}  // namespace srv

template<typename MessageType>
auto build();

template<>
inline
auto build<::octomap_msgs::srv::GetOctomap_Response>()
{
  return octomap_msgs::srv::builder::Init_GetOctomap_Response_map();
}

}  // namespace octomap_msgs


namespace octomap_msgs
{

namespace srv
{

namespace builder
{

class Init_GetOctomap_Event_response
{
public:
  explicit Init_GetOctomap_Event_response(::octomap_msgs::srv::GetOctomap_Event & msg)
  : msg_(msg)
  {}
  ::octomap_msgs::srv::GetOctomap_Event response(::octomap_msgs::srv::GetOctomap_Event::_response_type arg)
  {
    msg_.response = std::move(arg);
    return std::move(msg_);
  }

private:
  ::octomap_msgs::srv::GetOctomap_Event msg_;
};

class Init_GetOctomap_Event_request
{
public:
  explicit Init_GetOctomap_Event_request(::octomap_msgs::srv::GetOctomap_Event & msg)
  : msg_(msg)
  {}
  Init_GetOctomap_Event_response request(::octomap_msgs::srv::GetOctomap_Event::_request_type arg)
  {
    msg_.request = std::move(arg);
    return Init_GetOctomap_Event_response(msg_);
  }

private:
  ::octomap_msgs::srv::GetOctomap_Event msg_;
};

class Init_GetOctomap_Event_info
{
public:
  Init_GetOctomap_Event_info()
  : msg_(::rosidl_runtime_cpp::MessageInitialization::SKIP)
  {}
  Init_GetOctomap_Event_request info(::octomap_msgs::srv::GetOctomap_Event::_info_type arg)
  {
    msg_.info = std::move(arg);
    return Init_GetOctomap_Event_request(msg_);
  }

private:
  ::octomap_msgs::srv::GetOctomap_Event msg_;
};

}  // namespace builder

}  // namespace srv

template<typename MessageType>
auto build();

template<>
inline
auto build<::octomap_msgs::srv::GetOctomap_Event>()
{
  return octomap_msgs::srv::builder::Init_GetOctomap_Event_info();
}

}  // namespace octomap_msgs

#endif  // OCTOMAP_MSGS__SRV__DETAIL__GET_OCTOMAP__BUILDER_HPP_
