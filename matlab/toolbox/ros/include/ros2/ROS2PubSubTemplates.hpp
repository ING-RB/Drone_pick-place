// ROSPubSubTemplates.hpp
// Copyright 2020-2024 The MathWorks, Inc.

#ifndef ROS2PUBSUBTEMPLATES_H
#define ROS2PUBSUBTEMPLATES_H

#include "MATLABPublisherInterface.hpp"
#include "MATLABSubscriberInterface.hpp"
#include "MATLABROS2MsgInterface.hpp"

/*
 Ros2MessageType = geometry_msgs::msg::Point
 CommonType = geometry_msgs_msg_Point_common
 */
template<class Ros2MessageType, class CommonType>
class ROS2PublisherImpl : public MATLABPublisherInterface {
    std::shared_ptr<rclcpp::Publisher<Ros2MessageType>> mPub;
    CommonType mCommonObj;
  public:
    RCLCPP_SMART_PTR_DEFINITIONS(ROS2PublisherImpl)
    ROS2PublisherImpl()
        : MATLABPublisherInterface() {
    }
    virtual ~ROS2PublisherImpl() {
    }
    virtual intptr_t createPublisher(const std::string& topic_name,
                                     const rclcpp::QoS& qos_profile,
                                     rclcpp::Node::SharedPtr theNode,
                                     void* pd,
                                     SendDataToMATLABFunc_T sendDataToMATLABDeadlineFunc,
                                     SendDataToMATLABFunc_T sendDataToMATLABLivelinessFunc,
                                     SendDataToMATLABFunc_T sendDataToMATLABIncompatibleQoSFunc,
                                     const std::string& currentRMW) {
        // Create a subscription to the topic which can be matched with one or more compatible ROS
        // publishers.
        // Note that not all publishers on the same topic with the same type will be compatible:
        // they must have compatible Quality of Service policies.
        rclcpp::PublisherOptions publisher_options;

        // Set of supported RMWs for QoS event callbacks
        const std::set<std::string> supportedRMWs = {
            "rmw_fastrtps_cpp",
            "rmw_fastrtps_dynamic_cpp",
            "rmw_cyclonedds_cpp",
            "rmw_connextdds"
        };

        // Check if the current RMW is supported for QoS event callbacks
        if (supportedRMWs.find(currentRMW) != supportedRMWs.end()) {
            publisher_options.event_callbacks.deadline_callback = 
            [this, pd, sendDataToMATLABDeadlineFunc](rclcpp::QOSDeadlineOfferedInfo& event) {
                appendAndSendToMATLABDeadline(pd,sendDataToMATLABDeadlineFunc, event);
            };

            publisher_options.event_callbacks.liveliness_callback = 
            [this, pd, sendDataToMATLABLivelinessFunc](rclcpp::QOSLivelinessLostInfo& event) {
                appendAndSendToMATLABLiveliness(pd, sendDataToMATLABLivelinessFunc, event);
            };

            publisher_options.event_callbacks.incompatible_qos_callback = 
            [this, pd, sendDataToMATLABIncompatibleQoSFunc](rclcpp::QOSOfferedIncompatibleQoSInfo& event) {
                appendAndSendToMATLABIncompatibleQoS(pd, sendDataToMATLABIncompatibleQoSFunc, event);
            };
        }

        mPub = theNode->create_publisher<Ros2MessageType>(topic_name, qos_profile, publisher_options);
        return reinterpret_cast<intptr_t>(mPub.get());
    }
	virtual void setCommonObjMap(std::map<std::string,std::shared_ptr<MATLABROS2MsgInterfaceBase>>* commonObjMap){
		mCommonObjMap = commonObjMap;
		mCommonObj.mCommonObjMap = mCommonObjMap;
	}
    virtual bool publish(const matlab::data::StructArray& arr) {
        auto msg = std::make_unique<Ros2MessageType>();
        mCommonObj.copy_from_struct(msg.get(), arr[0], mMultiLibLoader);
        mPub->publish(std::move(msg));
        return true;
    }
    virtual const rmw_gid_t& get_gid() const {
        return mPub->get_gid();
    }
};

/*
 RosMessageType = geometry_msgs::msg::Point
 CommonType = geometry_msgs_msg_Point_common
 */
template<class RosMessageType, class CommonType>
class ROS2SubscriberImpl : public MATLABSubscriberInterface {
    std::shared_ptr<rclcpp::Subscription<RosMessageType>> mSub;
    CommonType mCommonObj;
  public:
    ROS2SubscriberImpl()
        : MATLABSubscriberInterface() {
    }
    virtual ~ROS2SubscriberImpl() {
    }
    virtual intptr_t createSubscription(const std::string& topic_name,
                                        const rclcpp::QoS& qos_profile,
                                        rclcpp::Node::SharedPtr theNode,
                                        void* sd,
                                        SendDataToMATLABFunc_T sendDataToMATLABFunc,
                                        SendDataToMATLABFunc_T sendDataToMATLABDeadlineFunc,
                                        SendDataToMATLABFunc_T sendDataToMATLABLivelinessFunc,
                                        SendDataToMATLABFunc_T sendDataToMATLABMessageLostFunc,
                                        SendDataToMATLABFunc_T sendDataToMATLABIncompatibleQoSFunc,
                                        const std::string& currentRMW,
                                        const bool incPubGid) {
        // Create a callback function for when messages are received.
        // Variations of this function also exist using, for example UniquePtr for zero-copy
        // transport.
        auto callback = [this, sd, sendDataToMATLABFunc, incPubGid](
                            const std::shared_ptr<const RosMessageType> msg,
                            const rclcpp::MessageInfo & msgInfo) -> void {
        auto outArray = mCommonObj.get_arr(mFactory, msg.get(), mMultiLibLoader);
            appendAndSendToMATLAB(sd, sendDataToMATLABFunc, outArray, incPubGid, msgInfo);
        };

        rclcpp::SubscriptionOptions subscription_options;

        // Set of supported RMWs for QoS event callbacks
        const std::set<std::string> supportedRMWs = {
            "rmw_fastrtps_cpp",
            "rmw_fastrtps_dynamic_cpp",
            "rmw_cyclonedds_cpp",
            "rmw_connextdds"
        };

        // Check if the current RMW is supported for QoS event callbacks
        if (supportedRMWs.find(currentRMW) != supportedRMWs.end()) {
            subscription_options.event_callbacks.deadline_callback = 
            [this, sd, sendDataToMATLABDeadlineFunc, incPubGid](rclcpp::QOSDeadlineRequestedInfo& event) {
                appendAndSendToMATLABDeadline(sd, sendDataToMATLABDeadlineFunc, event, incPubGid);
            };

            subscription_options.event_callbacks.liveliness_callback = 
            [this, sd, sendDataToMATLABLivelinessFunc, incPubGid](rclcpp::QOSLivelinessChangedInfo& event) {
                appendAndSendToMATLABLiveliness(sd, sendDataToMATLABLivelinessFunc, event, incPubGid);
            };

            subscription_options.event_callbacks.message_lost_callback = 
            [this, sd, sendDataToMATLABMessageLostFunc, incPubGid](rclcpp::QOSMessageLostInfo& event) {
                appendAndSendToMATLABMessageLost(sd, sendDataToMATLABMessageLostFunc, event, incPubGid);
            };
            
            subscription_options.event_callbacks.incompatible_qos_callback = 
            [this, sd, sendDataToMATLABIncompatibleQoSFunc, incPubGid](rclcpp::QOSRequestedIncompatibleQoSInfo& event) {
                appendAndSendToMATLABSubIncompatibleQoS(sd, sendDataToMATLABIncompatibleQoSFunc, event, incPubGid);
            };
        }

        // Create a subscription to the topic which can be matched with one or more compatible ROS
        // publishers.
        // Note that not all publishers on the same topic with the same type will be compatible:
        // they must have compatible Quality of Service policies.
        // Note: ignore_local_publications is not supported in FastRTPS
        mSub = theNode->create_subscription<RosMessageType>(topic_name, qos_profile, callback, subscription_options);
        return true;
    }
	virtual void setCommonObjMap(std::map<std::string,std::shared_ptr<MATLABROS2MsgInterfaceBase>>* commonObjMap){
		mCommonObjMap = commonObjMap;
		mCommonObj.mCommonObjMap = mCommonObjMap;
	}
};
#endif // ROS2PUBSUBTEMPLATES_H
