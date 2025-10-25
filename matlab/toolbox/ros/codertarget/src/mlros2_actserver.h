// Copyright 2023-2024 The MathWorks, Inc.
#ifndef _MLROS2_ACTSERVER_H_
#define _MLROS2_ACTSERVER_H_

#include <iostream>
#include <memory>
#include <map>
#include <string>
#include <mutex>
#include <functional>
#include <chrono>
#include <thread>
#include "rclcpp/rclcpp.hpp"
#include "rclcpp/node.hpp"
#include "rclcpp_action/rclcpp_action.hpp"
#include "rclcpp_action/server.hpp"
#include "mlros2_qos.h"
#include "ros2_structmsg_conversion.h"

#define MATLABROS2ActServer_createActServer(obj, theNode, mlActName, mlActSize, goalServiceQoS, resultServiceQoS, cancelServiceQoS, feedbackTopicQoS, statusTopicQoS) \
    obj->createActServer(theNode, mlActName, mlActSize, goalServiceQoS, resultServiceQoS, cancelServiceQoS, feedbackTopicQoS, statusTopicQoS)
#define MATLABROS2ActServer_mlSendFeedback(obj, feedbackMsgStruct, uuid, uuidSize) \
    obj->mlSendFeedback(feedbackMsgStruct, uuid, uuidSize)
#define MATLABROS2ActServer_mlIsPreemptRequested(obj, uuid, uuidSize, status) \
    obj->mlIsPreemptRequested(uuid, uuidSize, status)
#define MATLABROS2ActServer_mlIsCanceling(obj, uuid, uuidSize, status) \
    obj->mlIsCanceling(uuid, uuidSize, status)
#define MATLABROS2ActServer_rejectGoal(obj) obj->rejectGoal()
#define MATLABROS2ActServer_getCurrentUUIDSize(obj) obj->getCurrentUUIDSize()
#define MATLABROS2ActServer_getCurrentGoalHandle(obj, uuid, goal) \
    obj->getCurrentGoalHandle(uuid, goal)
#define MATLABROS2ActServer_sendGoalTerminalStatus(obj, resultStruct, uuid, uuidSize, status) \
    obj->sendGoalTerminalStatus(resultStruct, uuid, uuidSize, status)
#define MATLABROS2ActServer_abortActiveGoalIfAny(obj, goalGetsAborted, uuid, uuidSize) \
    obj->abortActiveGoalIfAny(goalGetsAborted, uuid, uuidSize)

#define MATLABROS2ActServer_lock(obj) obj->lock()
#define MATLABROS2ActServer_unlock(obj) obj->unlock()

template <class ActionType,
          class GoalMsgType,
          class FbMsgType,
          class ResultMsgType,
          class GoalStructType,
          class FbStructType,
          class ResultStructType>
class MATLABROS2ActServer {
  public:
    RCLCPP_SMART_PTR_DEFINITIONS(MATLABROS2ActServer)
    MATLABROS2ActServer(std::function<void(void)> executeGoalCallback,
                        std::function<void(void)> receiveGoalCallback,
                        std::function<void(void)> cancelGoalCallback,
                        GoalStructType* goalStructPtr,
                        FbStructType* feedbackStructPtr,
                        ResultStructType* resultStructPtr)
               : executeGoalCallback_{executeGoalCallback}
               , receiveGoalCallback_{receiveGoalCallback}
               , cancelGoalCallback_{cancelGoalCallback}
               , goalStructPtr_{goalStructPtr}
               , feedbackStructPtr_{feedbackStructPtr}
               , resultStructPtr_{resultStructPtr} {}
    
    /**
     * Create an action server and register it into current ROS 2 network.
     * @param theNode - pointer to ROS 2 Node
     * @param mlActName - the name of the action passed from MATLAB
     * @param mlActSize - the length of the action name
     * @param goalServiceQoS - QoS profile for goal service
     * @param resultServiceQoS - QoS profile for result service
     * @param cancelServiceQoS - QoS profile for cancel service
     * @param feedbackTopicQoS - QoS profile for feedback topic
     * @param statusTopicQoS - QoS profile for status topic
     * @param group - callback group to associate with action server
     */
    void createActServer(rclcpp::Node::SharedPtr theNode,
                         const char* mlActName,
                         size_t mlActSize,
                         const rmw_qos_profile_t& goalServiceQoS = rmw_qos_profile_default,
                         const rmw_qos_profile_t& resultServiceQoS = rmw_qos_profile_default,
                         const rmw_qos_profile_t& cancelServiceQoS = rmw_qos_profile_default,
                         const rmw_qos_profile_t& feedbackTopicQoS = rmw_qos_profile_default,
                         const rmw_qos_profile_t& statusTopicQoS = rmw_qos_profile_default,
                         rclcpp::CallbackGroup::SharedPtr group = nullptr) {
        std::string actname(mlActName, mlActSize);
        rcl_action_server_options_t options;
        options.goal_service_qos = goalServiceQoS;
        options.result_service_qos = resultServiceQoS;
        options.cancel_service_qos = cancelServiceQoS;
        options.feedback_topic_qos = feedbackTopicQoS;
        options.status_topic_qos = statusTopicQoS;
        options.allocator = rcl_get_default_allocator();

        server_ = rclcpp_action::create_server<ActionType>(
                        theNode,actname,
                        std::bind(&MATLABROS2ActServer<ActionType,GoalMsgType,FbMsgType,ResultMsgType,
                                  GoalStructType,FbStructType,ResultStructType>::handleGoal,
                                  this, std::placeholders::_1, std::placeholders::_2),
                        std::bind(&MATLABROS2ActServer<ActionType,GoalMsgType,FbMsgType,ResultMsgType,
                                  GoalStructType,FbStructType,ResultStructType>::handleCancel,
                                  this, std::placeholders::_1),
                        std::bind(&MATLABROS2ActServer<ActionType,GoalMsgType,FbMsgType,ResultMsgType,
                                  GoalStructType,FbStructType,ResultStructType>::handleAccepted,
                                  this, std::placeholders::_1),
                        options);
    }

    /**
     * Callback function for accepting goal
     * @param uuid - goal unique id
     * @param goal - goal message
     */
    rclcpp_action::GoalResponse handleGoal(
                    const rclcpp_action::GoalUUID & uuid,
                    std::shared_ptr<const GoalMsgType> goal) {
      // Update current goal and uuid
      currentUUID_ = rclcpp_action::to_string(uuid);
      currentUUIDSize_ = currentUUID_.length();
      currentGoalMsg_ = goal;

      // Call customized MATLAB receive goal callback
      lock();
      receiveGoalCallback_();
      auto currentGoalResp = goalResponse_;
	  
      // Reset back to default accept
      goalResponse_ = rclcpp_action::GoalResponse::ACCEPT_AND_EXECUTE;
      return currentGoalResp;
    }

    /**
     * Callback function for canceling goal
     * @param goal_handle - goal handle of the associated goal
     */
    rclcpp_action::CancelResponse handleCancel(
                    const typename std::shared_ptr<rclcpp_action::ServerGoalHandle<ActionType>> goal_handle) {
      // Update current goal and uuid
      currentUUID_ = rclcpp_action::to_string(goal_handle->get_goal_id());
      currentGoalMsg_ = goal_handle->get_goal();

      // Call customized MATLAB cancel goal callback
      lock();
      cancelGoalCallback_();

      // Always accept cancel request
      return rclcpp_action::CancelResponse::ACCEPT;
    }

    /**
     * Callback function for goal execution
     * @param goal_handle - goal handle of the associated goal
     */
    void handleAccepted(
            const typename std::shared_ptr<rclcpp_action::ServerGoalHandle<ActionType>> goal_handle) {
      // Spin up a new thread to execute accepted goals to avoid blocking executor
      std::string goalUUID = rclcpp_action::to_string(goal_handle->get_goal_id());
      goalHandleMap_[goalUUID] = goal_handle;
      std::thread{std::bind(&MATLABROS2ActServer<ActionType,GoalMsgType,FbMsgType,ResultMsgType,
                            GoalStructType,FbStructType,ResultStructType>::execute, this, std::placeholders::_1),
                  goal_handle}.detach();
    }

    /**
     * Actual execution function for each accepted goal
     * @param goal_handle - goal handle of the associated goal
     */
    void execute(const typename std::shared_ptr<rclcpp_action::ServerGoalHandle<ActionType>> goal_handle) {
      // Keep a local copy of uuid since executeGoalCallback_() may take long time to execute
      std::string loc_uuid = rclcpp_action::to_string(goal_handle->get_goal_id());

      // Update current goal and uuid
      lock();
      currentUUID_ = loc_uuid;
      currentGoalMsg_ = goal_handle->get_goal();

      // Call customized MATLAB execute goal callback
      executeGoalCallback_();
      // Erase goal from map after finishing execution
      goalHandleMap_.erase(loc_uuid);
    }

    /**
     * Send feedback message to action client
     * @param feedbackMsgStruct - feedback message struct from MATLAB
     * @param uuid - goal unique id associate with a goal
     * @param uuidSize - size of goal unique id
     */
    void mlSendFeedback(FbStructType feedbackMsgStruct, const char* uuid, size_t uuidSize){
        std::string goalUUID(uuid, uuidSize);
        FbStructType* feedbackStructPtr = &feedbackMsgStruct;
        auto feedbackMsgPtr = std::make_shared<FbMsgType>();
        struct2msg(*feedbackMsgPtr.get(),feedbackStructPtr);
        auto goal_handle = goalHandleMap_[goalUUID];
        goal_handle->publish_feedback(feedbackMsgPtr);
    }

    /**
     * Evaluate whether a goal is cancelling or inactive
     * @param uuid - goal unique id associate with a goal
     * @param uuidSize - size of goal unique id
     * @param status - indicate whether a goal is cancelling
     */
    void mlIsPreemptRequested(const char* uuid, size_t uuidSize, bool* status){
        std::string goalUUID(uuid, uuidSize);
        auto goal_handle = goalHandleMap_[goalUUID];
        *status = goal_handle->is_canceling() || (!goal_handle->is_active());
    }

    /**
     * Evaluate whether a goal is cancelling
     * @param uuid - goal unique id associate with a goal
     * @param uuidSize - size of goal unique id
     * @param status - indicate whether a goal is cancelling
     */
    void mlIsCanceling(const char* uuid, size_t uuidSize, bool* status){
        std::string goalUUID(uuid, uuidSize);
        auto goal_handle = goalHandleMap_[goalUUID];
        *status = goal_handle->is_canceling();
    }

    /**
     * Get current goal unique id size
     */
    int32_t getCurrentUUIDSize(){
        return currentUUIDSize_;
    }

    /**
     * Get current goal and uuid
     * @param uuid - goal unique id associate with a goal
     * @param goal - goal message for use in MATLAB
     */
    void getCurrentGoalHandle(char* uuid, GoalStructType* goal){
        const char* pStr =  currentUUID_.c_str();
        strncpy(uuid,pStr,currentUUIDSize_);
        uuid[currentUUIDSize_] = 0;
        msg2struct(goal, *currentGoalMsg_.get());
    }

    /**
     * Reject a new arrived goal
     */
    void rejectGoal(){
        goalResponse_ = rclcpp_action::GoalResponse::REJECT;
    }

    /**
     * Send goal terminal status
     * @param resultStruct - result message structure
     * @param uuid - goal unique id associate with a goal
     * @param uuidSize - length of uuid
     * @param mlStatus - goal terminal status
     * @param statusSize - length of status
     */
    void sendGoalTerminalStatus(ResultStructType* resultStruct, const char* uuid, size_t uuidSize, std::string status){
        auto resultMsgPtr = std::make_shared<ResultMsgType>();
        struct2msg(*resultMsgPtr.get(),resultStruct);
        std::string goalUUID(uuid,uuidSize);
        auto goal_handle = goalHandleMap_[goalUUID];
        if (rclcpp::ok()){
            if (status.compare("succeed")==0){
                goal_handle->succeed(resultMsgPtr);
            }
            else if (status.compare("canceled")==0){
                goal_handle->canceled(resultMsgPtr);
            }
            else{
                goal_handle->abort(resultMsgPtr);
            }
        }
    }

    /**
     * Abort any active goals except the new arrived goal
     * @param goalGetsAborted - indicates whether at least one goal has been aborted
     * @param uuid - goal unique id
     * @param uuidSize - length of unique id
     */
    void abortActiveGoalIfAny(bool* goalGetsAborted, const char* uuid, size_t uuidSize){
        std::string idToKeep(uuid,uuidSize);
        typename std::map<std::string, std::shared_ptr<rclcpp_action::ServerGoalHandle<ActionType>> >::iterator it;
        for (it=goalHandleMap_.begin(); it!=goalHandleMap_.end(); ++it){
            if (idToKeep.compare(it->first)!=0){
                // Abort goal
                auto goal_handle = it->second;
                auto resultMsgPtr = std::make_shared<ResultMsgType>();
                if (goal_handle->is_active()){
                    goal_handle->abort(resultMsgPtr);
                    *goalGetsAborted = true;
					// Wait until fully cancel
					while (goal_handle->is_canceling()){
						std::this_thread::sleep_for(std::chrono::milliseconds(100));
					}
                    // No need to erase from goalHandleMap_, it will be 
                    // handled in execute callback
                }
            }
        }
    }

    /**
     * Mutex lock to avoid read and write conflict on messages
     */
    void lock() {
        mutex_.lock();
    }

    /**
     * Mutex unlock to release mutex lock
     */
    void unlock() {
        mutex_.unlock();
    }

  private:
    std::mutex mutex_;
    GoalStructType* goalStructPtr_;
    FbStructType* feedbackStructPtr_;
    ResultStructType* resultStructPtr_;

    std::function<void(void)> executeGoalCallback_;
    std::function<void(void)> receiveGoalCallback_;
    std::function<void(void)> cancelGoalCallback_;

    typename rclcpp_action::Server<ActionType>::SharedPtr server_;

    int32_t currentUUIDSize_;
    std::string currentUUID_;
    std::shared_ptr<const GoalMsgType> currentGoalMsg_;

    std::map<std::string, typename std::shared_ptr<rclcpp_action::ServerGoalHandle<ActionType>> > goalHandleMap_;
    rclcpp_action::GoalResponse goalResponse_ = rclcpp_action::GoalResponse::ACCEPT_AND_EXECUTE;
};
#endif