// ROSActionTemplates.hpp
// Copyright 2020-2023 The MathWorks, Inc.

#ifndef ROS2ACTIONTEMPLATES_H
#define ROS2ACTIONTEMPLATES_H

#include "rclcpp/rclcpp.hpp"
#include "rclcpp_action/rclcpp_action.hpp"

#include "MATLABROS2MsgInterface.hpp"
#include "MATLABActClientInterface.hpp"
#include "MATLABActServerInterface.hpp"


template<class RosActType, class ActGoalType, class RosActFeedbackTypePtr, class RosActResultTypePtr, class GoalCommonType, class FeedbackCommonType, class ResultCommonType>
class  ROS2ActClientImpl: public MATLABActClientInterface {
    using UUIDType = std::array<uint8_t, 16>;
    typename rclcpp_action::Client<RosActType>::SharedPtr mClient;

    bool mIsConnectedToActServer;
    void* mSd;

    intptr_t mHactClient;

    SendDataToMATLABFunc_T mOnGoalActiveCBFunc;
    SendDataToMATLABFunc_T mOnFeedbackReceivedCBFunc;
    SendDataToMATLABFunc_T mOnResultReceivedCBFunc;
    SendDataToMATLABFunc_T mOnResultCBFunc;
    SendDataToMATLABFunc_T mOnCancelCBFunc;
    SendDataToMATLABFunc_T mOnCancelAllCBFunc;
    SendDataToMATLABFunc_T mOnCancelBeforeCBFunc;

    GoalCommonType mGoalCommonObj; 
    FeedbackCommonType mFeedbackCommonObj; 
    ResultCommonType mResultCommonObj;

    // Destructor mutex to indicate the action client deletion.
    std::mutex mDestMutex;
    // If mInUse = true means , an action callback is being executed.
    // In Future , we need to verify if this is really needed.
    bool mInUse;
    std::atomic<bool> mInDest;
    std::condition_variable mDestCond;

  public:
  class ActionCallBack {
    public:
    using GoalHandle =  rclcpp_action::ClientGoalHandle<RosActType>;
    ROS2ActClientImpl * mParent;
    ActionCallBack(ROS2ActClientImpl * parent):mParent(parent){}

    int goalIndex ;
    std::shared_ptr<GoalHandle> mGoalHandle;
    UUIDType mUUID;
    std::atomic<bool> mGoalAccepted={false};
    std::atomic<bool> mIsCompleted = {false};

    void onCancellCallBack(std::shared_ptr<action_msgs::srv::CancelGoal::Response> response){
        // If action client object is being deleted,
        // No need to execute further. Just return. mInDest = true indicates 
        // ActionClient Object being destroyed.
        if(mParent->mInDest)
           return;
        // If the callback is being executed , hold any requests to delete the 
        // Action client object and notify it after the callback is completed.
        std::lock_guard<std::mutex> lck(mParent->mDestMutex);
        mParent->mInUse = true;

        if(!mGoalAccepted){
            return ;
        }
        if ( response->return_code == response->ERROR_NONE) {
            mIsCompleted = true;
        }
        
        auto outArray1 = mParent->mFactory.createStructArray({1, 1}, {"cancelResponse","goalIndex"});
        outArray1[0]["goalIndex"]= mParent->mFactory.createScalar(goalIndex);
        auto ros2MsgFactory =
            mParent->mMultiLibLoader->template createInstance<ROS2MsgElementInterfaceFactory>("ros2_action_msgs_CancelGoal_service"); 
        
        if(response && response.get() && ros2MsgFactory && ros2MsgFactory.get()){
            auto outArray = ros2MsgFactory->generateMLMessage(eResponse,response.get(),mParent->mMultiLibLoader,mParent->mCommonObjMap);
            outArray1[0]["cancelResponse"]= outArray;
            if (mParent->mSd != NULL) {
                mParent->appendAndSendToMATLAB(mParent->mSd, mParent->mOnCancelCBFunc, outArray1, mParent->mHactClient);
            }
        }
        // Notify the destructor that the callback is completed.
        mParent->mInUse = false;
        mParent->mDestCond.notify_one();
    }

    void onGoalResponseCalback(std::shared_ptr<GoalHandle> goalHandle)
    {
        // If action client object is being deleted,
        // No need to execute further. Just return. mInDest = true indicates 
        // ActionClient Object being destroyed.
        if(mParent->mInDest)
           return;

        // If the callback is being executed , hold any requests to delete the 
        // Action client object and notify it after the callback is completed.
        std::lock_guard<std::mutex> lck(mParent->mDestMutex);
        mParent->mInUse = true;
        // goalUUID is a character vector
        // goalUUIDArray is a std::array of size 16x1 of type uint8
        auto outArray = mParent->mFactory.createStructArray({1, 1}, {"goalAccepted","goalUUID","goalUUIDArray", "goalIndex"});
        if(!goalHandle) {
            outArray[0]["goalAccepted"] = mParent->mFactory.createScalar(false);
            outArray[0]["goalUUID"]= mParent->mFactory.createCharArray("");  
            mGoalAccepted=false;
            mIsCompleted = true;
        }else{
            outArray[0]["goalAccepted"] =mParent->mFactory.createScalar(true);
            mGoalHandle = goalHandle;
            mUUID = goalHandle->get_goal_id();
            mGoalAccepted=true;
            auto goalID = rclcpp_action::to_string(goalHandle->get_goal_id());
            outArray[0]["goalUUID"]= mParent->mFactory.createCharArray(goalID);
            auto uuidArray = mParent->mFactory.template createArray<uint8_t>({16,1});
            std::copy(goalHandle->get_goal_id().begin(), goalHandle->get_goal_id().end(), uuidArray.begin());
            outArray[0]["goalUUIDArray"] = uuidArray;
        }
        outArray[0]["goalIndex"]= mParent->mFactory.createScalar(goalIndex);
        if (mParent->mSd != NULL) {
            mParent->appendAndSendToMATLAB(mParent->mSd, mParent->mOnGoalActiveCBFunc, outArray, mParent->mHactClient);
        }
        // Notify the destructor that the callback is completed.
        mParent->mInUse = false;
        mParent->mDestCond.notify_one();        
    }

    void onFeedbackReceivedCallback(
        std::shared_ptr<GoalHandle> goalHandlePtr,
        const std::shared_ptr<const typename RosActType::Feedback> feedback) {
        // If action client object is being deleted,
        // No need to execute further. Just return. mInDest = true indicates 
        // ActionClient Object being destroyed.
        if(mParent->mInDest)
           return;
        // If the callback is being executed , hold any requests to delete the 
        // Action client object and notify it after the callback is completed.
        std::lock_guard<std::mutex> lck(mParent->mDestMutex);
        mParent->mInUse = true;        
        if(!mGoalAccepted){
            return ;
        }
        auto outArray1 = mParent->mFactory.createStructArray({1, 1}, {"goalUUID","goalUUIDArray","goalIndex","Feedback"});            
        auto outArray = mParent->mFeedbackCommonObj.get_arr(mParent->mFactory, feedback.get(), mParent->mMultiLibLoader);
        auto goalID = rclcpp_action::to_string(goalHandlePtr->get_goal_id());
        outArray1[0]["goalUUID"]= mParent->mFactory.createCharArray(goalID);
        auto uuidArray = mParent->mFactory.template createArray<uint8_t>({16,1});
        std::copy(goalHandlePtr->get_goal_id().begin(), goalHandlePtr->get_goal_id().end(), uuidArray.begin());
        outArray1[0]["goalUUIDArray"] = uuidArray;
        outArray1[0]["goalIndex"]= mParent->mFactory.createScalar(goalIndex);
        outArray1[0]["Feedback"]= outArray;
        if (mParent->mSd != NULL) {
            mParent->appendAndSendToMATLAB(mParent->mSd, mParent->mOnFeedbackReceivedCBFunc, outArray1, mParent->mHactClient);
        }
        // Notify the destructor that the callback is completed.
        mParent->mInUse = false;
        mParent->mDestCond.notify_one();        
    }

    void onResultReceivedCallback(const typename GoalHandle::WrappedResult & result) {
        // If action client object is being deleted,
        // No need to execute further. Just return.
        if(mParent->mInDest)
           return;
        // If the callback is being executed , hold any requests to delete the 
        // Action client object and notify it after the callback is completed.
        std::lock_guard<std::mutex> lck(mParent->mDestMutex);
        mParent->mInUse = true;
 
        
        if(!mGoalAccepted){
            return ;
        }
        auto outArray1 = mParent->mFactory.createStructArray({1, 1}, {"goalUUID","goalUUIDArray","goalIndex","resultStatus","Result"});
        auto outArray = mParent->mResultCommonObj.get_arr(mParent->mFactory, result.result.get(), mParent->mMultiLibLoader);       
        
        mIsCompleted = true;
        outArray1[0]["goalUUID"]= mParent->mFactory.createCharArray(rclcpp_action::to_string(mGoalHandle->get_goal_id()));
        auto uuidArray = mParent->mFactory.template createArray<uint8_t>({16,1});
        std::copy(mGoalHandle->get_goal_id().begin(), mGoalHandle->get_goal_id().end(), uuidArray.begin());
        outArray1[0]["goalUUIDArray"] = uuidArray;
        outArray1[0]["goalIndex"]= mParent->mFactory.createScalar(goalIndex);
        outArray1[0]["resultStatus"]= mParent->mFactory.createScalar(static_cast<int8_t>(result.code));
        outArray1[0]["Result"]= outArray;
        if (mParent->mSd != NULL) {
            mParent->appendAndSendToMATLAB(mParent->mSd, mParent->mOnResultReceivedCBFunc, outArray1, mParent->mHactClient, static_cast<int32_t>(result.code));
        }
        // Notify the destructor that the callback is completed.
        mParent->mInUse = false;
        mParent->mDestCond.notify_one();
    }
};

    ROS2ActClientImpl()
        : MATLABActClientInterface()
        , mIsConnectedToActServer(false)
        , mDestMutex()
        , mInUse(false)
        , mInDest(false)
        , mDestCond(){
    }
    virtual void setCommonObjMap(std::map<std::string,std::shared_ptr<MATLABROS2MsgInterfaceBase>>* commonObjMap){
        mCommonObjMap = commonObjMap;
        mGoalCommonObj.mCommonObjMap = mCommonObjMap;
        mFeedbackCommonObj.mCommonObjMap = mCommonObjMap;
        mResultCommonObj.mCommonObjMap = mCommonObjMap;
    }
    virtual ~ROS2ActClientImpl() {

        mGoalIdActionCallBackMap.clear();    
    }

    virtual void cleanup ()
    {
        std::unique_lock lck(mDestMutex);
        mInDest = true;
        mDestCond.wait(lck,[this](){return this->mInUse == false;});
    }

    virtual intptr_t createActClient(const std::string& act_name,
                                    rclcpp::Node::SharedPtr theNode,
                                    rclcpp::QoS & goal_service_qos,
                                    rclcpp::QoS & result_service_qos,
                                    rclcpp::QoS & cancel_service_qos,
                                    rclcpp::QoS & feedback_topic_qos,
                                    rclcpp::QoS & status_topic_qos) {
    
        rcl_action_client_options_t rclQosOpt;
        
        rclQosOpt.goal_service_qos      =   goal_service_qos.get_rmw_qos_profile();
        rclQosOpt.result_service_qos    =   result_service_qos.get_rmw_qos_profile();
        rclQosOpt.cancel_service_qos    =   cancel_service_qos.get_rmw_qos_profile();
        rclQosOpt.feedback_topic_qos    =   feedback_topic_qos.get_rmw_qos_profile();
        rclQosOpt.status_topic_qos      =   status_topic_qos.get_rmw_qos_profile();
        rclQosOpt.allocator = rcl_get_default_allocator();

        mClient = rclcpp_action::create_client<RosActType>(theNode, act_name, nullptr, rclQosOpt);
        return reinterpret_cast<intptr_t>(mClient.get());
    }
    virtual bool waitForActServer(intptr_t timeout){
        std::chrono::duration<int,std::milli> milliseconds(timeout*1000);
        mIsConnectedToActServer = mClient->wait_for_action_server(milliseconds);
        return mIsConnectedToActServer;
    } 

    virtual int64_t sendGoaltoActserver( const matlab::data::StructArray arr,
                                        void* sd,
                                        SendDataToMATLABFunc_T onGoalActiveCBFunc,
                                        SendDataToMATLABFunc_T onFeedbackReceivedCBFunc,
                                        SendDataToMATLABFunc_T onResultReceivedCBFunc,
                                        const intptr_t hActClient,
                                        const int64_t goalIndex) {
        if(!mIsConnectedToActServer){
            return -1 ;
        }
        
        mSd = sd;
        auto actionCBObj = std::make_shared<ActionCallBack>(this);
        mOnGoalActiveCBFunc = onGoalActiveCBFunc;
        mOnFeedbackReceivedCBFunc = onFeedbackReceivedCBFunc;
        mOnResultReceivedCBFunc = onResultReceivedCBFunc;

        mHactClient = hActClient;
        std::shared_ptr<ActGoalType> goal = std::make_shared<ActGoalType>();
        mGoalCommonObj.copy_from_struct(goal.get(), arr[0], mMultiLibLoader);
        auto send_goal_options = typename rclcpp_action::Client<RosActType>::SendGoalOptions();
        send_goal_options.goal_response_callback =
        std::bind(&ROS2ActClientImpl::ActionCallBack::onGoalResponseCalback, actionCBObj.get(), std::placeholders::_1);
        send_goal_options.feedback_callback =
        std::bind(&ROS2ActClientImpl::ActionCallBack::onFeedbackReceivedCallback, actionCBObj.get(), std::placeholders::_1, std::placeholders::_2);
        send_goal_options.result_callback =
        std::bind(&ROS2ActClientImpl::ActionCallBack::onResultReceivedCallback, actionCBObj.get(), std::placeholders::_1);
        actionCBObj->goalIndex = goalIndex;
        mGoalIdActionCallBackMap[goalIndex]=actionCBObj;           
        mClient->async_send_goal(*goal, send_goal_options);
        return goalIndex;
    }
    virtual bool cancelGoal(int64_t goalIndex,SendDataToMATLABFunc_T onCancelCBFunc) {
        auto actionCBIter = mGoalIdActionCallBackMap.find(goalIndex);
        if(actionCBIter != mGoalIdActionCallBackMap.end() && 
            actionCBIter->second->mGoalAccepted && 
            !actionCBIter->second->mIsCompleted) {
            mOnCancelCBFunc=onCancelCBFunc;
            auto cancelCallBack =
            std::bind(&ROS2ActClientImpl::ActionCallBack::onCancellCallBack,actionCBIter->second.get(), std::placeholders::_1);
            mClient->async_cancel_goal(actionCBIter->second->mGoalHandle,cancelCallBack);
            return true;
        }else {
            return false;
        }
     }

    void onCancellAllCallBack( std::shared_ptr<action_msgs::srv::CancelGoal::Response> response){
        // If action client object is being deleted,
        // No need to execute further. Just return. mInDest = true indicates 
        // ActionClient Object being destroyed.
        if(mInDest)
           return;

        // If the callback is being executed , hold any requests to delete the 
        // Action client object and notify it after the callback is completed.
        std::lock_guard<std::mutex> lck(mDestMutex);
        mInUse = true;     

	    for ( auto goal : response->goals_canceling ){
           auto goalUUID = goal.goal_id.uuid;
           for ( auto iter : mGoalIdActionCallBackMap) {
                if(iter.second->mGoalAccepted && !iter.second->mIsCompleted){
                    if(iter.second->mUUID == goalUUID ) {
                        iter.second->mIsCompleted=true;                    
                    }
                }
           }
        }       

        auto ros2MsgFactory =
            mMultiLibLoader->createInstance<ROS2MsgElementInterfaceFactory>("ros2_action_msgs_CancelGoal_service"); 
        auto outArray = ros2MsgFactory->generateMLMessage(eResponse,response.get(),mMultiLibLoader,mCommonObjMap);
        
        if (mSd != NULL) {
            appendAndSendToMATLAB(mSd, mOnCancelAllCBFunc, outArray, mHactClient);
        }

        // Notify the destructor that the callback is completed.
        mInUse = false;
        mDestCond.notify_one();        
    }

    void onCancellBeforeCallBack( std::shared_ptr<action_msgs::srv::CancelGoal::Response> response) {
        // If action client object is being deleted,
        // No need to execute further. Just return. mInDest = true indicates 
        // ActionClient Object being destroyed.
        if(mInDest)
           return;

        // If the callback is being executed , hold any requests to delete the 
        // Action client object and notify it after the callback is completed.
        std::lock_guard<std::mutex> lck(mDestMutex);
        mInUse = true;

        for ( auto goal : response->goals_canceling ){
            auto goalUUID = goal.goal_id.uuid;
            for ( auto iter : mGoalIdActionCallBackMap) {
                if(iter.second->mGoalAccepted && !iter.second->mIsCompleted){
                    if(iter.second->mUUID == goalUUID ) {
                        iter.second->mIsCompleted=true;                    
                    }
                }
           }
        }       

        auto ros2MsgFactory =
            mMultiLibLoader->createInstance<ROS2MsgElementInterfaceFactory>("ros2_action_msgs_CancelGoal_service"); 
        auto outArray = ros2MsgFactory->generateMLMessage(eResponse,response.get(),mMultiLibLoader,mCommonObjMap);
        
        if (mSd != NULL) {
            appendAndSendToMATLAB(mSd, mOnCancelBeforeCBFunc, outArray, mHactClient);
        }
        // Notify the destructor that the callback is completed.
        mInUse = false;
        mDestCond.notify_one();        
    }

    virtual bool cancelAllGoal(SendDataToMATLABFunc_T onCancelCBFunc){
        mOnCancelAllCBFunc=onCancelCBFunc;
        auto cancel_callback =
        std::bind(&ROS2ActClientImpl::onCancellAllCallBack,this, std::placeholders::_1);
        mClient->async_cancel_all_goals(cancel_callback);
        return true;
    }
    
    // Cancel Goals before the specified time.
    virtual bool cancelGoalsBeforeTime(int32_t sec,uint32_t nanosec,SendDataToMATLABFunc_T onCancelBeforeCBFunc){
        mOnCancelBeforeCBFunc=onCancelBeforeCBFunc;
        auto cancelBeforeCallBack =
        std::bind(&ROS2ActClientImpl::onCancellBeforeCallBack,this, std::placeholders::_1);
        mClient->async_cancel_goals_before(rclcpp::Time(sec,nanosec),cancelBeforeCallBack);
        return true;
    }

    virtual bool isServerConnected(){
        mIsConnectedToActServer = mClient->action_server_is_ready();
        return mIsConnectedToActServer;
    }
    virtual int32_t getState(int64_t goalIndex){
        auto actionCBIter = mGoalIdActionCallBackMap.find(goalIndex);
        // In ROS 2 Humble, when a goal is accepted and completed, it
        // gives the last known status. So removed the condition
        // actionCBIter->second->mIsCompleted here.
        if(actionCBIter != mGoalIdActionCallBackMap.end() && 
            actionCBIter->second->mGoalAccepted) {
                return static_cast<int32_t>(actionCBIter->second->mGoalHandle->get_status()) ;
        }else{
            return -1;
        }
    }
    private :
        std::map<int64_t,std::shared_ptr<ActionCallBack>> mGoalIdActionCallBackMap; 
};


// ROS2 Action Server.
template<class RosActType, class ActFeedbackType, class ActResultType, class RosActGoalTypePtr, class GoalCommonType, class FeedbackCommonType, class ResultCommonType>
class ROS2ActServerImpl : public MATLABActServerInterface {
    typename rclcpp_action::Server<RosActType>::SharedPtr mServer;
    std::map<std::string,std::shared_ptr<rclcpp_action::ServerGoalHandle<RosActType>>> mGoalIDMap;

    void* mSd;
    SendDataToMATLABAndReturnFunc_T mHandleGoalCBFunc;
    SendDataToMATLABAndReturnFunc_T mHandleCancelCBFunc;
    SendDataToMATLABFunc_T mHandleAcceptedCBFunc;  
    intptr_t mHactServer;
  
    GoalCommonType mGoalCommonObj; 
    FeedbackCommonType mFeedbackCommonObj; 
    ResultCommonType mResultCommonObj; 
    
    public:
        ROS2ActServerImpl()
            : MATLABActServerInterface(){
    
        }
        virtual ~ROS2ActServerImpl() {
            mGoalIDMap.clear();
        }
        virtual void setCommonObjMap(std::map<std::string,std::shared_ptr<MATLABROS2MsgInterfaceBase>>* commonObjMap){
            mCommonObjMap = commonObjMap;
            mGoalCommonObj.mCommonObjMap = mCommonObjMap;
            mFeedbackCommonObj.mCommonObjMap = mCommonObjMap;
            mResultCommonObj.mCommonObjMap = mCommonObjMap;
        }

        // Callback function that is triggered on receiving a new goal from an action client.
        rclcpp_action::GoalResponse handleGoal(
        const rclcpp_action::GoalUUID & uuid,
        std::shared_ptr<const typename RosActType::Goal> goal)
        {
            auto outerArray = mFactory.createStructArray({1, 1}, {"goalUUID","goal"});
            auto goalID = rclcpp_action::to_string(uuid);
            outerArray[0]["goalUUID"]= mFactory.createCharArray(goalID);
            auto outArray = mGoalCommonObj.get_arr(mFactory, goal.get(), mMultiLibLoader);
            outerArray[0]["goal"]= outArray;

            // Default value to accept the goal request.
            int32_t goalStatus = 2;
            if (mSd != NULL) {
                goalStatus= appendAndSendToMATLABAndReturn(mSd,mHandleGoalCBFunc, outerArray,mHactServer,goalID);
            }
            rclcpp_action::GoalResponse goalResponse = static_cast<rclcpp_action::GoalResponse>(goalStatus);
            return goalResponse;
        }

        // Callback function that is triggered on receiving a cancel request from an action client.
        rclcpp_action::CancelResponse handleCancel(const std::shared_ptr<rclcpp_action::ServerGoalHandle<RosActType>> goal_handle)
        {
            auto uuid=goal_handle->get_goal_id();
            auto outerArray = mFactory.createStructArray({1, 1}, {"goalUUID","goal"});
            auto goalID = rclcpp_action::to_string(uuid);
            if(mGoalIDMap.find(goalID) == mGoalIDMap.end())
                mGoalIDMap.insert(std::pair<std::string,std::shared_ptr<rclcpp_action::ServerGoalHandle<RosActType>>>(goalID,goal_handle));

            outerArray[0]["goalUUID"]= mFactory.createCharArray(goalID);
            auto outArray = mGoalCommonObj.get_arr(mFactory, goal_handle->get_goal().get(), mMultiLibLoader);  
            outerArray[0]["goal"]= outArray;
            // Default value to accept a cancel request.
            int32_t cancelStatus = 2;

            if (mSd != NULL) {
                // Receive the response from the MATLAB front end to either accept or reject the cancel request.
                cancelStatus = appendAndSendToMATLABAndReturn(mSd,mHandleCancelCBFunc, outerArray,mHactServer,goalID);
            }
            rclcpp_action::CancelResponse cancelResponse = static_cast<rclcpp_action::CancelResponse>(cancelStatus);
            return cancelResponse;
        }

        // Callback function that is triggered on accepting a new goal.
        void handleAccepted(const std::shared_ptr<rclcpp_action::ServerGoalHandle<RosActType>> goal_handle)
        {
            using namespace std::placeholders;
            auto uuid=goal_handle->get_goal_id();
            auto outerArray = mFactory.createStructArray({1, 1}, {"goalUUID","goal"});
            auto goalID = rclcpp_action::to_string(uuid);   
            if(mGoalIDMap.find(goalID) == mGoalIDMap.end())
                mGoalIDMap.insert(std::pair<std::string,std::shared_ptr<rclcpp_action::ServerGoalHandle<RosActType>>>(goalID,goal_handle));
            
            outerArray[0]["goalUUID"]= mFactory.createCharArray(goalID);
            auto outArray = mGoalCommonObj.get_arr(mFactory, goal_handle->get_goal().get(), mMultiLibLoader);  
            outerArray[0]["goal"]= outArray;   
            if (mSd != NULL) {
                appendAndSendToMATLAB(mSd,mHandleAcceptedCBFunc, outerArray,mHactServer);
            }
        }
        
        virtual intptr_t addActServer(std::shared_ptr<rclcpp::Node> theNode,
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
        
            rcl_action_server_options_t     rclQosOpt;

            // QoS Settings.
            rclQosOpt.goal_service_qos      =   goal_service_qos.get_rmw_qos_profile();
            rclQosOpt.result_service_qos    =   result_service_qos.get_rmw_qos_profile();
            rclQosOpt.cancel_service_qos    =   cancel_service_qos.get_rmw_qos_profile();
            rclQosOpt.feedback_topic_qos    =   feedback_topic_qos.get_rmw_qos_profile();
            rclQosOpt.status_topic_qos      =   status_topic_qos.get_rmw_qos_profile();
            rclQosOpt.allocator =               rcl_get_default_allocator();        
            
            mSd = sd;
            mHandleGoalCBFunc = handleGoalCBFunc;
            mHandleCancelCBFunc = handleCancelCBFunc;
            mHandleAcceptedCBFunc = handleAcceptedCBFunc;
            mHactServer = hSvcServer;
            mServer = rclcpp_action::create_server<RosActType>(theNode->get_node_base_interface(),
                                                               theNode->get_node_clock_interface(),
                                                               theNode->get_node_logging_interface(),
                                                               theNode->get_node_waitables_interface(),
                                                               act_name,
                                                               std::bind(&ROS2ActServerImpl::handleGoal, this, std::placeholders::_1, std::placeholders::_2),
                                                               std::bind(&ROS2ActServerImpl::handleCancel, this, std::placeholders::_1),
                                                               std::bind(&ROS2ActServerImpl::handleAccepted, this, std::placeholders::_1),
                                                               rclQosOpt
                                                              );
            return reinterpret_cast<intptr_t>(mServer.get());
        }
        // check if a goal is active.
        virtual bool isActive(const std::string & uuid){
            auto iter = mGoalIDMap.find(uuid);
            if(iter == mGoalIDMap.end()) {
                return false;
            }
            return iter->second->is_active();
        }
        
        virtual bool isExecuting(const std::string & uuid){
            auto iter = mGoalIDMap.find(uuid);
            if(iter == mGoalIDMap.end()) {
                return false;
            }
            return iter->second->is_executing();
        }

        // Check if the goal is in cancelling state.
        virtual bool isCancelled(const std::string & uuid){
            auto iter = mGoalIDMap.find(uuid);
            if(iter == mGoalIDMap.end()) {
                return false;
            }
            return iter->second->is_canceling();
        }
        
        virtual void publishFeedback(const std::string & uuid,const matlab::data::StructArray arr) {
            auto iter = mGoalIDMap.find(uuid);
            if(iter == mGoalIDMap.end()) {
                return;
            }
            
            std::shared_ptr<ActFeedbackType> feedback = std::make_shared<ActFeedbackType>();
            mFeedbackCommonObj.copy_from_struct(feedback.get(), arr[0], mMultiLibLoader);
            iter->second->publish_feedback(feedback);
        }

        // Abort a goal with goal id as uuid .
        // Note : Goal state must be in cancelling or executing state for the state transition to abort.
        virtual void setAborted(const matlab::data::StructArray arr, 
                                std::string text,const std::string & uuid){
            auto iter = mGoalIDMap.find(uuid);
            if(iter == mGoalIDMap.end()) {
                return;
            }        
            if(!(iter->second->is_canceling() || iter->second->is_executing()))
                throw std::logic_error(" Goal State must be in CANCELLING or EXECUTING State for Abort");        
            std::shared_ptr<ActResultType> result = std::make_shared<ActResultType>();
            mResultCommonObj.copy_from_struct(result.get(), arr[0], mMultiLibLoader);
            iter->second->abort(result);

            // Goal has reached terminal state and is no longer needed.
            mGoalIDMap.erase(iter);
        }

        // Change the goal state from cancelling to cancelled state.
        // Note : Goal state must be in cancelling state to transition to cancelled state.
        virtual void setPreempted(const matlab::data::StructArray arr, 
                                std::string text,const std::string & uuid){
        
            auto iter = mGoalIDMap.find(uuid);
            if(iter == mGoalIDMap.end()) {
                return;
            }
            if(!iter->second->is_canceling())
                throw std::logic_error(" Goal State must be in CANCELLING State for CANCELLED state transition");
            std::shared_ptr<ActResultType> result= std::make_shared<ActResultType>();
            mResultCommonObj.copy_from_struct(result.get(), arr[0], mMultiLibLoader);
            iter->second->canceled(result);

            // Goal has reached terminal state and is no longer needed.
            mGoalIDMap.erase(iter);
        }

        // Change the goal state to succeeded .
        // Goal state should be in either cancelling state or executing state for state transition.
        virtual void setSucceeded(const matlab::data::StructArray arr, 
                                std::string text,const std::string & uuid){

            auto iter = mGoalIDMap.find(uuid);
            if(iter == mGoalIDMap.end()) {
                return;
            }
        
            if(!(iter->second->is_canceling() || iter->second->is_executing()))
                throw std::logic_error(" Goal State must be in CANCELLING or EXECUTING State for SUCCEED state transition ");
            std::shared_ptr<ActResultType> result = std::make_shared<ActResultType>();
            mResultCommonObj.copy_from_struct(result.get(), arr[0], mMultiLibLoader);
            iter->second->succeed(result);

            // Goal has reached terminal state and is no longer needed.
            mGoalIDMap.erase(iter);
        }
};
#endif // ROS2ACTIONTEMPLATES_H
