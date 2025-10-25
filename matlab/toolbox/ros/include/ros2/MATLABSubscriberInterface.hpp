// MATLABSubscriberInterface.hpp
// Copyright 2017-2024 The MathWorks, Inc.

#ifndef MATLABSUBSCRIBERINTEFACE_H
#define MATLABSUBSCRIBERINTEFACE_H

#ifndef FOUNDATION_MATLABDATA_API
#include "MDArray.hpp"
#include "StructArray.hpp"
#include "TypedArrayRef.hpp"
#include "Struct.hpp"
#include "ArrayFactory.hpp"
#include "StructRef.hpp"
#include "Reference.hpp"
#endif

#ifndef DLL_IMPORT_SYM
#ifdef _MSC_VER
#define DLL_IMPORT_SYM __declspec(dllimport)
#else
#define DLL_IMPORT_SYM __attribute__((visibility("default")))
#endif
#endif

#ifndef FOUNDATION_MATLABDATA_API
typedef matlab::data::Array MDArray_T;
typedef matlab::data::ArrayFactory MDFactory_T;
#else
typedef foundation::matlabdata::Array MDArray_T;
typedef foundation::matlabdata::standalone::ClientArrayFactory MDFactory_T;
#endif
#include "class_loader/multi_library_class_loader.hpp"
using namespace class_loader;
#define MultiLibLoader MultiLibraryClassLoader*

typedef bool (*SendDataToMATLABFunc_T)(void* sd, const std::vector<MDArray_T>& outData);
class MATLABROS2MsgInterfaceBase;
class MATLABSubscriberInterface {
  protected:
    MDFactory_T mFactory;

  public:
    RCLCPP_SMART_PTR_DEFINITIONS(MATLABSubscriberInterface)
    MultiLibLoader mMultiLibLoader;
    std::map<std::string,std::shared_ptr<MATLABROS2MsgInterfaceBase>>* mCommonObjMap;
    explicit MATLABSubscriberInterface() {
    }

    virtual ~MATLABSubscriberInterface() {
    }

    virtual intptr_t createSubscription(const std::string& /* topic_name */,
                                        const rclcpp::QoS& /* qos_profile */,
                                        rclcpp::Node::SharedPtr /* node */,
                                        void* /* subscriber data */,
                                        SendDataToMATLABFunc_T /* sendDataToMATLABFunc */,
                                        SendDataToMATLABFunc_T /* deadline missed send to matlab function */,
                                        SendDataToMATLABFunc_T /* liveliness changed send to matlab function */,
                                        SendDataToMATLABFunc_T /* message lost send to matlab function */,
                                        SendDataToMATLABFunc_T /* incompatible qos send to matlab function */,
                                        const std::string& /* current RMW */,
                                        const bool /* incPubGid */) {
        return 0;
    }
    
    virtual void setCommonObjMap(std::map<std::string,std::shared_ptr<MATLABROS2MsgInterfaceBase>>* ){}
    
    virtual void appendAndSendToMATLAB(void* sd,
                                       SendDataToMATLABFunc_T sendDataToMATLABFunc,
                                       MDArray_T arr,
                                       const bool incPubGid,
                                       const rclcpp::MessageInfo & msgInfo) {
        if (incPubGid) {
            auto gid = mFactory.createArray<uint8_t>({1, RMW_GID_STORAGE_SIZE});
            std::copy(msgInfo.get_rmw_message_info().publisher_gid.data, msgInfo.get_rmw_message_info().publisher_gid.data + RMW_GID_STORAGE_SIZE,
                      gid.begin());
            auto gidArr = mFactory.createStructArray({1, 1}, {"publisher_gid"});
            gidArr[0]["publisher_gid"] = gid;

            std::vector<MDArray_T> data{arr, gidArr};
            sendDataToMATLABFunc(sd, data);
        } else {
            std::vector<MDArray_T> data{arr};
            sendDataToMATLABFunc(sd, data);
        }
    }

    virtual void appendAndSendToMATLABDeadline(void* sd,
                                    SendDataToMATLABFunc_T sendDataToMATLABFunc,
                                    rclcpp::QOSDeadlineRequestedInfo& event,
                                    const bool incPubGid) {

        auto totalCount = mFactory.createStructArray({1, 1}, {"total_count"});
        totalCount[0]["total_count"] = mFactory.createScalar(event.total_count);
        
        auto totalCountChange = mFactory.createStructArray({1, 1}, {"total_count_change"});
        totalCountChange[0]["total_count_change"] = mFactory.createScalar(event.total_count_change);

        std::vector<MDArray_T> data{totalCount, totalCountChange};
        sendDataToMATLABFunc(sd, data);
    }

    virtual void appendAndSendToMATLABLiveliness(void* sd,
                                    SendDataToMATLABFunc_T sendDataToMATLABFunc,
                                    rclcpp::QOSLivelinessChangedInfo& event,
                                    const bool incPubGid) {

        auto aliveCount = mFactory.createStructArray({1, 1}, {"alive_count"});
        aliveCount[0]["alive_count"] = mFactory.createScalar(event.alive_count);

        auto aliveCountChange = mFactory.createStructArray({1, 1}, {"alive_count_change"});
        aliveCountChange[0]["alive_count_change"] = mFactory.createScalar(event.alive_count_change);

        auto notAliveCount = mFactory.createStructArray({1, 1}, {"not_alive_count"});
        notAliveCount[0]["not_alive_count"] = mFactory.createScalar(event.not_alive_count);
        
        auto notAliveCountChange = mFactory.createStructArray({1, 1}, {"not_alive_count_change"});
        notAliveCountChange[0]["not_alive_count_change"] = mFactory.createScalar(event.not_alive_count_change);

        std::vector<MDArray_T> data{aliveCount, aliveCountChange, notAliveCount, notAliveCountChange};
        sendDataToMATLABFunc(sd, data);
    }

    virtual void appendAndSendToMATLABMessageLost(void* sd,
                                    SendDataToMATLABFunc_T sendDataToMATLABFunc,
                                    rclcpp::QOSMessageLostInfo& event,
                                    const bool incPubGid) {

        auto totalCount = mFactory.createStructArray({1, 1}, {"total_count"});
        totalCount[0]["total_count"] = mFactory.createScalar(event.total_count);
        
        auto totalCountChange = mFactory.createStructArray({1, 1}, {"total_count_change"});
        totalCountChange[0]["total_count_change"] = mFactory.createScalar(event.total_count_change);

        std::vector<MDArray_T> data{totalCount, totalCountChange};
        sendDataToMATLABFunc(sd, data);
    }

    virtual void appendAndSendToMATLABSubIncompatibleQoS(void* sd,
                                    SendDataToMATLABFunc_T sendDataToMATLABFunc,
                                    rclcpp::QOSRequestedIncompatibleQoSInfo& event,
                                    const bool incPubGid) {

        auto totalCount = mFactory.createStructArray({1, 1}, {"total_count"});
        totalCount[0]["total_count"] = mFactory.createScalar(event.total_count);
        
        auto totalCountChange = mFactory.createStructArray({1, 1}, {"total_count_change"});
        totalCountChange[0]["total_count_change"] = mFactory.createScalar(event.total_count_change);

        auto lastPolicyKind = mFactory.createStructArray({1, 1}, {"last_policy_kind"});
        lastPolicyKind[0]["last_policy_kind"] = mFactory.createScalar(getPolicyNameFromKind(event.last_policy_kind));

        std::vector<MDArray_T> data{totalCount, totalCountChange, lastPolicyKind};
        sendDataToMATLABFunc(sd, data);
    }

    std::string getPolicyNameFromKind(uint16_t policyKind) {
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

#endif // MATLABSUBSCRIBERINTEFACE_H
