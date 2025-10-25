// Copyright 2021-2024 The MathWorks, Inc.
#ifndef _MLROS2_SUB_H_
#define _MLROS2_SUB_H_

#include <iostream>
#include <memory>
#include <string>
#include <mutex>
#include "rclcpp/rclcpp.hpp"
#include "mlros2_qos.h"
#include "ros2_structmsg_conversion.h" // For msg2struct()

#define MATLABROS2Subscriber_lock(obj) obj->lock()
#define MATLABROS2Subscriber_unlock(obj) obj->unlock()
#define MATLABROS2Subscriber_createSubscriber(obj, theNode, mlTopic, mlTopicSize, qos_profile) \
    obj->createSubscriber(theNode, mlTopic, mlTopicSize, qos_profile)
#define MATLABROS2Subscriber_getLatestDeadlineMissedStatus(obj, totalCount, totalCountChange) \
    obj->getLatestDeadlineMissedStatus(totalCount, totalCountChange)
#define MATLABROS2Subscriber_getLatestLivelinessChangedStatus(obj, aliveCount, aliveCountChange, notAliveCount, notAliveCountChange) \
    obj->getLatestLivelinessChangedStatus(aliveCount, aliveCountChange, notAliveCount, notAliveCountChange)
#define MATLABROS2Subscriber_getLatestMessageLostStatus(obj, totalCount, totalCountChange) \
    obj->getLatestMessageLostStatus(totalCount, totalCountChange)
#define MATLABROS2Subscriber_getLatestIncompatibleQoSStatus(obj, totalCount, totalCountChange, lastKindPolicy) \
    obj->getLatestIncompatibleQoSStatus(totalCount, totalCountChange, lastKindPolicy)
#define MATLABROS2Subscriber_deadlineMissedWarning(obj, nodeHandle) obj->deadlineMissedWarning(nodeHandle)
#define MATLABROS2Subscriber_livelinessChangedWarning(obj, nodeHandle) obj->livelinessChangedWarning(nodeHandle)
#define MATLABROS2Subscriber_messageLostWarning(obj, nodeHandle) obj->messageLostWarning(nodeHandle)
#define MATLABROS2Subscriber_incompatibleQoSWarning(obj, nodeHandle) obj->incompatibleQoSWarning(nodeHandle)

// Define the QoS Event Deadline structure
typedef struct QoSEventDeadlineStructType {
    int32_t TotalCount;
    int32_t TotalCountChange;
} QoSEventDeadlineStructType_T;

// Define the QoS Event Liveliness structure
typedef struct QoSEventLivelinessStructType {
    int32_t AliveCount;
    int32_t AliveCountChange;
    int32_t NotAliveCount;
    int32_t NotAliveCountChange;
} QoSEventLivelinessStructType_T;

// Define the QoS Event Incompatible QoS structure
typedef struct QoSEventIncompatibleStructType {
    int32_t TotalCount;
    int32_t TotalCountChange;
    std::string LastPolicyKind;
} QoSEventIncompatibleStructType_T;

// Define the QoS Event Message Lost structure
typedef struct QoSEventMessageLostStructType {
    size_t TotalCount;
    size_t TotalCountChange;
} QoSEventMessageLostStructType_T;

template <class MsgType, class StructType>
class MATLABROS2Subscriber {
    std::function<void(void)> MATLABCallback_;
    std::function<void(void)> MATLABRequestedDeadlineMissedCallback_;
    std::function<void(void)> MATLABLivelinessChangedCallback_;
    std::function<void(void)> MATLABMessageLostCallback_;
    std::function<void(void)> MATLABIncompatibleQoSCallback_;
    std::string topicName_;
    StructType* structPtr_;
    QoSEventDeadlineStructType_T* deadlineStructPtr_ = new QoSEventDeadlineStructType_T();
    QoSEventLivelinessStructType_T* livelinessStructPtr_ = new QoSEventLivelinessStructType_T();
    QoSEventMessageLostStructType_T* messageLostStructPtr_ = new QoSEventMessageLostStructType_T();
    QoSEventIncompatibleStructType_T* incompatibleQoSStructPtr_ = new QoSEventIncompatibleStructType_T();
    std::shared_ptr<rclcpp::Subscription<MsgType>> mSub_;
    std::shared_ptr<const MsgType> lastMsgPtr_;
    std::mutex mtx_;

  public:
    RCLCPP_SMART_PTR_DEFINITIONS(MATLABROS2Subscriber)
    MATLABROS2Subscriber(StructType* structPtr, std::function<void(void)> callback, 
        std::function<void(void)> deadline_callback, std::function<void(void)> liveliness_callback, 
        std::function<void(void)> message_lost_callback, std::function<void(void)> incompatible_qos_callback)
        : MATLABCallback_{callback}
        , MATLABRequestedDeadlineMissedCallback_{deadline_callback}
        , MATLABLivelinessChangedCallback_{liveliness_callback}
        , MATLABMessageLostCallback_{message_lost_callback}
        , MATLABIncompatibleQoSCallback_{incompatible_qos_callback}
        , structPtr_{structPtr} {
    }

    /**
     * Method to create a ROS 2 Subscriber.
     * @param theNode Shared pointer to the ROS 2 Node Handle
     * @param mlTopic Topic on which a message is to be published.
     * @param mlTopicSize size to handle string inputs.
     * @param qos_profile qos settings.
     */
    void createSubscriber(rclcpp::Node::SharedPtr theNode,
                          const char* mlTopic,
                          size_t mlTopicSize,
                          const rmw_qos_profile_t& qos_profile = rmw_qos_profile_default) {
        topicName_ = std::string(mlTopic, mlTopicSize);
        auto subscriberCallback = [this](const std::shared_ptr<const MsgType> msgPtr) {
            std::lock_guard<std::mutex> lockMsg(mtx_);
            lastMsgPtr_ = msgPtr; // copy the shared_ptr
            msg2struct(structPtr_, *lastMsgPtr_.get());
            MATLABCallback_(); // Call MATLAB callback
        };

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

        rclcpp::SubscriptionOptions subscription_options;
        
        if(enable_qos_events){
            subscription_options.event_callbacks.deadline_callback = [this](const rclcpp::QOSDeadlineRequestedInfo& event) {
                std::lock_guard<std::mutex> lockMsg(mtx_);
                deadlineStructPtr_->TotalCount = event.total_count;
                deadlineStructPtr_->TotalCountChange = event.total_count_change;
                MATLABRequestedDeadlineMissedCallback_();
            };
    
            subscription_options.event_callbacks.liveliness_callback = [this](const rclcpp::QOSLivelinessChangedInfo& event) {
                std::lock_guard<std::mutex> lockMsg(mtx_);
                livelinessStructPtr_->AliveCount = event.alive_count;
                livelinessStructPtr_->AliveCountChange = event.alive_count_change;
                livelinessStructPtr_->NotAliveCount = event.not_alive_count;
                livelinessStructPtr_->NotAliveCountChange = event.not_alive_count_change;
                MATLABLivelinessChangedCallback_();
            };
    
            subscription_options.event_callbacks.message_lost_callback = [this](const rclcpp::QOSMessageLostInfo& event) {
                std::lock_guard<std::mutex> lockMsg(mtx_);
                messageLostStructPtr_->TotalCount = event.total_count;
                messageLostStructPtr_->TotalCountChange = event.total_count_change;
                MATLABMessageLostCallback_();
            };
            
            subscription_options.event_callbacks.incompatible_qos_callback = [this](const rclcpp::QOSRequestedIncompatibleQoSInfo& event) {
                std::lock_guard<std::mutex> lockMsg(mtx_);
                incompatibleQoSStructPtr_->TotalCount = event.total_count;
                incompatibleQoSStructPtr_->TotalCountChange = event.total_count_change;
                incompatibleQoSStructPtr_->LastPolicyKind = getPolicyNameFromKind(event.last_policy_kind);
                MATLABIncompatibleQoSCallback_();
            };
        }

        // Subscribe to given topic and set callback
        mSub_ = theNode->create_subscription<MsgType>(topicName_, getQOSSettingsFromRMW(qos_profile),
                                                      subscriberCallback, subscription_options);
    }

    // Methods to retrieve the latest status of QoS events and generate warnings.
    void getLatestDeadlineMissedStatus(int32_t* total_count, int32_t* total_count_change){
        *total_count = deadlineStructPtr_->TotalCount;
        *total_count_change = deadlineStructPtr_->TotalCountChange;
    }

    void deadlineMissedWarning(rclcpp::Node::SharedPtr theNode){
        RCLCPP_WARN(theNode->get_logger(), "Requested deadline missed on topic '%s'. The subscription did not receive any messages within the expected duration set by the deadline QoS policy. Total missed deadlines: %d\n",topicName_.c_str(),deadlineStructPtr_->TotalCount);
    }

    void getLatestLivelinessChangedStatus(int32_t* alive_count, int32_t* alive_count_change, int32_t* not_alive_count, int32_t* not_alive_count_change){
        *alive_count = livelinessStructPtr_->AliveCount;
        *alive_count_change = livelinessStructPtr_->AliveCountChange;
        *not_alive_count = livelinessStructPtr_->NotAliveCount;
        *not_alive_count_change = livelinessStructPtr_->NotAliveCountChange;
    }

    void livelinessChangedWarning(rclcpp::Node::SharedPtr theNode){
        RCLCPP_WARN(theNode->get_logger(),"Liveliness changed on topic '%s'. A change in the liveliness of one or more publishers on the topic has been detected. Alive count: %d, Not alive count: %d\n",topicName_.c_str(),livelinessStructPtr_->AliveCount,livelinessStructPtr_->AliveCountChange);
    }

    void getLatestMessageLostStatus(int32_t* total_count, int32_t* total_count_change){
        *total_count = messageLostStructPtr_->TotalCount;
        *total_count_change = messageLostStructPtr_->TotalCountChange;
    }

    void messageLostWarning(rclcpp::Node::SharedPtr theNode){
        RCLCPP_WARN(theNode->get_logger(), "Messages lost on topic '%s'. Total lost messages: %d\n",topicName_.c_str(),messageLostStructPtr_->TotalCount);
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
        RCLCPP_WARN(theNode->get_logger(), "New publisher discovered on topic '%s', offering incompatible QoS. No messages will be received from it. Last incompatible policy: %s",topicName_.c_str(),(incompatibleQoSStructPtr_->LastPolicyKind).c_str());
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

    void lock() {
        mtx_.lock();
    }

    void unlock() {
        mtx_.unlock();
    }
};

/**
 * Function to get status text.
 */
extern void getStatusText(bool status, char* mlStatusText);
#endif
