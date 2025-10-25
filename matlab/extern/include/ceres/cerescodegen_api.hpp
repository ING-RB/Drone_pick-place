/* Copyright 2022-2024 The MathWorks, Inc. */
#ifndef CERESCODEGEN_API_HPP
#define CERESCODEGEN_API_HPP

#ifdef BUILDING_LIBMWCERESCODEGEN
    #include "cerescodegen/cerescodegen_spec.hpp"
#else
    /* To deal with the fact that PackNGo has no include file hierarchy during test */
    #include "cerescodegen_spec.hpp"
#endif

/** Construct mw_ceres::FactorIMU object and returns its pointer. **/
EXTERN_C CERESCODEGEN_API void* cerescodegen_constructIMUFactor(int32_T* ids,
                        real64_T sampleRate,
                        real64_T* gravityAcceleration,
                        real64_T* gyroBiasNoise,
                        real64_T* accelBiasNoise,
                        real64_T* gyroNoise,
                        real64_T* accelNoise,
                        real64_T* gyroReadings,
                        real64_T* accelReadings, 
                        real64_T numReadings, 
                        real64_T* sensorTransform);

/** Construct mw_ceres::FactorIMUGS object and returns its pointer. **/
EXTERN_C CERESCODEGEN_API void* cerescodegen_constructIMUGSFactor(int32_T* ids,
                        real64_T sampleRate,
                        real64_T* gravityAcceleration,
                        real64_T* gyroBiasNoise,
                        real64_T* accelBiasNoise,
                        real64_T* gyroNoise,
                        real64_T* accelNoise,
                        real64_T* gyroReadings,
                        real64_T* accelReadings, 
                        real64_T numReadings, 
                        real64_T* sensorTransform);


/** Construct mw_ceres::FactorIMUGST object and returns its pointer. **/
EXTERN_C CERESCODEGEN_API void* cerescodegen_constructIMUGSTFactor(int32_T* ids,
                        real64_T sampleRate,
                        real64_T* gravityAcceleration,
                        real64_T* gyroBiasNoise,
                        real64_T* accelBiasNoise,
                        real64_T* gyroNoise,
                        real64_T* accelNoise,
                        real64_T* gyroReadings,
                        real64_T* accelReadings, 
                        real64_T numReadings, 
                        real64_T* sensorTransform);

/** Destruct mw_ceres::FactorIMU**/
EXTERN_C CERESCODEGEN_API void cerescodegen_destructIMUFactor(void* objPtr);

/** Destruct mw_ceres::FactorIMUGS**/
EXTERN_C CERESCODEGEN_API void cerescodegen_destructIMUGSFactor(void* objPtr);

/** Destruct mw_ceres::FactorIMUGST**/
EXTERN_C CERESCODEGEN_API void cerescodegen_destructIMUGSTFactor(void* objPtr);

/** Predict the Pose and Velocity. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_predictIMU(void* objPtr, const real64_T* prevBias,
                                                       const real64_T* prevPose, const real64_T* prevVel,
                                                       real64_T* predictedPose, real64_T* predictedVel);

/** Predict the Pose and Velocity. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_predictIMUGST(void* objPtr, const real64_T* prevBias,
                                                       const real64_T* prevPose, const real64_T* prevVel,
                                                       const real64_T* gRot, const real64_T* scale, const real64_T* sensorTform, 
                                                       real64_T* predictedPose, real64_T* predictedVel); 

/** Construct mw_ceres::FactorGraph object and returns its pointer. **/
EXTERN_C CERESCODEGEN_API void* cerescodegen_constructFactorGraph();

/** Destruct mw_ceres::FactorGraph**/
EXTERN_C CERESCODEGEN_API void cerescodegen_destructFactorGraph(void* objPtr);

/** Get factor graph node ids. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_getNodeIDs(void* objPtr, real64_T* output, real64_T* outputLen, const int32_T* groupID, const int32_T numgroupID,
    const char_T* nodeType, const int32_T nodeTypeLen, const char_T* factorType, const int32_T factorTypeLen);

/** Add imu factor to factor graph **/
EXTERN_C CERESCODEGEN_API real64_T cerescodegen_addFactorIMU(void* objPtr, int32_T* ids,
                        real64_T sampleRate,
                        real64_T* gravityAcceleration,
                        real64_T* gyroBiasNoise,
                        real64_T* accelBiasNoise,
                        real64_T* gyroNoise,
                        real64_T* accelNoise,
                        real64_T* gyroReadings,
                        real64_T* accelReadings, 
                        real64_T numReadings,
                        const int32_T* groupIds,
                        const int32_T numGroupIds,
                        real64_T* sensorTransform);

/** Add imu factor connecting gravity and scale nodes to factor graph **/
EXTERN_C CERESCODEGEN_API real64_T cerescodegen_addFactorIMUGS(void* objPtr, int32_T* ids,
                        real64_T sampleRate,
                        real64_T* gravityAcceleration,
                        real64_T* gyroBiasNoise,
                        real64_T* accelBiasNoise,
                        real64_T* gyroNoise,
                        real64_T* accelNoise,
                        real64_T* gyroReadings,
                        real64_T* accelReadings, 
                        real64_T numReadings,
                        const int32_T* groupIds,
                        const int32_T numGroupIds,
                        real64_T* sensorTransform);

/** Add imu factor connecting gravity, scale and sensor transform nodes to factor graph **/
EXTERN_C CERESCODEGEN_API real64_T cerescodegen_addFactorIMUGST(void* objPtr, int32_T* ids,
                        real64_T sampleRate,
                        real64_T* gravityAcceleration,
                        real64_T* gyroBiasNoise,
                        real64_T* accelBiasNoise,
                        real64_T* gyroNoise,
                        real64_T* accelNoise,
                        real64_T* gyroReadings,
                        real64_T* accelReadings, 
                        real64_T numReadings,
                        const int32_T* groupIds,
                        const int32_T numGroupIds,
                        real64_T* sensorTransform);

/** Add gaussian noise model factor to factor graph**/
EXTERN_C CERESCODEGEN_API void cerescodegen_addFactorGaussianNoiseModel(void* objPtr, const char_T* factorType, const int32_T factorTypeLen,
    const int32_T* ids, const int32_T numIds, const real64_T* measurement, const int32_T numMeasurement, const real64_T* information,
    const int32_T numInformation, const int32_T numFactors, const int32_T* groupIds, const int32_T numGroupIds, real64_T* output, real64_T* outputLen);

/** Add camera projection factor to factor graph**/
EXTERN_C CERESCODEGEN_API void cerescodegen_addFactorCameraProjection(void* objPtr, const char_T* factorType, const int32_T factorTypeLen,
    const int32_T* ids, const int32_T numIds, const real64_T* measurement, const int32_T numMeasurement, const real64_T* information,
    const int32_T numInformation, const int32_T numFactors, const int32_T* groupIds, const int32_T numGroupIds, real64_T* sensorTform, real64_T* output, real64_T* outputLen);

/** Add distorted camera projection factor to factor graph**/
EXTERN_C CERESCODEGEN_API void cerescodegen_addFactorDistortedCameraProjection(void* objPtr, const char_T* factorType, const int32_T factorTypeLen,
    const int32_T* ids, const int32_T numIds, const real64_T* measurement, const int32_T numMeasurement, const real64_T* information,
    const int32_T numInformation, const int32_T numFactors, const real64_T* intrinsic, const int32_T numIntrinsic, const real64_T* sensorTransform, const int32_T numSensorTransform, const int32_T* groupIds, const int32_T numGroupIds, real64_T* output, real64_T* outputLen);

/** Get number of nodes added to factor graph. **/
EXTERN_C CERESCODEGEN_API real64_T cerescodegen_getNumNodes(void* objPtr);

/** Get number of factors added to factor graph . **/
EXTERN_C CERESCODEGEN_API real64_T cerescodegen_getNumFactors(void* objPtr);

/** Get state of factor graph node**/
EXTERN_C CERESCODEGEN_API void cerescodegen_getNodeState(void* objPtr, const int32_T* vid, int32_T vidNum, real64_T* state, real64_T* stateLen);

/** Get type of factor graph node. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_getNodeType(void* objPtr, const real64_T vid, char_T* type, real64_T* typeLen);

/** Get covariance of factor graph node. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_getNodeCovariance(void* objPtr, const int32_T* vid, int32_T vidNum, real64_T* covariance, real64_T* covarianceLen);

/** Set factor graph node state. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_setNodeState(void* objPtr, const int32_T* vid, int32_T vidNum, real64_T* state, int32_T stateLen,
    real64_T* output, real64_T* outputLen);

/** Remove factors. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_removeFactor(void* objPtr, const int32_T* vid, int32_T vidNum, real64_T* output, real64_T* outputLen);

/** Remove nodes. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_removeNode(void* objPtr, const int32_T* vid, int32_T vidNum, real64_T* output, real64_T* outputLen);

/** Marginalize factors. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_marginalizeFactor(void* objPtr, const int32_T* vid, int32_T vidNum, real64_T* output, real64_T* outputLen);

/** Marginalize nodes. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_marginalizeNode(void* objPtr, int32_T vid, real64_T* output, real64_T* outputLen);

/** Fix factor graph node. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_fixNode(void* objPtr, const int32_T* vid, int32_T vidNum, real64_T* output, real64_T* outputLen);

/** Free factor graph node. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_freeNode(void* objPtr, const int32_T* vid, int32_T vidNum, real64_T* output, real64_T* outputLen);

/** Query if factor graph node is fixed. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_isNodeFixed(void* objPtr, const int32_T* vid, int32_T vidNum, real64_T* output, real64_T* outputLen);

/** Query if factor graph has the specified node**/
EXTERN_C CERESCODEGEN_API boolean_T cerescodegen_hasNode(void* objPtr, const real64_T vid);

/** Query if the factor graph is connected. **/
EXTERN_C CERESCODEGEN_API boolean_T cerescodegen_isConnected(void* objPtr, const int32_T* vid, int32_T vidNum);

/** Query if the given node is pose type. **/
EXTERN_C CERESCODEGEN_API boolean_T cerescodegen_isPoseNode(void* objPtr, const int32_T* vid, int32_T vidNum);

/** Optimize factor graph. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_optimize(void* objPtr, real64_T* opts, real64_T* solInfo, int32_T* vid, int32_T vidNum,
    int32_T covarianceTypeNum, real64_T* OptimizedIDs, real64_T* OptimizedIDsLen, real64_T* FixedIDs, real64_T* FixedIDsLen);

#endif
