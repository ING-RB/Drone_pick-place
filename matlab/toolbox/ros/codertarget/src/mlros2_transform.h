// Copyright 2022-2023 The MathWorks, Inc.
#ifndef _MLROS2_TRANSFORM_H
#define _MLROS2_TRANSFORM_H

#include <iostream>
#include <memory>
#include <string>
#include <algorithm> // For std::sort
#include <chrono>

// Transformation
#include <tf2_ros/buffer.h>
#include <tf2_ros/static_transform_broadcaster.h>
#include <geometry_msgs/msg/transform_stamped.h>
#include <tf2_ros/transform_listener.h>

#include <tf2/LinearMath/Quaternion.h>
#include <tf2_ros/transform_broadcaster.h>

#include "rclcpp/rclcpp.hpp"
#include "mlros2_qos.h"
#include "ros2_structmsg_conversion.h" // For struct2msg()
#include <rcutils/logging_macros.h>

#define ROS_WARN RCUTILS_LOG_WARN
#define ROS_ERROR RCUTILS_LOG_ERROR

#define MATLABROS2Transform_createTfTree(obj, theNode, dynamicBroadcasterQoS, staticBroadcasterQoS, dynamicListenerQoS, staticListenerQoS) \
   obj->createTfTree(theNode, dynamicBroadcasterQoS, staticBroadcasterQoS, dynamicListenerQoS, staticListenerQoS)

#define MATLABROS2Transform_lookupTransform(obj, transformStampedStructPtr, mlTargetFrame, mlTargetFrameSize, mlSourceFrame, mlSourceFrameSize, \
                         targetTimeSec, targetTimeNsec, timeoutSec, timeoutNsec) \
   obj->lookupTransform(transformStampedStructPtr, mlTargetFrame, mlTargetFrameSize, mlSourceFrame, mlSourceFrameSize, \
                         targetTimeSec, targetTimeNsec, timeoutSec, timeoutNsec)

#define MATLABROS2Transform_sendTransform(obj,transformStampedStructPtr) \
   obj->sendTransform(transformStampedStructPtr)

#define MATLABROS2Transform_sendStaticTransform(obj,transformStampedStructPtr) \
   obj->sendStaticTransform(transformStampedStructPtr)

#define MATLABROS2Transform_canTransform(obj, isTransformAvailable, mlTargetFrame, mlTargetFrameSize, mlSourceFrame, mlSourceFrameSize, targetTimeSec, targetTimeNsec) \
   obj->canTransform(isTransformAvailable, mlTargetFrame, mlTargetFrameSize, mlSourceFrame, mlSourceFrameSize, targetTimeSec, targetTimeNsec)

#define MATLABROS2Transform_getCacheTime(obj, cacheTimeStatus, sec, nSec) \
   obj->getCacheTime(cacheTimeStatus, sec, nSec)

#define MATLABROS2Transform_setCacheTime(obj, sec, nSec) \
   obj->setCacheTime(sec, nSec)

#define MATLABROS2Transform_updateAndGetNumOfFrames(obj, numFrames) \
   obj->updateAndGetNumOfFrames(numFrames)

#define MATLABROS2Transform_getFrameNameLength(obj, key, frameLength) \
   obj->getFrameNameLength(key, frameLength)

#define MATLABROS2Transform_getAvailableFrame(obj, key, frameEntry) \
   obj->getAvailableFrame(key, frameEntry)

class MATLABROS2Transform {
        rclcpp::Node::SharedPtr mNode_;
        rclcpp::Node::SharedPtr mOptionalDefaultNode_;
        rmw_qos_profile_t mDynamicBroadcasterQos_;
        rmw_qos_profile_t mStaticBroadcasterQos_;
        rmw_qos_profile_t mDynamicListenerQos_;
        rmw_qos_profile_t mStaticListenerQos_;

        std::shared_ptr<tf2_ros::Buffer> mTfBuffer_;
        std::shared_ptr<tf2_ros::TransformListener> mTfListener_;
        std::shared_ptr<tf2_ros::TransformBroadcaster> mTfBroadcaster_;
        std::shared_ptr<tf2_ros::StaticTransformBroadcaster> mStaticTfBroadcaster_;
        std::shared_ptr<geometry_msgs::msg::TransformStamped> mTfMsgPtr_;
        std::shared_ptr<geometry_msgs_TransformStampedStruct_T> mTfStructPtr_;
        std::vector<std::string> mframeNames_{};

    public:
        RCLCPP_SMART_PTR_DEFINITIONS(MATLABROS2Transform)
        MATLABROS2Transform(): mNode_(nullptr),
        mOptionalDefaultNode_(nullptr),
        mDynamicBroadcasterQos_(rmw_qos_profile_default),
        mStaticBroadcasterQos_(rmw_qos_profile_default),
        mDynamicListenerQos_(rmw_qos_profile_default),
        mStaticListenerQos_(rmw_qos_profile_default),
        mTfBuffer_(nullptr),
        mTfListener_(nullptr),
        mTfBroadcaster_(nullptr),
        mStaticTfBroadcaster_(nullptr){};

    /**
    * Method to create a ROS 2 Transformation Tree.
    * @param theNode Shared pointer to the ROS 2 Node Handle
    * @param dynamicBroadcasterQos QoS profile of the Dynamic Broadcaster
    * @param staticBroadcasterQos QoS profile of the Static Broadcaster
    * @param dynamicListenerQos QoS profile of the Dynamic Listener
    * @param staticListenerQos QoS profile of the Static Listener
    */
    void createTfTree(rclcpp::Node::SharedPtr theNode,
                      const rmw_qos_profile_t& dynamicBroadcasterQos = rmw_qos_profile_default,
                      const rmw_qos_profile_t& staticBroadcasterQos = rmw_qos_profile_default,
                      const rmw_qos_profile_t& dynamicListenerQos = rmw_qos_profile_default,
                      const rmw_qos_profile_t& staticListenerQos = rmw_qos_profile_default) {
        mNode_ = theNode;
        mDynamicBroadcasterQos_ = dynamicBroadcasterQos;
        mStaticBroadcasterQos_ = staticBroadcasterQos;
        mDynamicListenerQos_ = dynamicListenerQos;
        mStaticListenerQos_ = staticListenerQos;

        mTfBroadcaster_ = std::make_shared<tf2_ros::TransformBroadcaster>(mNode_, getQOSSettingsFromRMW(mDynamicBroadcasterQos_));
        mStaticTfBroadcaster_ = std::make_shared<tf2_ros::StaticTransformBroadcaster>(mNode_, getQOSSettingsFromRMW(mStaticBroadcasterQos_));

        // Set the default buffer time to 10s
        setCacheTime(10, 0);
    }

    /**
    * Get the transform between two frames by frame ID.
    * @param transformStampedStruct message struct to be passed to MATLAB class
    * @param mlTargetFrame target frame name
    * @param mlTargetFrameSize size of target frame name
    * @param mlSourceFrame source frame name
    * @param mlSourceFrameSize size of source frame name
    * @param targetTimeSec sec field of target time
    * @param targetTimeNsec nanosec field of target time
    * @param timeoutSec sec field of timeout
    * @param timeoutNsec nanoec field of timeout
    */
    void lookupTransform(geometry_msgs_TransformStampedStruct_T* transformStampedStruct,
                         const char* mlTargetFrame,
                         size_t mlTargetFrameSize,
                         const char* mlSourceFrame,
                         size_t mlSourceFrameSize,
                         int32_t targetTimeSec,
                         uint32_t targetTimeNsec,
                         int32_t timeoutSec,
                         uint32_t timeoutNsec) {
        // Check if listener and buffer are initialized.
        if (!mTfBuffer_.get() || !mTfListener_.get()) {
            return;
        }

        std::string targetFrame(mlTargetFrame, mlTargetFrameSize);
        std::string sourceFrame(mlSourceFrame, mlSourceFrameSize);

        // Create an empty tf message
        mTfStructPtr_ = std::make_shared<geometry_msgs_TransformStampedStruct_T>();

        // Return empty transformStamped message if there is no valid transformation in Network
        try {
            geometry_msgs::msg::TransformStamped tfStampedMsg = mTfBuffer_->lookupTransform(
                targetFrame, sourceFrame, rclcpp::Time(targetTimeSec, targetTimeNsec),
                rclcpp::Duration(timeoutSec, timeoutNsec));
            msg2struct(mTfStructPtr_.get(), tfStampedMsg);
        } catch (...) {
        }

        *transformStampedStruct = *mTfStructPtr_;
    }

    /**
    * Send a StampedTransform including frame_id, parent_id, and time over /tf topic.
    * @param transformStampedStruct message struct from MATLAB class
    */
    void sendTransform(const geometry_msgs_TransformStampedStruct_T transformStampedStruct) {
        const geometry_msgs_TransformStampedStruct_T* structPtr = &transformStampedStruct;
        mTfMsgPtr_ = std::make_shared<geometry_msgs::msg::TransformStamped>();
        struct2msg(*mTfMsgPtr_.get(), structPtr);
        mTfBroadcaster_->sendTransform(*mTfMsgPtr_);
    }

    /**
    * Send a StampedTransform including frame_id, parent_id, and time over /tf_static topic.
    * @param transformStampedStruct message struct from MATLAB class
    */
    void sendStaticTransform(const geometry_msgs_TransformStampedStruct_T transformStampedStruct) {
        const geometry_msgs_TransformStampedStruct_T* structPtr = &transformStampedStruct;
        mTfMsgPtr_ = std::make_shared<geometry_msgs::msg::TransformStamped>();
        struct2msg(*mTfMsgPtr_.get(), structPtr);
        mStaticTfBroadcaster_->sendTransform(*mTfMsgPtr_);
    }

    /**
    * Test if a transform is possible.
    * @param isTransformAvailable boolean pointer to track whether transform is available
    * @param mlTargetFrame target frame name
    * @param mlTargetFrameSize size of target frame name
    * @param mlSourceFrame source frame name
    * @param mlSourceFrameSize size of source frame name
    * @param targetTimeSec sec field of target time
    * @param targetTimeNsec nanosec field of target time
    */
    void canTransform(bool* isTransformAvailable, 
                      const char* mlTargetFrame,
                      size_t mlTargetFrameSize,
                      const char* mlSourceFrame,
                      size_t mlSourceFrameSize,
                      int32_t targetTimeSec,
                      uint32_t targetTimeNsec) {

        std::string targetFrame(mlTargetFrame, mlTargetFrameSize);
        std::string sourceFrame(mlSourceFrame, mlSourceFrameSize);

        *isTransformAvailable =
            mTfBuffer_->canTransform(targetFrame, sourceFrame,
                                     rclcpp::Time(targetTimeSec, targetTimeNsec), rclcpp::Duration(0, 0));

    }

    /**
    * Get the cache time of the transformation buffer
    * @param cacheTimeStatus boolean pointer to track whether cache Time is available
    * @param sec sec field of cache time
    * @param nSec nanosec field of cache time
    */
    void getCacheTime(bool* cacheTimeStatus, int32_t* sec, uint32_t* nSec) {
        if (mTfBuffer_.get() && mTfListener_.get()) {
            auto d = mTfBuffer_->getCacheLength();
            auto nanosInSec = 1000000000;
            *sec = static_cast<int32_t>(d.count()/nanosInSec);
            *nSec = static_cast<uint32_t>(d.count()%nanosInSec);
            *cacheTimeStatus = true;
        }
        *cacheTimeStatus = false;
    }

    /**
    * Set the cache time of the transformation buffer
    * @param sec sec field of cache time
    * @param nSec nanosec field of cache time
    */
    void setCacheTime(int32_t sec, uint32_t nSec) {
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
        mTfBuffer_ = std::make_shared<tf2_ros::Buffer>(mNode_->get_clock(),tf2_ros::fromRclcpp(d));
        mTfListener_ = std::make_shared<tf2_ros::TransformListener>(*mTfBuffer_,
                                                                    mOptionalDefaultNode_,
                                                                    true,
                                                                    getQOSSettingsFromRMW(mDynamicListenerQos_),
                                                                    getQOSSettingsFromRMW(mStaticListenerQos_));
    }

    /**
    * Update and get number of available frames from ROS 2 network
    */
    void updateAndGetNumOfFrames(int32_t* numFrames) {
        // Get name of available frames from network
        if (mTfBuffer_.get() && mTfListener_.get()) {
            mTfBuffer_->_getFrameStrings(mframeNames_);
            std::sort(mframeNames_.begin(), mframeNames_.end());
            *numFrames = mframeNames_.size();
        } else {
            *numFrames = 0;
        }
    }

    /**
    * Get the length of specific frame 
    * @param key index of specific frame
    * @param frameLength pointer to length of each frame
    */
    void getFrameNameLength(int key, int32_t* frameLength) {
        *frameLength = mframeNames_[key].size();
    }

    /**
    * Get the specific frame name given frame index
    * @param key index of specific frame
    * @param frameEntry name of the frame
    */
    void getAvailableFrame(int key, char* frameEntry) {
        if (mframeNames_.size() > 0) {
            int32_t frameNameLen = 0;
            const char* frameStr = mframeNames_[key].c_str();
            getFrameNameLength(key, &frameNameLen);
            strncpy(frameEntry, frameStr, frameNameLen);
            frameEntry[frameNameLen] = 0;
        } else {
            frameEntry[0] = 0;
        }
    }
};

#endif