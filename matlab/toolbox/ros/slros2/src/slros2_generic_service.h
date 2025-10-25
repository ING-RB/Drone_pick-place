/* Copyright 2022-2025 The MathWorks, Inc. */

#ifndef _SLROS2_GENERIC_SERVICE_H_
#define _SLROS2_GENERIC_SERVICE_H_

#include <iostream>
#include <chrono>
#include <future>
#include <functional>
#include "rclcpp/rclcpp.hpp"
#include "slros_busmsg_conversion.cpp"
#include <mutex>
#include <condition_variable>

#ifndef _SL_ROS2_CONTROL_PLUGIN_
// Use shared pointer for standard/component node generation
extern rclcpp::Node::SharedPtr SLROSNodePtr;
#endif

#ifdef _SL_ROS2_CONTROL_PLUGIN_
// Use lifecycle node for ROS 2 control plugin generation
#include "rclcpp_lifecycle/lifecycle_node.hpp"
extern rclcpp_lifecycle::LifecycleNode::SharedPtr SLROSNodePtr;
#endif

/**
 * Class for ROS 2 service client in C++.
 *
 * This class is used by code generated from the Simulink ROS 2
 * "Call Service" blocks and is templatized by the ROS 2 service type and
 * the Simulink bus types for the request and response messages.
 */
template <class SrvType, class ReqBusType, class RespBusType>
class SimulinkServiceCaller {
  public:
    void createServiceCaller(const std::string& serviceName,
                                const rmw_qos_profile_t& qosProfile);
    bool waitForServer(const double connectionTimeout);
    uint8_t call(const ReqBusType* reqBusPtr, RespBusType* respBusPtr);
    void resetSvcClientPtr(){
        _svcClient.reset();
    }
  private:
    std::shared_ptr<rclcpp::Client<SrvType>> _svcClient; ///< The ROS 2 service client object
    std::mutex _srvMtx;
};

/**
 * Create a ROS 2 service client
 *
 * @param[in] serviceName The name of the service to call
 * @param[in] qosProfile QoS settings for the service client
 */
template <class SrvType, class ReqBusType, class RespBusType>
void SimulinkServiceCaller<SrvType, ReqBusType, RespBusType>::createServiceCaller(
    const std::string& serviceName,const rmw_qos_profile_t& qosProfile) {
    
	#ifdef ROS2_DISTRO_JAZZY //in jazzy
	    rclcpp::QoS qosProf(rclcpp::QoSInitialization::from_rmw(qosProfile));
        _svcClient = SLROSNodePtr->create_client<SrvType>(serviceName, qosProf);
    #else //before jazzy
        _svcClient = SLROSNodePtr->create_client<SrvType>(serviceName, qosProfile);
    #endif
}

/**
 * Wait for the service client to connect to the service server
 *
 * @param connectionTimeout Timeout for the server to wait for connection
 * @retval 0 The call to the service succeeded and we have a valid response
 * @retval 1 Server could not respond
 */

template <class SrvType, class ReqBusType, class RespBusType>
bool SimulinkServiceCaller<SrvType, ReqBusType, RespBusType>::waitForServer
(const double connectionTimeout){
    return _svcClient->wait_for_service(std::chrono::duration<double>(connectionTimeout));
}

/**
 * Call the service and receive a response
 *
 * @param reqBusPtr[in] Pointer to the bus structure for the request message
 * @param respBusPtr[out] Pointer to the bus structure for the response message
 * @retval 0 The call to the service succeeded and we have a valid response
 * @retval 2 Something bad happened
 */
template <class SrvType, class ReqBusType, class RespBusType>
uint8_t SimulinkServiceCaller<SrvType, ReqBusType, RespBusType>::call(const ReqBusType* inBus, RespBusType* outBus){
    std::lock_guard<std::mutex> lockSrv(_srvMtx);
    auto msg = std::make_shared<typename SrvType::Request>();
    convertFromBus(*msg, inBus);
    auto result = _svcClient->async_send_request(std::move(msg));
    // Wait for result
    std::future_status status = result.wait_for(std::chrono::seconds((int)1e9));
    if (status != std::future_status::ready) {
        return 2;
    }
    convertToBus(outBus, *result.get().get());
    return 0;
}

/**
 * Class for ROS 2 service server in C++.
 *
 * This class is used by code generated from the Simulink ROS 2
 * "Receive Service Request" blocks and is templated by the ROS 2
 * service type and the Simulink bus types for the request and
 * response messages.
 */
template <class SrvType, class ReqBusType, class RespBusType>
class SimulinkServiceServer {
    public:
        void createServiceServer(const std::string& serviceName,
                                    const rmw_qos_profile_t& qosProfile);
        bool getCurrentRequest(ReqBusType* reqBusPtr);
        void sendResponse(const RespBusType* respBusPtr);
        void resetSvcServerPtr(){
            _svcServer.reset();
        }
    private:
        std::shared_ptr<rclcpp::Service<SrvType>> _svcServer; // The ROS 2 service server object
        std::mutex _srvMtx;
        std::condition_variable _responseRecvCond;            // condition variable for waiting response
        std::shared_ptr<typename SrvType::Request> _currentRequest;
        std::shared_ptr<typename SrvType::Response> _currentResponse;
        bool _isRequestNew;
        int32_t _numOfRequests;
        rclcpp::CallbackGroup::SharedPtr _SvcServerCbGroup; ///< The callback group for service server
};

/**
 * Create a ROS 2 service server
 *
 * @param[in] serviceName The name of the service
 * @param[in] qosProfile QoS settings for the service server
 */
template <class SrvType, class ReqBusType, class RespBusType>
void SimulinkServiceServer<SrvType, ReqBusType, RespBusType>::createServiceServer(
    const std::string& serviceName, const rmw_qos_profile_t& qosProfile) {

        auto serviceCallback = [this](const std::shared_ptr<typename SrvType::Request> reqMsgPtr,
                                        std::shared_ptr<typename SrvType::Response> respMsgPtr) {
            _currentRequest = reqMsgPtr;
            _currentResponse = respMsgPtr;
            _isRequestNew = true;
            _numOfRequests++;
            std::unique_lock<std::mutex> lck(_srvMtx);
            _responseRecvCond.wait(lck);
        };

        _SvcServerCbGroup = SLROSNodePtr->create_callback_group(rclcpp::CallbackGroupType::Reentrant);
	  #ifdef ROS2_DISTRO_JAZZY //in jazzy
	    rclcpp::QoS qosProf(rclcpp::QoSInitialization::from_rmw(qosProfile));
        _svcServer = SLROSNodePtr->create_service<SrvType>(serviceName, serviceCallback, qosProf, _SvcServerCbGroup);
      #else //before jazzy
        _svcServer = SLROSNodePtr->create_service<SrvType>(serviceName, serviceCallback, qosProfile, _SvcServerCbGroup);
      #endif
        _isRequestNew = false;
        _numOfRequests = 0;
}

/**
 * Get the current Request and return to MATLAB
 *
 * @param[in] reqBusPtr Request bus message
 */
template <class SrvType, class ReqBusType, class RespBusType>
bool SimulinkServiceServer<SrvType, ReqBusType, RespBusType>::getCurrentRequest(ReqBusType* reqBusPtr){
    bool isNew = false;
    if (_isRequestNew) {
        isNew = true;
        // Reset to false since current request has been processed
        _isRequestNew = false;
        convertToBus(reqBusPtr, *_currentRequest.get());
    }
    return isNew;
}

/**
 * Send response to client
 *
 * @param[in] respBusPtr Response bus message
 */
template <class SrvType, class ReqBusType, class RespBusType>
void SimulinkServiceServer<SrvType, ReqBusType, RespBusType>::sendResponse(const RespBusType* respBusPtr){
    if (_numOfRequests>0){
        _numOfRequests--;
        convertFromBus(*_currentResponse, respBusPtr);
        std::unique_lock<std::mutex> lck(_srvMtx);
        _responseRecvCond.notify_all();
    }
}

#endif
