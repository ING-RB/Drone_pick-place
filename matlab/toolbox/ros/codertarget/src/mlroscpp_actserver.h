// Copyright 2022 The MathWorks, Inc.
#ifndef _MLROSCPP_ACTSERVER_H_
#define _MLROSCPP_ACTSERVER_H_

#include <iostream>
#include <memory>                                   // For std::unique_ptr
#include <ros/ros.h>
#include <actionlib/server/simple_action_server.h>  // For actionlib
#include "ros_structmsg_conversion.h"               // For msg2struct()
#include <string.h>                                 // For std::string
#include <functional>                               // For std::function
#include <mutex>

#define MATLABActServer_createActServer(obj, mlActName, mlActSize) \
    obj->createActServer(mlActName, mlActSize)
#define MATLABActServer_mlSetAborted(obj) obj->mlSetAborted()
#define MATLABActServer_mlSetPreempted(obj) obj->mlSetPreempted()
#define MATLABActServer_mlSetSucceeded(obj, resultMsgStruct) \
    obj->mlSetSucceeded(resultMsgStruct)
#define MATLABActServer_mlPublishFeedback(obj, feedbackMsgStruct) \
    obj->mlPublishFeedback(feedbackMsgStruct)
#define MATLABActServer_mlIsNewGoalAvailable(obj) obj->mlIsNewGoalAvailable()
#define MATLABActServer_mlIsPreemptRequested(obj) obj->mlIsPreemptRequested()
#define MATLABActServer_lock(obj) obj->lock()
#define MATLABActServer_unlock(obj) obj->unlock()


template <class ActionType,
          class GoalMsgType,
          class FeedbackMsgType,
          class ResultMsgType,
          class GoalStructType,
          class FeedbackStructType,
          class ResultStructType>
class MATLABActServer {
  private:
    std::mutex mutex_;
    ros::NodeHandle nh_;
    std::shared_ptr<actionlib::SimpleActionServer<ActionType>> server_;
    std::function<void(void)> executeGoalCallback_;
    ResultMsgType resultMsg_;
    FeedbackMsgType feedbackMsg_;
    GoalStructType* goalStructPtr_;
    FeedbackStructType* feedbackStructPtr_;
    ResultStructType* resultStructPtr_;
  
  public:
    MATLABActServer(std::function<void(void)> executeGoalCallback,
                    GoalStructType* goalStructPtr,
                    FeedbackStructType* feedbackStructPtr,
                    ResultStructType* resultStructPtr)
       : executeGoalCallback_{executeGoalCallback}
       , goalStructPtr_{goalStructPtr}
       , feedbackStructPtr_{feedbackStructPtr}
       , resultStructPtr_{resultStructPtr} {}

    ~MATLABActServer(){
        server_->shutdown();
    }
 
    /**
     * Creates an action server and register it on the ROS network.
     * @param mlActName - action server name retrieved from MATLAB
     * @param mlActSize - the length of the action server name
     */
    void createActServer(const char* mlActName, size_t mlActSize) {
        std::string actname(mlActName, mlActSize);
        server_ = std::make_shared<actionlib::SimpleActionServer<ActionType>>(nh_, actname, boost::bind(&MATLABActServer::executeGoalCb, this, _1), false);
        server_->start();
    }

    /**
     * Callback function for goal execution.
     * @param goal - goal message
     */
    void executeGoalCb(boost::shared_ptr<const GoalMsgType> goal) {
        lock();
        msg2struct(goalStructPtr_, goal.get());
        unlock();
        executeGoalCallback_();
    }

    /**
     * Set goal status for current goal to aborted.
     */
    void mlSetAborted(){
        server_->setAborted();
    }

    /**
     * Set goal status for current goal to preempted.
     */
    void mlSetPreempted(){
        server_->setPreempted();
    }

    /**
     * Set goal status for current goal to succeeded.
     * @param resultMsgStruct - result message struct from MATLAB
     */
    void mlSetSucceeded(ResultStructType resultMsgStruct){
        resultStructPtr_ = &resultMsgStruct;
        lock();
        struct2msg(&resultMsg_, resultStructPtr_);
        unlock();
        server_->setSucceeded(resultMsg_);
    }

    /**
     * Publish feedback message to action client
     * @param feedbackMsgStruct - feedback message struct from MATLAB
     */
    void mlPublishFeedback(FeedbackStructType feedbackMsgStruct){
        feedbackStructPtr_ = &feedbackMsgStruct;
        lock();
        struct2msg(&feedbackMsg_, feedbackStructPtr_);
        unlock();
        server_->publishFeedback(feedbackMsg_);
    }

    /**
     * Evaluate whether a new goal is available
     */
    bool mlIsNewGoalAvailable(){
        return server_->isNewGoalAvailable();
    }

    /**
     * Evaluate whether a preempt is requested
     */
    bool mlIsPreemptRequested(){
        return server_->isPreemptRequested();
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
};

#endif