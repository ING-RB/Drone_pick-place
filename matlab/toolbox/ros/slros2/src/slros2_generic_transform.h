/* Copyright 2023-2024 The MathWorks, Inc. */

#ifndef _SLROS2_GENERIC_TRANSFORM_H_
#define _SLROS2_GENERIC_TRANSFORM_H_

#include <iostream>
#include "rclcpp/rclcpp.hpp"
#include "rclcpp/qos.hpp"
#include "slros_busmsg_conversion.cpp"

// Transformation
#include <tf2_ros/buffer.h>
#include <geometry_msgs/msg/transform_stamped.h>
#include <tf2_ros/transform_listener.h>

inline rclcpp::QoS getQOSSettingsFromRMW(const rmw_qos_profile_t& qosProfile);

/**
 * Class for ROS 2 Transformation in C++.
 *
 * This class is used by code generated from the Simulink ROS 2
 * "Get Transform" blocks.
 */
class SimulinkTransform {
  public:
    void createTfTree(const rmw_qos_profile_t& dynamicListenerQoS,
                      const rmw_qos_profile_t& staticListenerQoS);
    bool canTransform(const std::string& targetFrame,
                      const std::string& sourceFrame);
    void getTransform(SL_Bus_geometry_msgs_TransformStamped* busPtr,
                      const std::string& targetFrame,
                      const std::string& sourceFrame);
    void getCacheTime(bool* cacheTimeStatus, int32_t* sec, uint32_t* nSec);
  private:
    rclcpp::Node::SharedPtr mOptionalDefaultNode_;
    std::shared_ptr<tf2_ros::Buffer> mTFBuffer_{nullptr};
    std::shared_ptr<tf2_ros::TransformListener> mTFListener_{nullptr};
};

/**
 * Create a ROS 2 Transformation Tree
 *
 * @param dynamicListenerQoS QoS profile of the Dynamic Listener
 * @param staticListenerQoS QoS profile of Static Listener
 */
inline void SimulinkTransform::createTfTree(const rmw_qos_profile_t& qosProfileDynamic,
                                     const rmw_qos_profile_t& qosProfileStatic) {
    
    // Set the default buffer time to 10s
    int32_t sec = 10;
    uint32_t nSec = 0;

    // Get current cache time
    int32_t currentSec;
    uint32_t currentNsec;
    bool cacheTimeStatus = false;
    getCacheTime(&cacheTimeStatus, &currentSec, &currentNsec);
    if (cacheTimeStatus && (currentSec == sec) &&
        (currentNsec == nSec)) {
        // if everything is equal, return;
        return;
    }

    //TransformerListener constructor expects a temporary node.
    // create a temporary node and specify a unique name.
    std::stringstream sstream;
    sstream << "transform_listener_impl_" << std::hex << reinterpret_cast<size_t>(this);
    rclcpp::NodeOptions options;
    // but specify its name in .arguments to override any __node passed on the command line
    options.arguments({"--ros-args", "-r", "__node:=" + std::string(sstream.str())});
    options.start_parameter_event_publisher(false);
    options.start_parameter_services(false);
    mOptionalDefaultNode_ = rclcpp::Node::make_shared("_", options);

    // Otherwise, create new buffer and new listener with the new cache time
    rclcpp::Duration d(sec, nSec);
    mTFBuffer_ = std::make_shared<tf2_ros::Buffer>(mOptionalDefaultNode_->get_clock(),tf2_ros::fromRclcpp(d));
    mTFListener_ = std::make_shared<tf2_ros::TransformListener>(*mTFBuffer_,
                                                                mOptionalDefaultNode_,
                                                                true,
                                                                getQOSSettingsFromRMW(qosProfileDynamic),
                                                                getQOSSettingsFromRMW(qosProfileStatic));
}

/**
 * Test if a transform is possible
 *
 * @param targetFrame target frame name
 * @param sourceFrame source frame name
 */
inline bool SimulinkTransform::canTransform(const std::string& targetFrame,
                  const std::string& sourceFrame) {
    bool isAvailable =
        mTFBuffer_->canTransform(targetFrame, sourceFrame,
                                 rclcpp::Time(0,0), rclcpp::Duration(0,0));
    return isAvailable;
}

/**
 * Get the transform between two frames by frame ID.
 * @param busPtr pointer to bus structure for the TransformStamped message
 * @param targetFrame target frame name
 * @param sourceFrame source frame name
 */
inline void SimulinkTransform::getTransform(SL_Bus_geometry_msgs_TransformStamped* busPtr,
                      const std::string& targetFrame,
                      const std::string& sourceFrame) {
    // Check if listener and buffer are initialized. Else throw ROS_ERROR
    if (!mTFBuffer_.get() || !mTFListener_.get()) {
        return;
    }

    // Return empty transformStamped message if there is no valid transformation in Network
    try {
        geometry_msgs::msg::TransformStamped tfStampedMsg = mTFBuffer_->lookupTransform(
            targetFrame, sourceFrame, rclcpp::Time(0, 0),
            rclcpp::Duration(0, 0));
        convertToBus(busPtr, tfStampedMsg);
    } catch (...) {
    }
}

/**
* Get the cache time of the transformation buffer
* @param cacheTimeStatus boolean pointer to track whether cache Time is available
* @param sec sec field of cache time
* @param nSec nanosec field of cache time
*/
inline void SimulinkTransform::getCacheTime(bool* cacheTimeStatus, int32_t* sec, uint32_t* nSec) {
    if (mTFBuffer_.get() && mTFListener_.get()) {
        auto d = mTFBuffer_->getCacheLength();
        auto nanosInSec = 1000000000;
        *sec = static_cast<int32_t>(d.count()/nanosInSec);
        *nSec = static_cast<uint32_t>(d.count()%nanosInSec);
        *cacheTimeStatus = true;
    }
    *cacheTimeStatus = false;
}

#endif