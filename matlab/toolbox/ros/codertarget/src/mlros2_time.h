// Copyright 2022 The MathWorks, Inc.
#ifndef _MLROS2_TIME_H
#define _MLROS2_TIME_H

#include "rclcpp/rclcpp.hpp"
#include "mlros2_node.h"

template <class MsgStructType>
inline bool time2struct(MsgStructType* msgStruct, bool isSystemTime) {
    bool isSimTime;
    auto secinnanos = 1000000000;

    if (isSystemTime) {
        // Use wall clock time
        static auto time = rclcpp::Clock(RCL_SYSTEM_TIME);
        auto nanos = time.now().nanoseconds();
        msgStruct->sec = static_cast<int32_t>(RCL_NS_TO_S(nanos));
        msgStruct->nanosec = static_cast<uint32_t>(nanos % (secinnanos));
        isSimTime = false;
    } else {
        // Use ROS 2 simulation time
        rclcpp::Node::SharedPtr nodeHandle = MATLAB::getGlobalNodeHandle();
        auto clockSharedPtr = nodeHandle->get_clock();
        bool isSimTime = clockSharedPtr->ros_time_is_active();

        rclcpp::Time time = nodeHandle->now();
        msgStruct->sec = static_cast<int32_t>(RCL_NS_TO_S(time.nanoseconds()));
        msgStruct->nanosec = static_cast<uint32_t>(time.nanoseconds() % (secinnanos));
    }

    return isSimTime;
}

inline bool getSimTime() {
    rclcpp::Node::SharedPtr nodeHandle = MATLAB::getGlobalNodeHandle();
    auto clockSharedPtr = nodeHandle->get_clock();
    return clockSharedPtr->ros_time_is_active();
}

#endif
