// Copyright 2021-2024 The MathWorks, Inc.
#ifndef FACTOR_GRAPH_HPP
#define FACTOR_GRAPH_HPP

#include <vector>
#include <unordered_map>
#include <unordered_set>
#include <map>
#include <limits>
#include <memory>
#include <algorithm>
#include "ceres/ceres.h"
#include "ceres/loss_function.h"

#ifdef BUILDING_LIBMWCERESCODEGEN
    #include "cerescodegen/cerescodegen_spec.hpp"
    #include "cerescodegen/factor.hpp"
    #include "cerescodegen/marginal_factor.hpp"
#else
    /* To deal with the fact that PackNGo has no include file hierarchy during test */
    #include "cerescodegen_spec.hpp"
    #include "factor.hpp"
    #include "marginal_factor.hpp"
#endif

namespace mw_ceres {

    enum FactorTypeEnum {Two_SE2_F, Two_SE3_F, SE2_Point2_F, SE3_Point3_F, IMU_F, GPS_F, SE2_Prior_F, SE3_Prior_F, IMU_Bias_Prior_F, Vel3_Prior_F, Camera_SE3_Point3_F, Two_SIM3_F, Marginal_F, Distorted_Pinhole_Camera_Projection_With_Variable_Intrinsics_F, Distorted_Pinhole_Camera_Projection_With_Aspect_Ratio_And_Variable_Intrinsics_F, Distorted_Pinhole_Camera_Projection_With_Fixed_Intrinsics_F, Distorted_Pinhole_Camera_Projection_With_Fixed_Intrinsics_And_Sensor_Transform_F};
    
    using LinearSolverType =  ceres::LinearSolverType;
    using TrustRegionStrategyType = ceres::TrustRegionStrategyType;
    using MinimizerType = ceres::MinimizerType;
    using LineSearchDirectionType = ceres::LineSearchDirectionType;
    using LineSearchType = ceres::LineSearchType;

    /// TODO
    struct Variable {
        int Dim;
        int Type;
        std::vector<double> State;
    };

    /// Commonly used trust region solver parameters
    struct CERESCODEGEN_API CeresSolverOptions {
        
        /// Minimizer type LINE_SEARCH or TRUST_REGION (default). 
		/// LINE_SEARCH is more conservative in selecting the step size.
        int MinimizerType;

        /// Trust region algorithm specifics
        
        /// LEVENBERG_MARQUARDT or DOGLEG (default). Note this default is different from Ceres
        int TrustRegionStrategyType;
        
        /// TRADITIONAL_DOGLEG (default) or SUBSPACE_DOGLEG  
        int DoglegType;

        /// SPARSE_NORMAL_CHOLESKY (default) or DENSE_QR
        int LinearSolverType;

        /// Size of the initial trust region. (default 1e4)
        double InitialTrustRegionRadius;

        /// Line search algorithm specifics

        /// Line search direction type. Possible choices are 
        /// STEEPEST_DESCENT, NONLINEAR_CONJUGATE_GRADIENT, BFGS and LBFGS (default).
        int LineSearchDirectionType;

        /// Line search type. Possible choices are ARMIJO, WOLFE (default).
        int LineSearchType;

        /// General
        
        /// Maximum number of iterations. (default 200)
        int MaxNumIterations;

        /// |new_cost - old_cost| < FunctionTolerance * old_cost (cost is always > 0). (default 1e-6)
        double FunctionTolerance;

        /// max_norm ( x - [x oplus -g(x)] ) <= GradientTolerance. (default 1e-10)
        double GradientTolerance;

        /// |delta_x| <= (|x| + StepTolerance) * StepTolerance (1e-8)
        double StepTolerance;

        /// 0 - no printing, 1 - only summary, 2 - per iteration + summary. (default 1)
        int VerbosityLevel;

        std::unordered_map<int, int> LinearSolverOrdering;
        /// Whether Ceres Solver should update solver parameters after each iteration, irrespective of solver success
        /// This is the case if the UpdateStateEveryIteration is set to true (default false)
        bool UpdateStateEveryIteration;
        
        /// Whether to abort the Ceres optimization. 
        /// (default is nullptr specifying that abort callback will not be 
        /// added to the ceres problem.)
        bool* AbortOptimization;
        double NumThreads;

        /// -1 - no covariance, -2 - all pose and point nodes. (default -1)
        std::vector<int> CovarianceType;

        CeresSolverOptions() {
            MinimizerType = ceres::TRUST_REGION;
            LineSearchType = ceres::WOLFE;
            LineSearchDirectionType = ceres::LBFGS;
            TrustRegionStrategyType = ceres::DOGLEG;
            DoglegType = ceres::TRADITIONAL_DOGLEG;
            LinearSolverType = ceres::SPARSE_NORMAL_CHOLESKY;
            InitialTrustRegionRadius = 1e4;
            MaxNumIterations = 200;
            FunctionTolerance = 1e-6;
            GradientTolerance = 1e-10;
            StepTolerance = 1e-8;
            VerbosityLevel = 1;
            UpdateStateEveryIteration = false; 
            AbortOptimization = nullptr;
            CovarianceType = {-1};
            NumThreads = 1.0;
        }
    };

    /// A (very) brief summary of the state of solver after optimization
    struct CERESCODEGEN_API CeresSolutionInfo {
        /// Cost of the objective function before the optimization
        double InitialCost;

        /// Cost of the objective function after the optimization
        double FinalCost;

        /// Number of iterations in which the step was accepted 
        int NumSuccessfulSteps;

        /// Number of iterations in which the step was rejected 
        int NumUnsuccessfulSteps;

        /// Time spent in the solver
        double TotalTime;

        /// Cause of minimizer terminating
        /// The options are CONVERGENCE, NO_CONVERGENCE, FAILURE, 
        int TerminationType;

        /// Reason why the solver terminated
        std::string Message;

        /// Whether the solution returned by optimizer is numerically sane
        /// This is the case if the TerminationType is CONVERGENCE or NO_CONVERGENCE
        bool IsSolutionUsable;

        /// Optimized node IDs
        std::vector<int> OptimizedNodeIDs;

        /// Fixed node IDs
        std::vector<int> FixedNodeIDs;
    };

    
    // NOTE Ceres problem definition only supports double as "too much pain and suffering in single precision land"

    /// <summary>
    /// A factor graph is a bipartite graph consisting of factors connected to variables.
    /// The variables represent the unknown random variables in the estimation problem,
    /// whereas the factors represent probabilistic constraints on those variables,
    /// derived from measurements or prior knowledge.
    /// </summary>
    class CERESCODEGEN_API FactorGraph {

    public:
        FactorGraph() : m_NumFactors(0), m_UniqueFactorID(0) {
            m_FactorType = { {"Two_SE2_F", FactorTypeEnum::Two_SE2_F},
                             {"Two_SE3_F", FactorTypeEnum::Two_SE3_F},
                             {"SE2_Point2_F", FactorTypeEnum::SE2_Point2_F},
                             {"SE3_Point3_F", FactorTypeEnum::SE3_Point3_F},
                             {"IMU_F", FactorTypeEnum::IMU_F},
                             {"GPS_F", FactorTypeEnum::GPS_F},
                             {"SE2_Prior_F", FactorTypeEnum::SE2_Prior_F},
                             {"SE3_Prior_F", FactorTypeEnum::SE3_Prior_F},
                             {"IMU_Bias_Prior_F", FactorTypeEnum::IMU_Bias_Prior_F},
                             {"Vel3_Prior_F", FactorTypeEnum::Vel3_Prior_F},
                             {"Camera_SE3_Point3_F", FactorTypeEnum::Camera_SE3_Point3_F},
                             {"Two_SIM3_F", FactorTypeEnum::Two_SIM3_F},
                             {"Marginal_F", FactorTypeEnum::Marginal_F},
                             {"Distorted_Pinhole_Camera_Projection_With_Variable_Intrinsics_F", FactorTypeEnum::Distorted_Pinhole_Camera_Projection_With_Variable_Intrinsics_F},
                             {"Distorted_Pinhole_Camera_Projection_With_Aspect_Ratio_And_Variable_Intrinsics_F", FactorTypeEnum::Distorted_Pinhole_Camera_Projection_With_Aspect_Ratio_And_Variable_Intrinsics_F},
                             {"Distorted_Pinhole_Camera_Projection_With_Fixed_Intrinsics_F", FactorTypeEnum::Distorted_Pinhole_Camera_Projection_With_Fixed_Intrinsics_F},
                             {"Distorted_Pinhole_Camera_Projection_With_Fixed_Intrinsics_And_Sensor_Transform_F", FactorTypeEnum::Distorted_Pinhole_Camera_Projection_With_Fixed_Intrinsics_And_Sensor_Transform_F}
                           };
		m_AllStates.reserve(1000000);
        }

        ~FactorGraph() {
        }

        // Explicitly delete the copy constructor and copy assignment operator
        // So that DLL_EXPORT (on Windows) can work correctly
        FactorGraph(const FactorGraph &) = delete;
        FactorGraph &operator=(const FactorGraph &) = delete;

        // default in move constructor/assignment
        FactorGraph &operator=(FactorGraph &&) = default;
        FactorGraph(FactorGraph &&) = default;

        /// Check whether the factor graph is connected
        bool isConnected(const std::vector<int>& IDs);

        /// Check whether the factor graph is connected for codegen
        bool isConnectedArray(const int* vid, int vidNum) {
            std::vector<int> id(vid,vid+size_t(vidNum));
            return isConnected(id);
        }

        /// Check whether the given node is pose node
        bool isPoseNode(std::vector<int> id);

        /// Check whether the given node is pose node for codegen
        bool isPoseNodeArray(const int* vid, int vidNum) {
            std::vector<int> id(vid,vid+size_t(vidNum));
            return isPoseNode(id);
        }

        /// Add a factor
        int addFactor(std::unique_ptr<Factor> fctr);

        /// Validate all the given factors
        std::vector<int> validateFactor(std::unique_ptr<Factor> fctr, std::vector<int> IDs, int size);

        /// Store node IDs with node type
        void storeNodeIDs(std::unordered_map<int, std::set<int> >& map, int type, std::set<int> IDs);

        /// Store node with factor type
        void storeFactorTypes(std::unordered_map<int, std::unordered_map<int, std::set<int> > >& map,
            int fctrType, int node_type, std::set<int> IDs);

        /// Store factor and node with group ID
        void storeGroups(std::unordered_map<int, std::unordered_map<int, std::unordered_map<int, std::set<int> > > >& map,
            int group, int fctrType, int node_type, std::set<int> IDs);

        /// Store information for the factor which can accept two group ID
        void storeByTwoGroupID(std::vector<int> GroupID, const size_t numGroupID, std::vector<int> IDs, const size_t numIds,
            int fctrType, int nodeType1, int nodeType2);

        /// Store information for the factor which can only accept one group ID
        void storeByOneGroupID(std::vector<int> GroupID, const size_t numGroupID, std::vector<int> IDs, int fctrType,
            int nodeType, std::set<int> IDset);

        /// Store factorIMU information
        void storeIMU(std::vector<int> IDs, const std::vector<int>& groupID);

        /// Store factorTwoPoseSIM3 information
        void storeSIM3(std::vector<int> IDs, const std::vector<int>& groupID);

        /// Store factor ID information
        void storeFactorID(int fID, int fctrType);

        /// Store factorIMU information
        int storeIMUArray(std::unique_ptr<Factor> fctr, const int* groupID, const size_t numGroupID) {
            std::vector<int> gID(groupID,groupID+numGroupID);
            std::vector<int> varIDs = fctr->getVariableIDs();
            int fId = addFactor(std::move(fctr));
            if (fId != -1) {
                storeIMU(varIDs, gID);
            }
            return fId;
        }

        /// Retrieve variable IDs in the graph
        std::vector<int> getAllVariableIDs(std::vector<int> groupID, std::string nodeType, std::string factorType) const;

        /// Add a gaussian noise model factor
        std::vector<int> addGaussianFactor(const char* factorType, const size_t factorTypeLen, const int* ids, const size_t numIds, const double* measurement,
            const size_t numMeasurement, const double* information, const size_t numInformation, const size_t numFactors, const int* groupID, const size_t numGroupID);

        /// Add factors and get output as an array
        void addGaussianFactorArray(const char* factorType, const size_t factorTypeLen, const int* ids, const size_t numIds, const double* measurement,
            const size_t numMeasurement, const double* information, const size_t numInformation, const size_t numFactors, const int* groupID,
            const size_t numGroupID, double* output, double* outputLen) {
            std::vector<int> v = addGaussianFactor(factorType, factorTypeLen, ids, numIds, measurement,
                numMeasurement, information, numInformation, numFactors, groupID, numGroupID);
            // fill output array
            for(size_t k=0;k<v.size();k++){
                output[k] = static_cast<double>(v[k]);
            }
            outputLen[0] = static_cast<double>(v.size());
        }

        /// Add  camera projection factor
        std::vector<int> addCameraProjectionFactor(const char* factorType, const size_t factorTypeLen, const int* ids, const size_t numIds, const double* measurement,
            const size_t numMeasurement, const double* information, const size_t numInformation, const size_t numFactors, const int* groupID, const size_t numGroupID, const double* sensorTform);

        /// Add camera projection factors and get output as an array
        void addCameraProjectionFactorArray(const char* factorType, const size_t factorTypeLen, const int* ids, const size_t numIds, const double* measurement,
            const size_t numMeasurement, const double* information, const size_t numInformation, const size_t numFactors, const int* groupID,
            const size_t numGroupID, const double* sensorTform, double* output, double* outputLen) {
            std::vector<int> v = addCameraProjectionFactor(factorType, factorTypeLen, ids, numIds, measurement,
                numMeasurement, information, numInformation, numFactors, groupID, numGroupID, sensorTform);
            // fill output array
            for(size_t k=0;k<v.size();k++){
                output[k] = static_cast<double>(v[k]);
            }
            outputLen[0] = static_cast<double>(v.size());
        }


        /// Add distorted camera projection factor
        std::vector<int> addDistortedCameraProjectionFactor(const char* factorType, const size_t factorTypeLen, const int* ids, const size_t numIds, const double* measurement,
            const size_t numMeasurement, const double* information, const size_t numInformation, const size_t numFactors, const double* intrinsic,const size_t numIntrinsic, const double* sensorTransform,const size_t numSensorTransform, const int* groupID, const size_t numGroupID);

        /// Add distorted camera projection factors and get output as an array
        void addDistortedCameraProjectionFactorArray(const char* factorType, const size_t factorTypeLen, const int* ids, const size_t numIds, const double* measurement,
            const size_t numMeasurement, const double* information, const size_t numInformation, const size_t numFactors, const double* intrinsic,const size_t numIntrinsic, const double* sensorTransform,const size_t numSensorTransform, const int* groupID,
            const size_t numGroupID, double* output, double* outputLen) {
            std::vector<int> v = addDistortedCameraProjectionFactor(factorType, factorTypeLen, ids, numIds, measurement,
                numMeasurement, information, numInformation, numFactors, intrinsic, numIntrinsic, sensorTransform, numSensorTransform, groupID, numGroupID);
            // fill output array
            for(size_t k=0;k<v.size();k++){
                output[k] = static_cast<double>(v[k]);
            }
            outputLen[0] = static_cast<double>(v.size());
        }


    
        /// Add a variable. Note this API is not required before calling addFactor.
        int addVariable(int id, std::vector<double> state, int varType);

        /// Update state for variables
        std::vector<int> setVariableState(const std::vector<int>& id, const std::vector<double>& var, int size);

        template <typename VarType>
        std::vector<int> setVariableState(const std::vector<int>& id, const VarType&& var, int size) {
            return setVariableState(id, var, size);
        }

        /// Retrieve state of a variable
        std::vector<double> getVariableState(const std::vector<int>& ids) {
            std::vector<int> validness = validateExistence(ids);
            std::vector<double> res;
            if (validness.back() == -1) {
                // There are nodes not in the graph
                res = {validness.begin(), validness.end()};
                res.push_back(std::numeric_limits<double>::quiet_NaN());
                return res;
            }

            int type = m_MapOfVariableTypes[ids[0]];
            validness = validateType(ids, type);
            if (validness.back() == -2) {
                // There are nodes with different types
                res = {validness.begin(), validness.end()};
                res.push_back(std::numeric_limits<double>::quiet_NaN());
                return res;
            }
            size_t sz = static_cast<size_t>(m_MapOfVariableDims[ids[0]]);
            std::vector<double> states(ids.size() * sz, 0);
            std::vector<double>::iterator iter = states.begin();
            for (size_t i=0; i<ids.size(); i++){
                auto iterNode = m_MapOfVariables.find(ids[i]);
                double* currentState = m_AllStates.data() + iterNode->second;
                std::copy(currentState, currentState+sz, iter);
                std::advance(iter, sz);
            }
            return  states;
        }

        // get variable state as an array
        void getVariableStateArray(const int* vid, int vidNum, double* state, double* stateLen) {
            std::vector<int> ids(vid,vid+size_t(vidNum));
            std::vector<double> v = getVariableState(ids);
            // fill output array
            for(size_t k=0;k<v.size();k++){
                state[k] = v[k];
            }
            stateLen[0] = static_cast<double>(v.size());
        }

        /// set variable state using an array input
        void setVariableStateArray(const int* vid, int vidNum, double* state, int stateLen, double* output, double* outputLen) {
            std::vector<int> id(vid,vid+size_t(vidNum));
            std::vector<double> v(state,state+size_t(vidNum*stateLen));
            std::vector<int> out = setVariableState(id,v,stateLen);
            // fill output array
            for(size_t k=0;k<out.size();k++){
                output[k] = static_cast<double>(out[k]);
            }
            outputLen[0] = static_cast<double>(out.size());
        }
        
        /// Retrieve all variable IDs in the graph and fill output array
        void getVariableIDsArray(double* output, double* outputLen, const int* groupID, const size_t numgroupID,
            const char* nodeType, const size_t nodeTypeLen, const char* factorType, const size_t factorTypeLen) {
            std::vector<int> gID(groupID, groupID + numgroupID);
            std::string fctr_type(factorType, factorTypeLen);
            std::string node_type(nodeType, nodeTypeLen);
            std::vector<int> v = getAllVariableIDs(gID, node_type, fctr_type);
            // fill output array
            for(size_t k=0;k<v.size();k++){
                output[k] = static_cast<double>(v[k]);
            }
            outputLen[0] = static_cast<double>(v.size());
        }

        /// Retrieve the type of a variable
        int getVariableType(int id) const {
            auto iter = m_MapOfVariableTypes.find(id);
            if (iter == m_MapOfVariableTypes.end())
                return -1;

            return iter->second;
        }

        /// Retrieve the user-facing variable type string
        std::string getVariableTypeString(int id) const {
            int typeId = getVariableType(id);
            if (typeId == -1) return "";
            return VariableTypeString.at(static_cast<VariableType>(typeId));
        }

        /// Retrieve the user-facing variable type as char
        void getVariableTypeChar(int id, char* type, double* typeLen) const {
            std::string t = getVariableTypeString(id);
            std::copy(t.begin(),t.end(),type);
            *typeLen = static_cast<double>(t.size());
        }

        /// Retrieve the number of factors in the graph
        int getNumFactors() const {
            return m_NumFactors;
        }

        /// Retrieve the number of variables in the graph
        int getNumVariables() const {
            return static_cast<int>(m_MapOfVariables.size());
        }

        /// Whether a variable with given node ID exists in the graph
        bool hasVariable(const int id) const {
            return m_MapOfVariables.count(id) == 1 ? true : false;
        }

        /// Validate whether all nodes exist in the graph and return -1 for invalid ones
        std::vector<int> validateExistence(const std::vector<int>& ids) const {
            std::vector<int> validness;
            int flag = 1;
            for (auto id: ids) {
                if (m_MapOfVariables.find(id) == m_MapOfVariables.end()) {
                    validness.push_back(-1);
                    flag = -1;
                }
                else {
                    validness.push_back(1);
                }
            }
            validness.push_back(flag);
            return validness;
        }

        /// Validate whether all factors exist in the graph and return -1 for invalid ones
        std::vector<int> validateFactorExistence(const std::vector<int>& ids) const {
            std::vector<int> validness;
            int flag = 1;
            for (auto id: ids) {
                if (m_MapOfFactors.find(id) == m_MapOfFactors.end()) {
                    validness.push_back(-1);
                    flag = -1;
                }
                else {
                    validness.push_back(1);
                }
            }
            validness.push_back(flag);
            return validness;
        }

        /// Validate whether all node states have the same size as the given size
        std::vector<int> validateType(const std::vector<int>& ids, int type) {
            std::vector<int> validness;
            int flag = 1;
            for (auto id: ids) {
                if (type != m_MapOfVariableTypes[id]) {
                    validness.push_back(-2);
                    flag = -2;
                }
                else {
                    validness.push_back(1);
                }
            }
            validness.push_back(flag);
            return validness;
        }

        /// Validate whether all node covariances are estimated before retrieval
        std::vector<int> validateCovarianceExistence(const std::vector<int>& ids) {
            std::vector<int> validness;
            int flag = 1;
            for (auto id: ids) {
                if (m_MapOfNodeCovariances.find(id) == m_MapOfNodeCovariances.end()) {
                    validness.push_back(-1);
                    flag = -3;
                }
                else {
                    validness.push_back(1);
                }
            }
            validness.push_back(flag);
            return validness;
        }

        /// Freeze/fix a variable so that its state does not change in optimization
        std::vector<int> fixVariable(const std::vector<int>& ids);

        /// Freeze/fix variables and get output as an array
        void fixVariableArray(const int* vid, int vidNum, double* output, double* outputLen) {
            std::vector<int> id(vid,vid+size_t(vidNum));
            std::vector<int> v = fixVariable(id);
            // fill output array
            for(size_t k=0;k<v.size();k++){
                output[k] = static_cast<double>(v[k]);
            }
            outputLen[0] = static_cast<double>(v.size());
        }

        /// Unfreeze/free a variable
        std::vector<int> freeVariable(const std::vector<int>& ids);

        /// Unfreeze/free variables and get output as an array
        void freeVariableArray(const int* vid, int vidNum, double* output, double* outputLen) {
            std::vector<int> id(vid,vid+size_t(vidNum));
            std::vector<int> v = freeVariable(id);
            // fill output array
            for(size_t k=0;k<v.size();k++){
                output[k] = static_cast<double>(v[k]);
            }
            outputLen[0] = static_cast<double>(v.size());
        }

        // Check if a variable is frozen (fixed) or not
        std::vector<int> isVariableFixed(const std::vector<int>& ids);

        // Check if variables are fixed or not and get output as an array
        void isVariableFixedArray(const int* vid, int vidNum, double* output, double* outputLen) {
            std::vector<int> id(vid, vid + size_t(vidNum));
            std::vector<int> v = isVariableFixed(id);
            // fill output array
            for(size_t k=0;k<v.size();k++){
                output[k] = static_cast<double>(v[k]);
            }
            outputLen[0] = static_cast<double>(v.size());
        }

        // Remove factors by factor ID
        std::vector<int> removeFactor(const std::vector<int>& id);

        // Remove factors and get output as an array
        void removeFactorArray(const int* vid, int vidNum, double* removedNodeID, double* removedNodeLen) {
            std::vector<int> ids(vid,vid+size_t(vidNum));
            std::vector<int> v = removeFactor(ids);
            // fill output array
            for(size_t k=0;k<v.size();k++){
                removedNodeID[k] = static_cast<double>(v[k]);
            }
            removedNodeLen[0] = static_cast<double>(v.size());
        }

        // Remove nodes by node ID
        std::vector<int> removeNode(const std::vector<int>& id);

        // Remove nodes and get output as an array
        void removeNodeArray(const int* vid, int vidNum, double* removedID, double* removedIDLen) {
            std::vector<int> ids(vid,vid+size_t(vidNum));
            std::vector<int> v = removeNode(ids);
            // fill output array
            for(size_t k=0;k<v.size();k++){
                removedID[k] = static_cast<double>(v[k]);
            }
            removedIDLen[0] = static_cast<double>(v.size());
        }

        // Remove dangling nodes
        std::vector<int> removeDanglingNode();

        // Remove factors by factor IDs
        void removeFactorByFactorID(const std::vector<int>& id);

        /// Optimize the graph using current states in variables as initial guess.
        /// The optimized result is updated in place.
        CeresSolutionInfo optimize(const CeresSolverOptions& optStruct, const std::vector<int>& ids, bool storeProblem = false);
        void optimize(double* opts, double* info, int* ids, int vidNum, int covarianceTypeNum, double* OptimizedIDs, double* OptimizedIDsLen,
            double* FixedIDs, double* FixedIDsLen); // for codegen call

        // Get which nodes are connected by the edges
        std::vector<int> getEdge(int fctrType);


        // Get node IDs for covariance calculation
        std::set<int> getCovarianceNodeID(const std::vector<int>& CovarianceType, const std::vector<int>& ids);

        // Calculate covariance
        std::vector<double> computeCovariance(ceres::Problem& problem, const std::set<int>& covarianceNodeID);

        // Retrieve covariance of variables
        std::vector<double> getVariableCovariance(const std::vector<int>& ids) {
            std::vector<int> validness = validateExistence(ids);
            std::vector<double> res;
            if (validness.back() == -1) {
                // There are nodes not in the graph
                res = {validness.begin(), validness.end()};
                res.push_back(std::numeric_limits<double>::quiet_NaN());
                return res;
            }

            int type = m_MapOfVariableTypes[ids[0]];
            validness = validateType(ids, type);
            if (validness.back() == -2) {
                // There are nodes with different types
                res = {validness.begin(), validness.end()};
                res.push_back(std::numeric_limits<double>::quiet_NaN());
                return res;
            }
            validness = validateCovarianceExistence(ids);
            if (validness.back() == -3) {
                // There are nodes without covariances stored
                res = {validness.begin(), validness.end()};
                res.push_back(std::numeric_limits<double>::quiet_NaN());
                return res;
            }
            auto iterNode = m_MapOfNodeCovariances.find(ids[0]);
            std::vector<double> currentCovariance = iterNode->second;
            std::vector<double> covariances(ids.size() * currentCovariance.size(), 0);
            std::vector<double>::iterator iter = covariances.begin();
            for (size_t i=0; i<ids.size(); i++){
                iterNode = m_MapOfNodeCovariances.find(ids[i]);
                currentCovariance = iterNode->second;
                std::copy(currentCovariance.begin(), currentCovariance.end(), iter);
                std::advance(iter, currentCovariance.size());
            }
            return  covariances;
        }

        // get variable covariance as an array
        void getVariableCovarianceArray(const int* vid, int vidNum, double* covariance, double* covarianceLen) {
            std::vector<int> ids(vid,vid+size_t(vidNum));
            std::vector<double> v = getVariableCovariance(ids);
            // fill output array
            for(size_t k=0;k<v.size();k++){
                covariance[k] = v[k];
            }
            covarianceLen[0] = static_cast<double>(v.size());
        }

        // Find all types of nodes in the partial graph by the given pose nodes
        std::set<int> findNodesInPartialGraphByPoseNodes(const std::vector<int>& ids);

        // Check if any unselected pose nodes are included 
        bool isUnselectedPoseNodeIncluded(const std::vector<int>& selectedIDs, int fID, const std::vector<int>& includedNodeIDs);

        // Get all the factors in the partial graph by the given pose node
        std::unordered_set<int> findFactorsInPartialGraphByPoseNode(int poseID);

        // Get m_MapOfFactorType
        std::unordered_map<int, std::unordered_map<int, std::set<int> > >& getMapOfFactorType() {
            return m_MapOfFactorType;
        }

        // Marginalize the given marginal factor. The input must be a marginal factor. Return the node IDs being marginalized.
        // Remember to utilize addMarginalFactor to add the marginal factor to factorGraph after marginalization
        std::vector<int> marginalize(std::unique_ptr<MarginalFactor>& fctr);

        // Marginalize factors by factor ID
        std::vector<int> marginalizeFactor(const std::vector<int>& id);

        // Marginalize factors and get output as an array
        void marginalizeFactorArray(const int* vid, int vidNum, double* output, double* outputLen) {
            std::vector<int> ids(vid,vid+size_t(vidNum));
            std::vector<int> v = marginalizeFactor(ids);
            // fill output array
            for(size_t k=0;k<v.size();k++){
                output[k] = static_cast<double>(v[k]);
            }
            outputLen[0] = static_cast<double>(v.size());
        }

        // Marginalize nodes by node ID
        std::vector<int> marginalizeNode(int id);

        // Marginalize nodes and get output as an array
        void marginalizeNodeArray(int vid, double* output, double* outputLen) {
            std::vector<int> v = marginalizeNode(vid);
            // fill output array
            for(size_t k=0;k<v.size();k++){
                output[k] = static_cast<double>(v[k]);
            }
            outputLen[0] = static_cast<double>(v.size());
        }

        /// Add a marginal factor to factor graph
        int addMarginalFactor(std::unique_ptr<MarginalFactor> fctr);

        // Get individual factor residuals for the given node IDs
        std::unordered_map<int, std::unordered_map<int, std::vector<double> > > getIndividualFactorResidual(const std::set<int>& ids, int factorType);

        // Get individual factor residuals for the given node IDs
        std::unordered_map<int, std::unordered_map<int, std::vector<double> > > getIndividualFactorResidualAssumingStateUnchanged(const std::set<int>& ids, int factorType);

    protected:
        // This stores all variable states
        std::vector<double> m_AllStates;

        /// This is currently the map from variable ID to variable state
        std::unordered_map<int, size_t> m_MapOfVariables;

        /// This is currently the map from variable ID to variable state dimension
        std::unordered_map<int, int> m_MapOfVariableDims;

        /// This is currently the map from variable ID to variable (local parameterization) type
        std::unordered_map<int, int> m_MapOfVariableTypes;

        /// This is currently the map from variable ID to whether this variable is held constant during graph optimization or not
        std::unordered_map<int, bool> m_MapOfVariableIsConstant;

        /// Map from unique factor ID to the unique pointer of the factor object
        std::map<int, std::unique_ptr<Factor>> m_MapOfFactors;

        // Map of factor type string to the unique ID
        std::unordered_map<std::string, int> m_FactorType;

        // Map from node type to node IDs
        std::unordered_map<int, std::set<int> > m_MapOfNodeTypes;

        // Map from factor type to node type map
        std::unordered_map<int, std::unordered_map<int, std::set<int> > > m_MapOfFactorType;

        // Map from group to factor type map
        std::unordered_map<int, std::unordered_map<int, std::unordered_map<int, std::set<int> > > > m_MapOfGroup;

        // Map from node ID to factor IDs
        std::unordered_map<int, std::unordered_set<int> > m_MapOfNodeIDtoFactorID;

        /// Map from unique factor ID to factor type
        std::map<int, int> m_MapOfFactorIDtoFactorType;

        /// Set for storing potential dangling nodes
        std::set<int> m_DanglingNodes;


        /// This is currently the map from variable ID to variable covariance
        std::unordered_map<int, std::vector<double>> m_MapOfNodeCovariances;

        /// Map from factor ID to residual block ID. (Should be reset for each new problem)
        std::unordered_map<int, ceres::ResidualBlockId> m_MapOfFactorIDtoResidualID;

        /// Number of factors in the graph
        int m_NumFactors;

        /// Next factor ID
        int m_UniqueFactorID;

        /// ceres::Problem
        ceres::Problem Problem;
    };


    inline std::vector<int> FactorGraph::fixVariable(const std::vector<int>& ids) {
        std::vector<int> validness = validateExistence(ids);
        // If all ids are valid
        if (validness.back()!=-1) {
            for (auto id : ids) {
                m_MapOfVariableIsConstant[id] = true;
            }
        }
        return validness;
    }

    inline std::vector<int> FactorGraph::freeVariable(const std::vector<int>& ids) {
        std::vector<int> validness = validateExistence(ids);
        // If all ids are valid
        if (validness.back()!=-1) {
            for (auto id : ids) {
                m_MapOfVariableIsConstant[id] = false;
            }
        }
        return validness;
    }

    inline std::vector<int> FactorGraph::isVariableFixed(const std::vector<int>& ids) {
        std::vector<int> validness = validateExistence(ids);
        // If all ids are valid
        if (validness.back()!=-1) {
            validness = {};
            for (auto id : ids) {
                if (m_MapOfVariableIsConstant.at(id)) {
                    validness.push_back(1);
                }
                else {
                    validness.push_back(0);
                }
            }
        }
        return validness;
    }


    class AbortSolverCallback : public ceres::IterationCallback {
    public:
        AbortSolverCallback(const bool* abortIteration) : abortIteration_(abortIteration) {}
        ~AbortSolverCallback() override = default;
        ceres::CallbackReturnType operator()(const ceres::IterationSummary& summary) final;

    private:
        const bool* abortIteration_ = nullptr;
    };


}



#endif // FACTOR_GRAPH_HPP
