// MATLABActServerInterface.hpp
// Copyright 2020-2022 The MathWorks, Inc.

#ifndef MATLABActServerInterface_H
#define MATLABActServerInterface_H

#include "MATLABInterfaceCommon.hpp"
class MATLABROS2MsgInterfaceBase;
class MATLABActServerInterface {
  protected:
    MDFactory_T mFactory;

  public:
    MultiLibLoader mMultiLibLoader;
    std::map<std::string,std::shared_ptr<MATLABROS2MsgInterfaceBase>>* mCommonObjMap; 
    explicit MATLABActServerInterface() {
    }

    virtual ~MATLABActServerInterface() {
    }

    virtual intptr_t createActServer(const std::string& /* act_name */,
                                     rclcpp::Node::SharedPtr  /* node */) {
        return 0;
    }
    
    virtual void setCommonObjMap(std::map<std::string,std::shared_ptr<MATLABROS2MsgInterfaceBase>>* ){}

    virtual intptr_t addActServer(rclcpp::Node::SharedPtr theNode,
                                  const std::string& act_name,
                                  SendDataToMATLABAndReturnFunc_T handleGoalCBFunc,
                                  SendDataToMATLABFunc_T handleAcceptedCBFunc,
                                  SendDataToMATLABAndReturnFunc_T handleCancelCBFunc,                                  
                                  rclcpp::QoS & goal_service_qos,
                                  rclcpp::QoS & result_service_qos,
                                  rclcpp::QoS & cancel_service_qos,
                                  rclcpp::QoS & feedback_topic_qos,
                                  rclcpp::QoS & status_topic_qos,
                                  void* sd,
                                  const intptr_t hSvcServer) {
        return 0;
    }

    virtual bool isActive(const std::string & uuid){
        return false;
    }

    virtual bool isExecuting(const std::string & uuid){
        return false;
    }

    virtual bool isCancelled(const std::string & uuid){
        return false;
    }    

#ifndef FOUNDATION_MATLABDATA_API
    virtual void publishFeedback(const std::string & uuid,const matlab::data::StructArray /* arr */){}
#else
    virtual void publishFeedback(const std::string & uuid,const foundation::matlabdata::StructArray /* arr */){}
#endif
    
#ifndef FOUNDATION_MATLABDATA_API
    virtual void setAborted(const matlab::data::StructArray /* arr */, 
                            std::string /* text */,const std::string & uuid){}
#else
    virtual void setAborted(const foundation::matlabdata::StructArray /* arr */,
                            std::string /* text */,const std::string & uuid){}
#endif

#ifndef FOUNDATION_MATLABDATA_API
    virtual void setPreempted(const matlab::data::StructArray /* arr */, 
                              std::string /* text */,const std::string & uuid){}
#else
    virtual void setPreempted(const foundation::matlabdata::StructArray /* arr */,
                              std::string /* text */,const std::string & uuid){}
#endif

#ifndef FOUNDATION_MATLABDATA_API
    virtual void setSucceeded(const matlab::data::StructArray /* arr */, 
                              std::string /* text */,const std::string & uuid){}
#else
    virtual void setSucceeded(const foundation::matlabdata::StructArray /* arr */, 
                              std::string /* text */,const std::string & uuid){}
#endif

    virtual void handleGoalRequest(const std::string & uuid, int32_t goalStatus){};
    virtual void handleCancelRequest(const std::string & uuid, int32_t cancelStatus){};
    virtual void appendAndSendToMATLAB(void* sd,
                                       SendDataToMATLABFunc_T sendDataToMATLABFunc,
                                       MDArray_T arr,
                                       const intptr_t hActServer) {
        auto hndlArr = mFactory.createStructArray({1, 1}, {"handle"});
        hndlArr[0]["handle"] = mFactory.createScalar(CONVERT_INTPTR_T_FOR_MATLAB_ARRAY(hActServer));
        std::vector<MDArray_T> data{arr, hndlArr};
        sendDataToMATLABFunc(sd, data);
    }

    virtual int32_t appendAndSendToMATLABAndReturn(void* sd,
                                       SendDataToMATLABAndReturnFunc_T sendDataToMATLABFunc,
                                       MDArray_T arr,
                                       const intptr_t hActServer,const std::string & goalID) {
        auto hndlArr = mFactory.createStructArray({1, 1}, {"handle"});
        hndlArr[0]["handle"] = mFactory.createScalar(CONVERT_INTPTR_T_FOR_MATLAB_ARRAY(hActServer));
        std::vector<MDArray_T> data{arr, hndlArr};
        return sendDataToMATLABFunc(sd, data,goalID);
    }    

};
#endif // MATLABActServerInterface_H
