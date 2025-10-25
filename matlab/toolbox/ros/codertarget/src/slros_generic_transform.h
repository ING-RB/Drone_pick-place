/* Copyright 2023 The MathWorks, Inc. */

#ifndef _SLROS_GENERIC_TRANSFORM_H_
#define _SLROS_GENERIC_TRANSFORM_H_

#include <iostream>
#include "ros/ros.h"
#include "tf2_ros/buffer.h"
#include <tf2_ros/transform_listener.h>

#include "slros_busmsg_conversion.h"

/**
 * Class for ROS Transformation in C++.
 *
 * This class is used by code generated from the Simulink ROS
 * "Get Transform" blocks.
 */
template <class BusType>
class SimulinkTransform {
  public:
  	void createTfTree();
  	bool canTransform(const std::string& targetFrame,
  		              const std::string& sourceFrame);
  	void getTransform(BusType* busPtr,
  					  const std::string& targetFrame,
  		              const std::string& sourceFrame);
  	bool getCacheTime(uint32_t* sec, uint32_t* nSec);
  private:
  	std::shared_ptr<ros::NodeHandle> mOptionalDefaultNode_;
  	std::shared_ptr<tf2_ros::Buffer> mTFBuffer_{nullptr};
  	std::shared_ptr<tf2_ros::TransformListener> mTFListener_{nullptr};
};

/**
 * Create a ROS 2 Transformation Tree
 */
template <class BusType>
inline void SimulinkTransform<BusType>::createTfTree(){
	// TransformerListener constructor expects a temporary node.
	mOptionalDefaultNode_ = std::make_shared<ros::NodeHandle>();
	// Set the default buffer time to 10s
    uint32_t sec = 10;
    uint32_t nSec = 0;

    // Get current cache time
    uint32_t currentSec, currentNsec;
    if (getCacheTime(&currentSec, &currentNsec) && (currentSec == sec) &&
        (currentNsec == nSec)) {
        // if everything is equal, return;
        return;
    }

    // Otherwise, create new buffer and new listener with the new cache time
    ros::Duration d(sec, nSec);
    mTFBuffer_ = std::make_shared<tf2_ros::Buffer>(d);
    mTFListener_ = std::make_shared<tf2_ros::TransformListener>(*mTFBuffer_, *mOptionalDefaultNode_);
}

/**
 * Test if a transform is possible
 *
 * @param targetFrame target frame name
 * @param sourceFrame source frame name
 */
template <class BusType>
inline bool SimulinkTransform<BusType>::canTransform(const std::string& targetFrame,
					const std::string& sourceFrame) {
	bool isAvailable =
		mTFBuffer_->canTransform(targetFrame, sourceFrame,
								 ros::Time(0,0), ros::Duration(0,0));
	return isAvailable;
}

/**
 * Get the transform between two frames by frame ID.
 * @param busPtr pointer to bus structure for the TransformStamped message
 * @param targetFrame target frame name
 * @param sourceFrame source frame name
 */
template <class BusType>
inline void SimulinkTransform<BusType>::getTransform(BusType* busPtr,
					const std::string& targetFrame,
  		            const std::string& sourceFrame) {
	// Check if listener and buffer are initialized. Else throw ROS_ERROR
    if (!mTFBuffer_.get() || !mTFListener_.get()) {
        ROS_ERROR("Transformation-Listener is not initialized properly.");
    }

    // Return empty transformStamped message if there is no valid transformation in Network
    try {
    	geometry_msgs::TransformStamped tfStampedMsg = mTFBuffer_->lookupTransform(
    		targetFrame, sourceFrame, ros::Time(0,0),
    		ros::Duration(0,0));
    	convertToBus(busPtr, &tfStampedMsg);
    } catch (...) {
    }
}

/**
* Get the cache time of the transformation buffer
* @param sec sec field of cache time
* @param nSec nanosec field of cache time
*/
template <class BusType>
inline bool SimulinkTransform<BusType>::getCacheTime(uint32_t* sec, uint32_t* nSec){
	if (mTFBuffer_.get() && mTFListener_.get()) {
		ros::Duration d = mTFBuffer_->getCacheLength();
		*sec = d.sec;
		*nSec = d.nsec;
		return true;
	}
	return false;
}
#endif