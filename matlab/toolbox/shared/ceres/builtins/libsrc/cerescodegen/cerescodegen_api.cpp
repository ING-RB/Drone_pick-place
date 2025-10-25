// Copyright 2021-2024 The MathWorks, Inc.
#ifdef BUILDING_LIBMWCERESCODEGEN
    #include "cerescodegen/cerescodegen_api.hpp"
    #include "cerescodegen/factor_graph.hpp"
    #include "cerescodegen/rosenbrock.hpp"
    #include "cerescodegen/imu_factor.hpp"
    #include "cerescodegen/marginal_factor.hpp"
#else
    /* To deal with the fact that PackNGo has no include file hierarchy during test */
    #include "cerescodegen_api.hpp"
    #include "rosenbrock.hpp"
    #include "imu_factor.hpp"
    #include "factor_graph.hpp"
    #include "marginal_factor.hpp"
    
    #include <vector>
    #include <string>
    #include <unordered_map>
#endif

void* cerescodegen_constructIMUFactor(int32_T* ids,
                        real64_T sampleRate,
                        real64_T* gravityAcceleration,
                        real64_T* gyroBiasNoise,
                        real64_T* accelBiasNoise,
                        real64_T* gyroNoise,
                        real64_T* accelNoise,
                        real64_T* gyroReadings,
                        real64_T* accelReadings, 
                        real64_T numReadings,
                        real64_T* sensorTransform) {
    // returns the pointer 
    return static_cast<void*>(new mw_ceres::FactorIMU(ids, sampleRate,
                gravityAcceleration,
                gyroBiasNoise,
                accelBiasNoise,
                gyroNoise,
                accelNoise,
                gyroReadings,
                accelReadings,
                static_cast<size_t>(numReadings), 
                sensorTransform));
}

void* cerescodegen_constructIMUGSFactor(int32_T* ids,
                        real64_T sampleRate,
                        real64_T* gravityAcceleration,
                        real64_T* gyroBiasNoise,
                        real64_T* accelBiasNoise,
                        real64_T* gyroNoise,
                        real64_T* accelNoise,
                        real64_T* gyroReadings,
                        real64_T* accelReadings, 
                        real64_T numReadings,
                        real64_T* sensorTransform) {
    // returns the pointer 
    return static_cast<void*>(new mw_ceres::FactorIMUGS(ids, sampleRate,
                gravityAcceleration,
                gyroBiasNoise,
                accelBiasNoise,
                gyroNoise,
                accelNoise,
                gyroReadings,
                accelReadings,
                static_cast<size_t>(numReadings), 
                sensorTransform));
}

void cerescodegen_predictIMU(void* objPtr, const real64_T* prevBias, const real64_T* prevPose, const real64_T* prevVel,
            real64_T* predictedPose, real64_T* predictedVel) {
    mw_ceres::FactorIMU* factorObjPtr = static_cast<mw_ceres::FactorIMU*>(objPtr);
    factorObjPtr->predict(prevBias, prevPose, prevVel, predictedPose, predictedVel);
}

void cerescodegen_destructIMUFactor(void* objPtr) {
    mw_ceres::FactorIMU* factorObjPtr = static_cast<mw_ceres::FactorIMU*>(objPtr);
    if (factorObjPtr != nullptr) {
        delete factorObjPtr;
    }
}

void cerescodegen_destructIMUGSFactor(void* objPtr) {
    mw_ceres::FactorIMUGS* factorObjPtr = static_cast<mw_ceres::FactorIMUGS*>(objPtr);
    if (factorObjPtr != nullptr) {
        delete factorObjPtr;
    }
}

void* cerescodegen_constructIMUGSTFactor(int32_T* ids,
                        real64_T sampleRate,
                        real64_T* gravityAcceleration,
                        real64_T* gyroBiasNoise,
                        real64_T* accelBiasNoise,
                        real64_T* gyroNoise,
                        real64_T* accelNoise,
                        real64_T* gyroReadings,
                        real64_T* accelReadings, 
                        real64_T numReadings,
                        real64_T* sensorTransform) {
    // returns the pointer 
    return static_cast<void*>(new mw_ceres::FactorIMUGST(ids, sampleRate,
                gravityAcceleration,
                gyroBiasNoise,
                accelBiasNoise,
                gyroNoise,
                accelNoise,
                gyroReadings,
                accelReadings,
                static_cast<size_t>(numReadings), 
                sensorTransform));
}

void cerescodegen_predictIMUGST(void* objPtr, const real64_T* prevBias, const real64_T* prevPose, const real64_T* prevVel,
            const real64_T* gRot, const real64_T* scale, const real64_T* sensorTform, real64_T* predictedPose, real64_T* predictedVel) {
    mw_ceres::FactorIMUGST* factorObjPtr = static_cast<mw_ceres::FactorIMUGST*>(objPtr);
    factorObjPtr->predict(prevBias, prevPose, prevVel, gRot, scale, sensorTform, predictedPose, predictedVel);
}

void cerescodegen_destructIMUGSTFactor(void* objPtr) {
    mw_ceres::FactorIMU* factorObjPtr = static_cast<mw_ceres::FactorIMU*>(objPtr);
    if (factorObjPtr != nullptr) {
        delete factorObjPtr;
    }
}

void* cerescodegen_constructFactorGraph(){
    return static_cast<void*>(new mw_ceres::FactorGraph());
}

void cerescodegen_destructFactorGraph(void* objPtr){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    if (graphObjPtr != nullptr) {
        delete graphObjPtr;
    }
}

EXTERN_C CERESCODEGEN_API void cerescodegen_getNodeIDs(void* objPtr, real64_T* output, real64_T* outputLen, const int32_T* groupID, const int32_T numgroupID,
    const char_T* nodeType, const int32_T nodeTypeLen, const char_T* factorType, const int32_T factorTypeLen){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    graphObjPtr->getVariableIDsArray(output, outputLen, groupID, static_cast<size_t>(numgroupID), nodeType, static_cast<size_t>(nodeTypeLen),
        factorType, static_cast<size_t>(factorTypeLen));
}

EXTERN_C CERESCODEGEN_API real64_T cerescodegen_addFactorIMU(void* objPtr,int32_T* ids,
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
                        real64_T* sensorTransform) {
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    std::unique_ptr<mw_ceres::Factor> factorObjPtr(static_cast<mw_ceres::Factor*>(new mw_ceres::FactorIMU(ids, sampleRate,
                gravityAcceleration,
                gyroBiasNoise,
                accelBiasNoise,
                gyroNoise,
                accelNoise,
                gyroReadings,
                accelReadings,
                static_cast<size_t>(numReadings), 
                sensorTransform)));
    int fId = graphObjPtr->storeIMUArray(std::move(factorObjPtr), groupIds, static_cast<size_t>(numGroupIds));

    return static_cast<real64_T>(fId);
}

EXTERN_C CERESCODEGEN_API real64_T cerescodegen_addFactorIMUGS(void* objPtr,int32_T* ids,
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
                        real64_T* sensorTransform) {
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    std::unique_ptr<mw_ceres::Factor> factorObjPtr(static_cast<mw_ceres::Factor*>(new mw_ceres::FactorIMUGS(ids, sampleRate,
                gravityAcceleration,
                gyroBiasNoise,
                accelBiasNoise,
                gyroNoise,
                accelNoise,
                gyroReadings,
                accelReadings,
                static_cast<size_t>(numReadings), 
                sensorTransform)));
    int fId = graphObjPtr->storeIMUArray(std::move(factorObjPtr), groupIds, static_cast<size_t>(numGroupIds));

    return static_cast<real64_T>(fId);
}

EXTERN_C CERESCODEGEN_API real64_T cerescodegen_addFactorIMUGST(void* objPtr,int32_T* ids,
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
                        real64_T* sensorTransform) {
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    std::unique_ptr<mw_ceres::Factor> factorObjPtr(static_cast<mw_ceres::Factor*>(new mw_ceres::FactorIMUGST(ids, sampleRate,
                gravityAcceleration,
                gyroBiasNoise,
                accelBiasNoise,
                gyroNoise,
                accelNoise,
                gyroReadings,
                accelReadings,
                static_cast<size_t>(numReadings), 
                sensorTransform)));
    int fId = graphObjPtr->storeIMUArray(std::move(factorObjPtr), groupIds, static_cast<size_t>(numGroupIds));

    return static_cast<real64_T>(fId);
}

/** Add gaussian noise model factor to factor graph**/
EXTERN_C CERESCODEGEN_API void cerescodegen_addFactorGaussianNoiseModel(void* objPtr, const char_T* factorType, const int32_T factorTypeLen,
    const int32_T* ids, const int32_T numIds, const real64_T* measurement, const int32_T numMeasurement, const real64_T* information,
    const int32_T numInformation, const int32_T numFactors, const int32_T* groupIds, const int32_T numGroupIds, real64_T* output, real64_T* outputLen){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    graphObjPtr->addGaussianFactorArray(factorType,static_cast<size_t>(factorTypeLen),ids,static_cast<size_t>(numIds),measurement,static_cast<size_t>(numMeasurement),information,
        static_cast<size_t>(numInformation),static_cast<size_t>(numFactors),groupIds,static_cast<size_t>(numGroupIds),output,outputLen);
}

/** Add camera projection factor to factor graph**/
EXTERN_C CERESCODEGEN_API void cerescodegen_addFactorCameraProjection(void* objPtr, const char_T* factorType, const int32_T factorTypeLen,
    const int32_T* ids, const int32_T numIds, const real64_T* measurement, const int32_T numMeasurement, const real64_T* information,
    const int32_T numInformation, const int32_T numFactors, const int32_T* groupIds, const int32_T numGroupIds, real64_T* sensorTform, real64_T* output, real64_T* outputLen){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    graphObjPtr->addCameraProjectionFactorArray(factorType,static_cast<size_t>(factorTypeLen),ids,static_cast<size_t>(numIds),measurement,static_cast<size_t>(numMeasurement),information,
        static_cast<size_t>(numInformation),static_cast<size_t>(numFactors),groupIds,static_cast<size_t>(numGroupIds), sensorTform, output,outputLen);
}

/** Add camera projection factor to factor graph**/
EXTERN_C CERESCODEGEN_API void cerescodegen_addFactorDistortedCameraProjection(void* objPtr, const char_T* factorType, const int32_T factorTypeLen,
    const int32_T* ids, const int32_T numIds, const real64_T* measurement, const int32_T numMeasurement, const real64_T* information,
    const int32_T numInformation, const int32_T numFactors, const real64_T* intrinsic, const int32_T numIntrinsic, const real64_T* sensorTransform, const int32_T numSensorTransform,const int32_T* groupIds, const int32_T numGroupIds, real64_T* output, real64_T* outputLen){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    graphObjPtr->addDistortedCameraProjectionFactorArray(factorType,static_cast<size_t>(factorTypeLen),ids,static_cast<size_t>(numIds),measurement,static_cast<size_t>(numMeasurement),information,
        static_cast<size_t>(numInformation),static_cast<size_t>(numFactors),intrinsic,static_cast<size_t>(numIntrinsic),sensorTransform,static_cast<size_t>(numSensorTransform),groupIds,static_cast<size_t>(numGroupIds), output,outputLen);
}

/** Get number of nodes added to factor graph. **/
EXTERN_C CERESCODEGEN_API real64_T cerescodegen_getNumNodes(void* objPtr){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    return static_cast<real64_T>(graphObjPtr->getNumVariables());
}

/** Get number of factors added to factor graph . **/
EXTERN_C CERESCODEGEN_API real64_T cerescodegen_getNumFactors(void* objPtr){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    return static_cast<real64_T>(graphObjPtr->getNumFactors());
}

/** Get state of factor graph node**/
EXTERN_C CERESCODEGEN_API void cerescodegen_getNodeState(void* objPtr, const int32_T* vid, int32_T vidNum, real64_T* state, real64_T* stateLen){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    graphObjPtr->getVariableStateArray(vid, vidNum, state, stateLen);
}

/** Get type of factor graph node. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_getNodeType(void* objPtr, const real64_T vid, char_T* type, real64_T* typeLen){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    int id = static_cast<int>(vid);
    graphObjPtr->getVariableTypeChar(id, type, typeLen);
}

/** Get covariance of factor graph node**/
EXTERN_C CERESCODEGEN_API void cerescodegen_getNodeCovariance(void* objPtr, const int32_T* vid, int32_T vidNum, real64_T* covariance, real64_T* covarianceLen){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    graphObjPtr->getVariableCovarianceArray(vid, vidNum, covariance, covarianceLen);
}

/** Set factor graph node state. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_setNodeState(void* objPtr, const int32_T* vid, int32_T vidNum, real64_T* state, int32_T stateLen,
    real64_T* output, real64_T* outputLen){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    graphObjPtr->setVariableStateArray(vid, vidNum, state, stateLen, output, outputLen);
}

/** Remove factors. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_removeFactor(void* objPtr, const int32_T* vid, int32_T vidNum, real64_T* output, real64_T* outputLen){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    graphObjPtr->removeFactorArray(vid, vidNum, output, outputLen);
}

/** Remove nodes. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_removeNode(void* objPtr, const int32_T* vid, int32_T vidNum, real64_T* output, real64_T* outputLen){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    graphObjPtr->removeNodeArray(vid, vidNum, output, outputLen);
}

/** Marginalize factors. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_marginalizeFactor(void* objPtr, const int32_T* vid, int32_T vidNum, real64_T* output, real64_T* outputLen){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    graphObjPtr->marginalizeFactorArray(vid, vidNum, output, outputLen);
}

/** Marginalize node. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_marginalizeNode(void* objPtr, int32_T vid, real64_T* output, real64_T* outputLen){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    graphObjPtr->marginalizeNodeArray(vid, output, outputLen);
}

/** Fix factor graph node. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_fixNode(void* objPtr, const int32_T* vid, int32_T vidNum, real64_T* output, real64_T* outputLen){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    graphObjPtr->fixVariableArray(vid, vidNum, output, outputLen);
}

/** Free factor graph node. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_freeNode(void* objPtr, const int32_T* vid, int32_T vidNum, real64_T* output, real64_T* outputLen){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    graphObjPtr->freeVariableArray(vid, vidNum, output, outputLen);
}

/** Query if factor graph node is fixed. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_isNodeFixed(void* objPtr, const int32_T* vid, int32_T vidNum, real64_T* output, real64_T* outputLen){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    graphObjPtr->isVariableFixedArray(vid, vidNum, output, outputLen);
}

/** Query if factor graph has the specified node**/
EXTERN_C CERESCODEGEN_API boolean_T cerescodegen_hasNode(void* objPtr, const real64_T vid){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    int id = static_cast<int>(vid);
    return graphObjPtr->hasVariable(id);
}

/** Query if the factor graph is connected. **/
EXTERN_C CERESCODEGEN_API boolean_T cerescodegen_isConnected(void* objPtr, const int32_T* vid, int32_T vidNum){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    return graphObjPtr->isConnectedArray(vid, vidNum);
}

/** Query if the given node is pose type. **/
EXTERN_C CERESCODEGEN_API boolean_T cerescodegen_isPoseNode(void* objPtr, const int32_T* vid, int32_T vidNum){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    return graphObjPtr->isPoseNodeArray(vid, vidNum);
}

/** Optimize factor graph. **/
EXTERN_C CERESCODEGEN_API void cerescodegen_optimize(void* objPtr, real64_T* opts, real64_T* solInfo, int32_T* vid, int32_T vidNum,
    int32_T covarianceTypeNum, real64_T* OptimizedIDs, real64_T* OptimizedIDsLen, real64_T* FixedIDs, real64_T* FixedIDsLen){
    mw_ceres::FactorGraph* graphObjPtr = static_cast<mw_ceres::FactorGraph*>(objPtr);
    graphObjPtr->optimize(opts, solInfo, vid, vidNum, covarianceTypeNum, OptimizedIDs, OptimizedIDsLen, FixedIDs, FixedIDsLen);
}
