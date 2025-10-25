// MATLABActClientInterface.hpp
// Copyright 2022 The MathWorks, Inc.

#ifndef MATLABACTCLIENTINTERFACE_H
#define MATLABACTCLIENTINTERFACE_H

#include "MATLABInterfaceCommon.hpp"
class MATLABROS2MsgInterfaceBase;
class MATLABActClientInterface {
  protected:
    MDFactory_T mFactory;

  public:
    std::map<std::string,std::shared_ptr<MATLABROS2MsgInterfaceBase>>* mCommonObjMap; 
    MultiLibLoader mMultiLibLoader;
    explicit MATLABActClientInterface() {
    }

    virtual ~MATLABActClientInterface() {
    }
    virtual void cleanup() {
        
    }

    virtual intptr_t createActClient(const std::string& /* act_name */,
                                     rclcpp::Node::SharedPtr /* node */,
                                     rclcpp::QoS & goal_service_qos,
                                     rclcpp::QoS & result_service_qos,
                                     rclcpp::QoS & cancel_service_qos,
                                     rclcpp::QoS & feedback_topic_qos,
                                     rclcpp::QoS & status_topic_qos) {
        return 0;
    }
    
    virtual bool waitForActServer(intptr_t /*timeout*/){
        return false;
    }

    virtual void setCommonObjMap(std::map<std::string,std::shared_ptr<MATLABROS2MsgInterfaceBase>>* ){}

#ifndef FOUNDATION_MATLABDATA_API
    virtual int64_t sendGoaltoActserver(const matlab::data::StructArray /* arr */,
                                      void* /* sd */,
                                      SendDataToMATLABFunc_T /* onGoalActiveCBFunc */,
                                      SendDataToMATLABFunc_T /* onFeedbackReceivedCBFunc */,
                                      SendDataToMATLABFunc_T /* onResultReceivedCBFunc */,
                                      const intptr_t /* hActClient */,
                                      const int64_t /* goalIndex */)
#else
    virtual int64_t sendGoaltoActserver(const foundation::matlabdata::StructArray /* arr */,
                                      void* /* sd */,
                                      SendDataToMATLABFunc_T /* onGoalActiveCBFunc */,
                                      SendDataToMATLABFunc_T /* onFeedbackReceivedCBFunc */,
                                      SendDataToMATLABFunc_T /* onResultReceivedCBFunc */,
                                      const intptr_t /* hActClient */,
                                      const int64_t /* goalIndex */)
#endif
    {
        return -1;
    }

    virtual bool cancelGoal(int64_t goalIndex,SendDataToMATLABFunc_T onCancelCBFunc){
        return false;
    }
    
    virtual bool cancelAllGoal(SendDataToMATLABFunc_T onCancelCBFunc){
        return false;
    }
    
    virtual bool cancelGoalsBeforeTime(int32_t sec,uint32_t nanosec,SendDataToMATLABFunc_T onCancelBeforeCBFunc){    
        return false;
    }

    virtual bool isServerConnected(){
        return false;
    }
    
    virtual int32_t getState(int64_t goalIndex){
        return -1;
    }
    
    virtual MDArray_T getResult(int64_t goalIndex){
        MDArray_T res;
        return res;
    }
    
    virtual void appendAndSendToMATLAB(void* sd,
                                       SendDataToMATLABFunc_T sendDataToMATLABFunc,
                                       MDArray_T arr,
                                       const intptr_t hActServer) {
        auto hndlArr = mFactory.createStructArray({1, 1}, {"handle"});
        hndlArr[0]["handle"] = mFactory.createScalar(CONVERT_INTPTR_T_FOR_MATLAB_ARRAY(hActServer));
        std::vector<MDArray_T> data{arr, hndlArr};
        sendDataToMATLABFunc(sd, data);
    }
    
    virtual void appendAndSendToMATLAB(void* sd,
                                       SendDataToMATLABFunc_T sendDataToMATLABFunc,
                                       MDArray_T arr,
                                       const intptr_t hActServer,
                                       int32_t goal_state) {
        auto hndlArr = mFactory.createStructArray({1, 1}, {"handle"});
        hndlArr[0]["handle"] = mFactory.createScalar(CONVERT_INTPTR_T_FOR_MATLAB_ARRAY(hActServer));
        
        auto goalStateArr = mFactory.createStructArray({1, 1}, {"goal_state"});
        goalStateArr[0]["goal_state"] = mFactory.createScalar(goal_state);
        std::vector<MDArray_T> data{arr, hndlArr, goalStateArr};
        sendDataToMATLABFunc(sd, data);
    }    
};
#endif // MATLABACTCLIENTINTERFACE_H
