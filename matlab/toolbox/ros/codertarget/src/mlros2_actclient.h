// Copyright 2022-2023 The MathWorks, Inc.
#ifndef _MLROS2_ACTCLIENT_H_
#define _MLROS2_ACTCLIENT_H_

#include <iostream>
#include <memory>
#include <string>
#include <mutex>
#include <functional>                   // For std::function
#include <future>                       // For std::future
#include <chrono>                       // For std::chrono
#include <thread>                       // For generate thread pause
#include <condition_variable>           // For std::condition_variable
#include "rclcpp/rclcpp.hpp"
#include "rclcpp/node.hpp"
#include "rclcpp_action/client.hpp"
#include "rclcpp_action/create_client.hpp"
#include "mlros2_node.h"
#include "mlros2_qos.h"
#include "ros2_structmsg_conversion.h"  // For msg2struct()

#define MATLABROS2ActClient_lock(obj) obj->lock()
#define MATLABROS2ActClient_unlock(obj) obj->unlock()
#define MATLABROS2ActClient_createActClient(obj, theNode, mlActName, mlActSize, goalServiceQos, resultServiceQos, cancelServiceQos, feedbackTopicQos, statusTopicQos) \
    obj->createActClient(theNode, mlActName, mlActSize, goalServiceQos, resultServiceQos, cancelServiceQos, feedbackTopicQos, statusTopicQos)
#define MATLABROS2ActClient_waitForServer(obj, timeout, status) \
    obj->waitForServer(timeout, status)
#define MATLABROS2ActClient_sendGoal(obj) obj->sendGoal()
#define MATLABROS2ActClient_getGoalIndex(obj) obj->getGoalIndex()
#define MATLABROS2ActClient_getCurrentCancelGoalIndex(obj) obj->getCurrentCancelGoalIndex()
#define MATLABROS2ActClient_getGoalInfo(obj, goalIndex, uuid, secStamp, nanosecStamp, isGoalUUIDValid) \
    obj->getGoalInfo(goalIndex, uuid, secStamp, nanosecStamp, isGoalUUIDValid)
#define MATLABROS2ActClient_isResultReady(obj, goalIndex) obj->isResultReady(goalIndex)
#define MATLABROS2ActClient_getResultInfo(obj, goalIndex, resultCode) \
    obj->getResultInfo(goalIndex, resultCode)
#define MATLABROS2ActClient_getStatus(obj, goalIndex) obj->getStatus(goalIndex)
#define MATLABROS2ActClient_getResult(obj, goalIndex, timeout) \
    obj->getResult(goalIndex, timeout)
#define MATLABROS2ActClient_cancelGoal(obj, goalIndex) obj->cancelGoal(goalIndex)
#define MATLABROS2ActClient_cancelGoalAndWait(obj, goalIndex, timeout) \
    obj->cancelGoalAndWait(goalIndex, timeout)
#define MATLABROS2ActClient_cancelAllGoals(obj) obj->cancelAllGoals()
#define MATLABROS2ActClient_cancelAllGoalsAndWait(obj, timeout) \
    obj->cancelAllGoalsAndWait(timeout)
#define MATLABROS2ActClient_cancelGoalsBefore(obj, sec, nanosec) \
    obj->cancelGoalsBefore(sec, nanosec)
#define MATLABROS2ActClient_cancelGoalsBeforeAndWait(obj, sec, nanosec, timeout) \
    obj->cancelGoalsBeforeAndWait(sec, nanosec, timeout)
#define MATLABROS2ActClient_isServerConnected(obj) obj->isServerConnected()

template <class ActionType,
          class GoalMsgType,
          class FbMsgType,
          class ResultMsgType,
          class CancelRespMsgType,
          class GoalStructType,
          class FbStructType,
          class ResultStructType,
          class CancelRespStructType>
class MATLABROS2ActClient {
  public:
    using GoalHandleType = rclcpp_action::ClientGoalHandle<ActionType>;

    RCLCPP_SMART_PTR_DEFINITIONS(MATLABROS2ActClient)
    MATLABROS2ActClient(std::function<void(void)> goalResponseCallback,
                        std::function<void(void)> feedbackCallback,
                        std::function<void(void)> resultCallback,
                        std::function<void(void)> cancelCallback,
                        std::function<void(void)> cancelBeforeCallback,
                        std::function<void(void)> cancelAllCallback,
                        GoalStructType* goalStructPtr,
                        FbStructType* feedbackStructPtr,
                        ResultStructType* resultStructPtr,
                        CancelRespStructType* cancelRespStructPtr)
                : goalResponseCallback_ {goalResponseCallback}
                , feedbackCallback_ {feedbackCallback}
                , resultCallback_ {resultCallback}
                , cancelCallback_ {cancelCallback}
                , cancelBeforeCallback_ {cancelBeforeCallback}
                , cancelAllCallback_ {cancelAllCallback}
                , goalStructPtr_{goalStructPtr}
                , feedbackStructPtr_{feedbackStructPtr}
                , resultStructPtr_{resultStructPtr}
                , cancelRespStructPtr_{cancelRespStructPtr} {}
    
    /**
     * Create an action client and register it into current ROS 2 network.
     * @param theNode - pointer to ROS 2 Node
     * @param mlActName - the name of the action passed from MATLAB
     * @param mlActSize - the length of the action name
     * @param goalServiceQos - QoS profile for goal service passed from MATLAB
     * @param resultServiceQos - QoS profile for result service passed from MATLAB
     * @param cancelServiceQos - QoS profile for cancel service passed from MATLAB
     * @param feedbackTopicQos - QoS profile for feedback topic passed from MATLAB
     * @param statusTopicQos - QoS profile for status topic passed from MATLAB
     * @param group - callback group to associate with action client
     */
    void createActClient(rclcpp::Node::SharedPtr theNode,
                         const char* mlActName,
                         size_t mlActSize,
                         const rmw_qos_profile_t& goalServiceQos = rmw_qos_profile_default,
                         const rmw_qos_profile_t& resultServiceQos = rmw_qos_profile_default,
                         const rmw_qos_profile_t& cancelServiceQos = rmw_qos_profile_default,
                         const rmw_qos_profile_t& feedbackTopicQos = rmw_qos_profile_default,
                         const rmw_qos_profile_t& statusTopicQos = rmw_qos_profile_default,
                         rclcpp::CallbackGroup::SharedPtr group = nullptr) {

        std::string actname(mlActName, mlActSize);
        rcl_action_client_options_t options;
        options.goal_service_qos = goalServiceQos;
        options.result_service_qos = resultServiceQos;
        options.cancel_service_qos = cancelServiceQos;
        options.feedback_topic_qos = feedbackTopicQos;
        options.status_topic_qos = statusTopicQos;
        options.allocator = rcl_get_default_allocator();

        client_ = rclcpp_action::create_client<ActionType>(theNode, actname, nullptr, options);
        // Initialize current goal index
        currentGoalIndex_ = 0;
    }

    /**
     * Wait for server to be available.
     * @param timeout - wait timeout carried from MATLAB
     * @param status - boolean pointer to track server status
     */
    void waitForServer(int timeout, bool* status) {
        if (timeout > 0) {
            *status = client_->wait_for_action_server(std::chrono::milliseconds(timeout));
        } else {
            *status = client_->wait_for_action_server();
        }
    }

    /**
     * Check whether server is ready to connect
     */
    bool isServerConnected() {
        return client_->action_server_is_ready();
    }

    /**
     * Send goal message to action server
     */
    void sendGoal() {
        // Set up send goal options, this can be moved to constructor for better performance
        auto send_goal_options = typename rclcpp_action::Client<ActionType>::SendGoalOptions();
        send_goal_options.goal_response_callback = 
            std::bind(&MATLABROS2ActClient<ActionType,GoalMsgType,FbMsgType,ResultMsgType,CancelRespMsgType,
            GoalStructType,FbStructType,ResultStructType,CancelRespStructType>::goal_response_callback, this, std::placeholders::_1);
        send_goal_options.feedback_callback =
            std::bind(&MATLABROS2ActClient<ActionType,GoalMsgType,FbMsgType,ResultMsgType,CancelRespMsgType,
            GoalStructType,FbStructType,ResultStructType,CancelRespStructType>::feedback_callback, this, std::placeholders::_1, std::placeholders::_2);
        send_goal_options.result_callback =
            std::bind(&MATLABROS2ActClient<ActionType,GoalMsgType,FbMsgType,ResultMsgType,CancelRespMsgType,
            GoalStructType,FbStructType,ResultStructType,CancelRespStructType>::result_callback, this, std::placeholders::_1);
        // Get message to be sent
        lock();
        struct2msg(*goalMsgPtr_.get(), goalStructPtr_);
        // Send goal to action server
        client_->async_send_goal(*goalMsgPtr_.get(), send_goal_options);
        unlock();
    }

    /**
     * Cancel goal associated with the goal index
     * @param goalIndex - index of the goal
     */
    void cancelGoal(int32_t goalIndex) {
        waitUntilGoalReady(goalIndex);
        cancelGoalIndex_ = goalIndex;
        auto goalHandle = goalHandles_[goalIndex];
        client_->async_cancel_goal(goalHandle,
                    std::bind(&MATLABROS2ActClient<ActionType,GoalMsgType,FbMsgType,ResultMsgType,CancelRespMsgType,
                    GoalStructType,FbStructType,ResultStructType,CancelRespStructType>::cancel_callback, this, std::placeholders::_1));
    }

    /*
     * Cancel goal associated with the goal index and wait until timeout or complete
     * @param goalIndex - index of the goal
     * @param timeout - timeout for waiting cancel goal
     */
    bool cancelGoalAndWait(int32_t goalIndex, int timeout) {
        waitUntilGoalReady(goalIndex);
        cancelGoalIndex_ = goalIndex;
        auto goalHandle = goalHandles_[goalIndex];
        auto cancelGoalFuture = client_->async_cancel_goal(goalHandle);

        std::future_status resultStatus;
        if (timeout > 0) {
            // User specified timeout
            resultStatus = cancelGoalFuture.wait_for(std::chrono::milliseconds(timeout));
            if (resultStatus == std::future_status::ready) {
                // Received result before timeout
                auto cancelRespPtr = cancelGoalFuture.get();
                lock();
                msg2struct(cancelRespStructPtr_, *cancelRespPtr.get());
                unlock();
                return false;
            } else {
                // Timeout
                return true;
            }
        } else {
            // Use default timeout, which is Inf.
            do {
                resultStatus = cancelGoalFuture.wait_for(std::chrono::seconds(1));
            } while (resultStatus != std::future_status::ready);
            auto cancelRespPtr = cancelGoalFuture.get();
            lock();
            msg2struct(cancelRespStructPtr_, *cancelRespPtr.get());
            unlock();
            return false;
        }
    }

    /*
     * Cancel all active goals this action client sent
     */
    void cancelAllGoals() {
        client_->async_cancel_all_goals(
                    std::bind(&MATLABROS2ActClient<ActionType,GoalMsgType,FbMsgType,ResultMsgType,CancelRespMsgType,
                    GoalStructType,FbStructType,ResultStructType,CancelRespStructType>::cancelAll_callback, this, std::placeholders::_1));
    }

    /*
     * Cancel all active goals this action client sent and wait until timeout or complete
     * @param timeout - timeout for waiting cancel all goals
     */
    bool cancelAllGoalsAndWait(int timeout) {

        auto cancelGoalFuture = client_->async_cancel_all_goals();

        std::future_status resultStatus;
        if (timeout > 0) {
            // User specified timeout
            resultStatus = cancelGoalFuture.wait_for(std::chrono::milliseconds(timeout));
            if (resultStatus == std::future_status::ready) {
                // Received result before timeout
                auto cancelRespPtr = cancelGoalFuture.get();
                lock();
                msg2struct(cancelRespStructPtr_, *cancelRespPtr.get());
                unlock();
                return false;
            } else {
                // Timeout
                return true;
            }
        } else {
            // Use default timeout, which is Inf.
            do {
                resultStatus = cancelGoalFuture.wait_for(std::chrono::seconds(1));
            } while (resultStatus != std::future_status::ready);
            auto cancelRespPtr = cancelGoalFuture.get();
            lock();
            msg2struct(cancelRespStructPtr_, *cancelRespPtr.get());
            unlock();
            return false;
        }
    }

    /*
     * Cancel all goals before certain timestamp
     * @param sec - sec field of timestamp
     * @param nanosec - nanosec field of timestamp
     */
    void cancelGoalsBefore(int32_t sec, uint32_t nanosec) {
        rclcpp::Time timestamp = rclcpp::Time(sec, nanosec);
        client_->async_cancel_goals_before(timestamp,
                    std::bind(&MATLABROS2ActClient<ActionType,GoalMsgType,FbMsgType,ResultMsgType,CancelRespMsgType,
                    GoalStructType,FbStructType,ResultStructType,CancelRespStructType>::cancelBefore_callback, this, std::placeholders::_1));
    }

    /*
     * Cancel all goals before certain timestamp and wait until timeout or complete
     * @param sec - sec field of timestamp
     * @param nanosec - nanosec field of timestamp
     * @param timeout - timeout for waiting cancel goals before
     */
    bool cancelGoalsBeforeAndWait(int32_t sec, uint32_t nanosec, int timeout) {
        rclcpp::Time timestamp = rclcpp::Time(sec, nanosec);
        auto cancelGoalFuture = client_->async_cancel_goals_before(timestamp);

        std::future_status resultStatus;
        if (timeout > 0) {
            // User specified timeout
            resultStatus = cancelGoalFuture.wait_for(std::chrono::milliseconds(timeout));
            if (resultStatus == std::future_status::ready) {
                // Received result before timeout
                auto cancelRespPtr = cancelGoalFuture.get();
                lock();
                msg2struct(cancelRespStructPtr_, *cancelRespPtr.get());
                unlock();
                return false;
            } else {
                // Timeout
                return true;
            }
        } else {
            // Use default timeout, which is Inf.
            do {
                resultStatus = cancelGoalFuture.wait_for(std::chrono::seconds(1));
            } while (resultStatus != std::future_status::ready);
            auto cancelRespPtr = cancelGoalFuture.get();
            lock();
            msg2struct(cancelRespStructPtr_, *cancelRespPtr.get());
            unlock();
            return false;
        }
    }

    /**
     * Get status of a goal associated with given goal index
     * @param goalIndex - index of a goal
     */
    int8_t getStatus(int32_t goalIndex) {
        auto goalHandle = goalHandles_[goalIndex];
        int8_t goalStatus = 0;
        try {
            goalStatus = goalHandle.get()->get_status();
        } catch (...) {
            // return unknown if failed to call
        }
        return goalStatus;
    }

    /**
     * Get result of a goal associated with given goal index and wait
     * @param goalIndex - index of a goal
     * @param timeout - timeout for get result
     */
    bool getResult(int32_t goalIndex, int timeout) {
        auto goalHandle = goalHandles_[goalIndex];
        auto resultFuture = client_->async_get_result(goalHandle);

        std::future_status resultStatus;
        if (timeout > 0) {
            // User specified timeout
            resultStatus = resultFuture.wait_for(std::chrono::milliseconds(timeout));
            if (resultStatus == std::future_status::ready) {
                // Received result before timeout
                auto wrappedResult = resultFuture.get();
                const ResultMsgType* tmpResultMsgPtr_ = wrappedResult.result.get();
                lock();
                msg2struct(resultStructPtr_, *tmpResultMsgPtr_);
                unlock();
                return false;
            } else {
                // Timeout
                return true;
            }
        } else {
            // Use default timeout, which is Inf.
            do {
                resultStatus = resultFuture.wait_for(std::chrono::seconds(1));
            } while (resultStatus != std::future_status::ready);
            auto wrappedResult = resultFuture.get();
            const ResultMsgType* tmpResultMsgPtr_ = wrappedResult.result.get();
            lock();
            msg2struct(resultStructPtr_, *tmpResultMsgPtr_);
            unlock();
            return false;
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

    /**
     * Get goal index of the current goal
     */
    int32_t getGoalIndex(){
        return goalIndex_;
    }

    /**
     * Get current cancel goal index
     */
    int32_t getCurrentCancelGoalIndex(){
        return cancelGoalIndex_;
    }

    /**
     * Get goal information such as goalUUID and timestamp
     * @param goalIndex - index of a goal
     * @param uuid - goal unique id associate with a goal
     * @param secStamp - timestamp sec field
     * @param nanosecStamp - timestamp nanosec field
     */
    void getGoalInfo(int32_t goalIndex, char* uuid, int32_t* secStamp, uint32_t* nanosecStamp, bool* isGoalUUIDValid) {
        waitUntilGoalReady(goalIndex);
        if (quickAccessGoalHandles_[goalIndex].goalUUID.size() > 0) {
            const char* pStr = quickAccessGoalHandles_[goalIndex].goalUUID.c_str();
            strncpy(uuid, pStr, 16);
            uuid[16] = 0;
            *isGoalUUIDValid = true;
        }
        *secStamp = quickAccessGoalHandles_[goalIndex].sec;
        *nanosecStamp = quickAccessGoalHandles_[goalIndex].nanosec;
    }

    /**
     * Inspect whether result of a goal is ready to return
     * @param goalIndex - index of a goal
     */
    bool isResultReady(int32_t goalIndex) {
        return resultCodes_.size() > goalIndex;
    }

    /**
     * Get result code of a goal
     * @param goalIndex - index of a goal
     * @param resultCode - result code of a goal
     */
    void getResultInfo(int32_t goalIndex, int8_t* resultCode){
        *resultCode = resultCodes_[goalIndex];
    }

  private:
        /**
         * Goal response callback for sendGoal
         * @param future - future shared pointer for goal handle
         */
        void goal_response_callback(typename rclcpp_action::ClientGoalHandle<ActionType>::SharedPtr goal_handle) {
            // call MATLAB function here
            if (!goal_handle) {
              std::cout<< "Goal was rejected by server"<< std::endl;
              goalHandles_.push_back(nullptr);
              resultCodes_.push_back(int8_t(0));
              lock();
              quickAccessGoalHandles_.push_back(matlabGoalHandle_);
              cv_.notify_all();
              currentGoalIndex_++;
              unlock();
            } else {
              // Save current goalhandle to goalHandles_
              goalHandles_.push_back(goal_handle);
              // Get goal id and accepted time stamp
              std::string goalUUID = rclcpp_action::to_string(goal_handle->get_goal_id());

              rclcpp::Node::SharedPtr nodeHandle = MATLAB::getGlobalNodeHandle();
              rclcpp::Time ts = nodeHandle->now();
              auto secinnanos = 1000000000;
              int32_t sec = static_cast<int32_t>(RCL_NS_TO_S(ts.nanoseconds()));
              uint32_t nanosec = static_cast<uint32_t>(ts.nanoseconds() % (secinnanos));
        
              // Write uuid and timestamp to quickAccessGoalHandles_ for quick access
              auto currentGoalHandle = matlabGoalHandle_;
              currentGoalHandle.goalUUID = goalUUID;
              currentGoalHandle.sec = sec;
              currentGoalHandle.nanosec = nanosec;
              lock();
              quickAccessGoalHandles_.push_back(currentGoalHandle);
              cv_.notify_all();
              // Write new key-value to goalUUID-goalIndex map
              updateGoalUUIDMap(goal_handle->get_goal_id());
              goalResponseCallback_();
              unlock();
            }
        }

        /**
         * Feedback callback for sendGoal
         * @param goal_handle - goal handle of the associated goal
         * @param feedback - feedback message shared pointer
         */
        void feedback_callback(typename rclcpp_action::ClientGoalHandle<ActionType>::SharedPtr goal_handle,
                               const std::shared_ptr<const FbMsgType> feedback) {
            lock();
            updateGoalIndexByUUID(goal_handle->get_goal_id());
            msg2struct(feedbackStructPtr_, *feedback.get());
            // call MATLAB function here
            feedbackCallback_();
            unlock();
        }

        /**
         * Result callback for sendGoal
         * @param result - wrapped result of the associated goal
         */
        void result_callback(const typename rclcpp_action::ClientGoalHandle<ActionType>::WrappedResult & result) {
            lock();
            resultCodes_.push_back(int8_t(result.code));
            updateGoalIndexByUUID(result.goal_id);
            const ResultMsgType* tmpResultMsgPtr_ = result.result.get();
            msg2struct(resultStructPtr_, *tmpResultMsgPtr_);
            // call MATLAB function here
            resultCallback_();
            unlock();
        }

        /**
         * Cancel callback for cancelGoal
         * @param cancelResp - cancel response message shared pointer
         */
        void cancel_callback(typename rclcpp_action::Client<ActionType>::CancelResponse::SharedPtr cancelResp) {
            lock();
            msg2struct(cancelRespStructPtr_, *cancelResp.get());
            // call MATLAB function here
            cancelCallback_();
            unlock();
        }

        /**
         * Cancel all callback for cancelAllGoals
         * @param cancelResp - cancel response message shared pointer
         */
        void cancelAll_callback(typename rclcpp_action::Client<ActionType>::CancelResponse::SharedPtr cancelResp) {
            lock();
            msg2struct(cancelRespStructPtr_, *cancelResp.get());
            // call MATLAB function here
            cancelAllCallback_();
            unlock();
        }

        /**
         * Cancel before callback for cancelGoalsBefore
         * @param cancelResp - cancel response message shared pointer
         */
        void cancelBefore_callback(typename rclcpp_action::Client<ActionType>::CancelResponse::SharedPtr cancelResp) {
            lock();
            msg2struct(cancelRespStructPtr_, *cancelResp.get());
            // call MATLAB function here
            cancelBeforeCallback_();
            unlock();
        }

        /**
         * Utility to update a map with key value as goal index and unique id
         * @param goalUUID - unique id of a goal
         */
        void updateGoalUUIDMap(const rclcpp_action::GoalUUID goalUUID) {
            // Add new goalIndex, goalUUID pair into map
            indexUUIDMap_[goalUUID] = currentGoalIndex_;
            goalIndex_ = currentGoalIndex_;
            currentGoalIndex_++;
        }

        /**
         * Utility to update current goal index given unique id
         * @param goalUUID - unique id of a goal
         */
        void updateGoalIndexByUUID(const rclcpp_action::GoalUUID goalUUID) {
            goalIndex_ = indexUUIDMap_[goalUUID];
        }

        /**
         * Pause current thread until goal is ready to access
         * @param goalIndex - index of a goal
         */
        void waitUntilGoalReady(int32_t goalIndex) {
            // This means both goalHandles_ and quickAccessGoalHandles_ are ready
            // While loop is required here to avoid cv_.notify_all triggered by
            // another goal instead of the goal associated with goalIndex.
            while(quickAccessGoalHandles_.size() <= goalIndex) {
                std::unique_lock<std::mutex> lck(mutex_);
                cv_.wait(lck);
            }
        }


  private:
    std::mutex mutex_;
    std::condition_variable cv_;

    GoalStructType* goalStructPtr_;
    FbStructType* feedbackStructPtr_;
    ResultStructType* resultStructPtr_;
    CancelRespStructType* cancelRespStructPtr_;

    std::function<void(void)> goalResponseCallback_;
    std::function<void(void)> feedbackCallback_;
    std::function<void(void)> resultCallback_;
    std::function<void(void)> cancelCallback_;
    std::function<void(void)> cancelBeforeCallback_;
    std::function<void(void)> cancelAllCallback_;

    std::shared_ptr<GoalMsgType> goalMsgPtr_ = std::make_shared<GoalMsgType>();

    typename rclcpp_action::Client<ActionType>::SharedPtr client_;
    int32_t currentGoalIndex_;
    int32_t goalIndex_;
    int32_t cancelGoalIndex_;
    std::map<rclcpp_action::GoalUUID,int32_t> indexUUIDMap_;
    std::vector<typename rclcpp_action::ClientGoalHandle<ActionType>::SharedPtr> goalHandles_;
    struct MATLABROS2GoalHandle {
    std::string goalUUID = "";
    int32_t     sec = int32_t(0);
    uint32_t    nanosec = uint32_t(0);
    } matlabGoalHandle_;
    std::vector<MATLABROS2GoalHandle> quickAccessGoalHandles_;
    std::vector<int8_t> resultCodes_;
};

#endif