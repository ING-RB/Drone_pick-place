// MATLABPublisherInterface.hpp
// Copyright 2017-2024 The MathWorks, Inc.

#ifndef MATLABPUBLISHERINTEFACE_H
#define MATLABPUBLISHERINTEFACE_H

#ifndef FOUNDATION_MATLABDATA_API
#include "MDArray.hpp"
#include "StructArray.hpp"
#include "TypedArrayRef.hpp"
#include "Struct.hpp"
#include "ArrayFactory.hpp"
#include "StructRef.hpp"
#include "Reference.hpp"
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
class MATLABPublisherInterface {
    rmw_gid_t mNullGID;

  protected:
    MDFactory_T mFactory;
  public:
    RCLCPP_SMART_PTR_DEFINITIONS(MATLABPublisherInterface)
    MultiLibLoader mMultiLibLoader;
    std::map<std::string,std::shared_ptr<MATLABROS2MsgInterfaceBase>>* mCommonObjMap;
    explicit MATLABPublisherInterface()
        : mNullGID() {
    }

    virtual ~MATLABPublisherInterface() {
    }

    virtual intptr_t createPublisher(const std::string& /* topic_name */,
                                     const rclcpp::QoS& /* qos_profile */,
                                     rclcpp::Node::SharedPtr /* node */,
                                     void* /* publisher data */,
                                     SendDataToMATLABFunc_T /* deadline missed send to matlab function */,
                                     SendDataToMATLABFunc_T /* liveliness lost send to matlab function */,
                                     SendDataToMATLABFunc_T /* incompatible qos send to matlab function */,
                                     const std::string& /* currentRMW */) {
        return 0;
    }
    
    virtual void setCommonObjMap(std::map<std::string,std::shared_ptr<MATLABROS2MsgInterfaceBase>>* ){}
    
#ifndef FOUNDATION_MATLABDATA_API
    virtual bool publish(const matlab::data::StructArray& /* arr */)
#else
    virtual bool publish(const foundation::matlabdata::StructArray& /* arr */)
#endif
    {
        return false;
    }

    virtual const rmw_gid_t& get_gid() const {
        return mNullGID;
    }

    virtual void appendAndSendToMATLABDeadline(void* pd,
                                               SendDataToMATLABFunc_T sendDataToMATLABFunc,
                                               rclcpp::QOSDeadlineOfferedInfo& event) {

        auto totalCount = mFactory.createStructArray({1, 1}, {"total_count"});
        totalCount[0]["total_count"] = mFactory.createScalar(event.total_count);
        
        auto totalCountChange = mFactory.createStructArray({1, 1}, {"total_count_change"});
        totalCountChange[0]["total_count_change"] = mFactory.createScalar(event.total_count_change);

        std::vector<MDArray_T> data{totalCount, totalCountChange};
        sendDataToMATLABFunc(pd, data);
    }

    virtual void appendAndSendToMATLABLiveliness(void* pd,
                                                 SendDataToMATLABFunc_T sendDataToMATLABFunc,
                                          
                                                 rclcpp::QOSLivelinessLostInfo& event) {

        auto totalCount = mFactory.createStructArray({1, 1}, {"total_count"});
        totalCount[0]["total_count"] = mFactory.createScalar(event.total_count);
        
        auto totalCountChange = mFactory.createStructArray({1, 1}, {"total_count_change"});
        totalCountChange[0]["total_count_change"] = mFactory.createScalar(event.total_count_change);

        std::vector<MDArray_T> data{totalCount, totalCountChange};
        sendDataToMATLABFunc(pd, data);
    }

    virtual void appendAndSendToMATLABIncompatibleQoS(void* pd,
                                                      SendDataToMATLABFunc_T sendDataToMATLABFunc,
                                                      rclcpp::QOSOfferedIncompatibleQoSInfo& event) {

        auto totalCount = mFactory.createStructArray({1, 1}, {"total_count"});
        totalCount[0]["total_count"] = mFactory.createScalar(event.total_count);
        
        auto totalCountChange = mFactory.createStructArray({1, 1}, {"total_count_change"});
        totalCountChange[0]["total_count_change"] = mFactory.createScalar(event.total_count_change);

        auto lastPolicyKind = mFactory.createStructArray({1, 1}, {"last_policy_kind"});
        lastPolicyKind[0]["last_policy_kind"] = mFactory.createScalar(getPolicyNameFromKind(event.last_policy_kind));

        std::vector<MDArray_T> data{totalCount, totalCountChange, lastPolicyKind};
        sendDataToMATLABFunc(pd, data);
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


#endif // MATLABPUBLISHERINTEFACE_H
