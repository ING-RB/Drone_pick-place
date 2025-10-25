// Copyright 2021-2024 The MathWorks, Inc.
#ifndef _MLROS2_PUB_H
#define _MLROS2_PUB_H

#include <iostream>
#include <memory>
#include <string>
#include <mutex>
#include "rclcpp/rclcpp.hpp"
#include "mlros2_qos.h"
#include "ros2_structmsg_conversion.h" // For struct2msg()
#include <type_traits>

#define MATLABROS2Publisher_createPublisher(obj,theNode,mlTopic,mlTopicSize,qos_profile) \
    obj->createPublisher(theNode,mlTopic,mlTopicSize,qos_profile)
#define MATLABROS2Publisher_publish(obj,structPtr) obj->publish(structPtr)
#define MATLABROS2Publisher_getLatestDeadlineMissedStatus(obj, totalCount, totalCountChange) \
    obj->getLatestDeadlineMissedStatus(totalCount, totalCountChange)
#define MATLABROS2Publisher_getLatestLivelinessLostStatus(obj, totalCount, totalCountChange) \
    obj->getLatestLivelinessLostStatus(totalCount, totalCountChange)
#define MATLABROS2Publisher_getLatestIncompatibleQoSStatus(obj, totalCount, totalCountChange, lastPolicyKind) \
    obj->getLatestIncompatibleQoSStatus(totalCount, totalCountChange, lastPolicyKind)
#define MATLABROS2Publisher_deadlineMissedWarning(obj, nodeHandle) obj->deadlineMissedWarning(nodeHandle)
#define MATLABROS2Publisher_livelinessLostWarning(obj, nodeHandle) obj->livelinessLostWarning(nodeHandle)
#define MATLABROS2Publisher_incompatibleQoSWarning(obj, nodeHandle) obj->incompatibleQoSWarning(nodeHandle)

// Structures for holding QoS event data.
typedef struct PubQoSEventStructType {
    int32_t TotalCount;
    int32_t TotalCountChange;
} PubQoSEventStructType_T;

typedef struct PubQoSEventIncompatibleStructType {
    int32_t TotalCount;
    int32_t TotalCountChange;
    std::string LastPolicyKind;
} PubQoSEventIncompatibleStructType_T;

template <class MsgType, class StructType>
class MATLABROS2Publisher {
    std::function<void(void)> MATLABOfferedDeadlineMissedCallback_;
    std::function<void(void)> MATLABLivelinessLostCallback_;
    std::function<void(void)> MATLABIncompatibleQoSCallback_;
    std::string topicName_;
    std::shared_ptr<rclcpp::Publisher<MsgType>> mPub_;
    std::shared_ptr<MsgType> msgPtr_;
    PubQoSEventStructType_T* deadlineStructPtr_ = new PubQoSEventStructType_T();
    PubQoSEventStructType_T* livelinessStructPtr_ = new PubQoSEventStructType_T();
    PubQoSEventIncompatibleStructType_T* incompatibleQoSStructPtr_ = new PubQoSEventIncompatibleStructType_T();
    std::mutex mtx_;
  public:
    RCLCPP_SMART_PTR_DEFINITIONS(MATLABROS2Publisher)
    MATLABROS2Publisher(std::function<void(void)> deadline_callback, std::function<void(void)> liveliness_callback, std::function<void(void)> incompatible_qos_callback)
        : MATLABOfferedDeadlineMissedCallback_{deadline_callback}
        , MATLABLivelinessLostCallback_{liveliness_callback}
        , MATLABIncompatibleQoSCallback_{incompatible_qos_callback}
        , msgPtr_(new MsgType) {
    }

    /**
    * Method to create a ROS 2 publisher.
    * @param theNode Shared pointer to the ROS 2 Node Handle
    * @param mlTopic Topic on which a message is to be published.
    * @param mlTopicSize size to handle string inputs.
    * @param qos_profile qos settings.
    */
    void createPublisher(rclcpp::Node::SharedPtr theNode,
                         const char* mlTopic,
                         size_t mlTopicSize,
                         const rmw_qos_profile_t& qos_profile = rmw_qos_profile_default) {
         topicName_ = std::string(mlTopic, mlTopicSize);

         // Set of supported RMWs for QoS event callbacks
        const std::set<std::string> supportedRMWs = {
            "rmw_fastrtps_cpp",
            "rmw_fastrtps_dynamic_cpp",
            "rmw_cyclonedds_cpp",
            "rmw_connextdds"
        };

        // Check if RMW_IMPLEMENTATION is set and supported
        const char* rmw_impl_env = std::getenv("RMW_IMPLEMENTATION");
        std::string rmw_impl = rmw_impl_env ? std::string(rmw_impl_env) : "";
        bool enable_qos_events = rmw_impl.empty() || supportedRMWs.find(rmw_impl) != supportedRMWs.end();

        rclcpp::PublisherOptions publisher_options;
        
        if(enable_qos_events){
            publisher_options.event_callbacks.deadline_callback = [this](rclcpp::QOSDeadlineOfferedInfo& event) {
                std::lock_guard<std::mutex> lockMsg(mtx_);
                deadlineStructPtr_->TotalCount = event.total_count;
                deadlineStructPtr_->TotalCountChange = event.total_count_change;
                MATLABOfferedDeadlineMissedCallback_();
            };
        
            publisher_options.event_callbacks.liveliness_callback = [this](rclcpp::QOSLivelinessLostInfo& event) {
                std::lock_guard<std::mutex> lockMsg(mtx_);
                livelinessStructPtr_->TotalCount = event.total_count;
                livelinessStructPtr_->TotalCountChange = event.total_count_change;
                MATLABLivelinessLostCallback_();
            };
        
            publisher_options.event_callbacks.incompatible_qos_callback = [this](rclcpp::QOSOfferedIncompatibleQoSInfo& event) {
                std::lock_guard<std::mutex> lockMsg(mtx_);
                incompatibleQoSStructPtr_->TotalCount = event.total_count;
                incompatibleQoSStructPtr_->TotalCountChange = event.total_count_change;
                incompatibleQoSStructPtr_->LastPolicyKind = getPolicyNameFromKind(event.last_policy_kind);
                MATLABIncompatibleQoSCallback_();
            };
        }
         // Create a publisher to the topic which can be matched with one or more compatible ROS
         // publishers.
         // Note that not all publishers on the same topic with the same type will be compatible:
         // they must have compatible Quality of Service policies.
         mPub_ = theNode->create_publisher<MsgType>(topicName_, getQOSSettingsFromRMW(qos_profile), publisher_options);
    }

     /**
     * Method to publish a ROS 2 message.
     * @param msgStruct ROS 2 message structure
     */
     void publish(const StructType *msgStructPtr) {
         struct2msg(*msgPtr_.get(), msgStructPtr);
         mPub_->publish(*msgPtr_);
     }

     // Methods to retrieve the latest status of QoS events and generate warnings.
     void getLatestDeadlineMissedStatus(int32_t* total_count, int32_t* total_count_change){
        *total_count = deadlineStructPtr_->TotalCount;
        *total_count_change = deadlineStructPtr_->TotalCountChange;
    }

    void deadlineMissedWarning(rclcpp::Node::SharedPtr theNode){
        RCLCPP_WARN(theNode->get_logger(), "Offered deadline missed on topic '%s'. The publisher failed to meet the expected deadline for publishing messages as per the deadline QoS policy. Total missed deadlines: %d\n",topicName_.c_str(),deadlineStructPtr_->TotalCount);
    }

    void getLatestLivelinessLostStatus(int32_t* total_count, int32_t* total_count_change){
        *total_count = livelinessStructPtr_->TotalCount;
        *total_count_change = livelinessStructPtr_->TotalCountChange;
    }

    void livelinessLostWarning(rclcpp::Node::SharedPtr theNode){
        RCLCPP_WARN(theNode->get_logger(), "Liveliness lost on topic '%s'. The publisher has not indicated liveliness within the lease duration. Liveliness lost count: %d\n",topicName_.c_str(),livelinessStructPtr_->TotalCount);
    }

    void getLatestIncompatibleQoSStatus(int32_t* total_count, int32_t* total_count_change, char* last_kind_policy){
        *total_count = incompatibleQoSStructPtr_->TotalCount;
        *total_count_change = incompatibleQoSStructPtr_->TotalCountChange;
        const char* pStr = (incompatibleQoSStructPtr_->LastPolicyKind).c_str();
        size_t size = strlen(pStr);
        strncpy(last_kind_policy, pStr, size);
        last_kind_policy[size] = '\0';
    }

    void incompatibleQoSWarning(rclcpp::Node::SharedPtr theNode){
        RCLCPP_WARN(theNode->get_logger(), "New subscription discovered on topic '%s', requesting incompatible QoS. No messages will be sent to it. Last incompatible policy: %s\n",topicName_.c_str(),(incompatibleQoSStructPtr_->LastPolicyKind).c_str());
    }

    static std::string getPolicyNameFromKind(uint16_t policyKind) {
        switch (policyKind) {
            case 1 << 0: return "INVALID";
            case 1 << 1: return "DURABILITY";
            case 1 << 2: return "DEADLINE";
            case 1 << 3: return "LIVELINESS";
            case 1 << 4: return "RELIABILITY";
            case 1 << 5: return "HISTORY";
            case 1 << 6: return "LIFESPAN";
            case 1 << 7: return "DEPTH";
            case 1 << 8: return "LIVELINESS_LEASE_DURATION";
            case 1 << 9: return "AVOID_ROS_NAMESPACE_CONVENTIONS";
            default: return "UNKNOWN_POLICY";
        }
    }
};

#endif
