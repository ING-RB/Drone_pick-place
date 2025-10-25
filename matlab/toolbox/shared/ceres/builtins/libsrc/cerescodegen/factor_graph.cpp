// Copyright 2021-2024 The MathWorks, Inc.

#ifdef BUILDING_LIBMWCERESCODEGEN
    #include "cerescodegen/factor_graph.hpp"
    #include "cerescodegen/common_factors_2.hpp"
    #include "cerescodegen/camera_projection_factor.hpp"
#else
    /* To deal with the fact that PackNGo has no include file hierarchy during test */
    #include "factor_graph.hpp"
    #include "common_factors_2.hpp"
    #include "camera_projection_factor.hpp"
#endif

using namespace std;

ceres::CallbackReturnType mw_ceres::AbortSolverCallback::operator()(
    const ceres::IterationSummary& summary){

    // intentionally unused
    (void)summary;

    // Check whether the user has aborted Ceres Solver Optimization
    // If this is the case, then update Solver parameters and terminate, else continue to next solver iteration.
    if (*abortIteration_) {
        return ceres::SOLVER_TERMINATE_SUCCESSFULLY;
    } else {
        return ceres::SOLVER_CONTINUE;
    }
}

mw_ceres::CeresSolutionInfo mw_ceres::FactorGraph::optimize(const mw_ceres::CeresSolverOptions& optStruct, const vector<int>& ids,
    bool storeProblem) {

    ceres::Solver::Options options;
    options.max_num_iterations = optStruct.MaxNumIterations;
    options.function_tolerance = optStruct.FunctionTolerance;
    options.gradient_tolerance = optStruct.GradientTolerance;
    options.parameter_tolerance = optStruct.StepTolerance;
    options.minimizer_type = static_cast<ceres::MinimizerType>(optStruct.MinimizerType);
    options.trust_region_strategy_type =
        static_cast<ceres::TrustRegionStrategyType>(optStruct.TrustRegionStrategyType);
    options.linear_solver_type = static_cast<ceres::LinearSolverType>(optStruct.LinearSolverType);
    options.dogleg_type = static_cast<ceres::DoglegType>(optStruct.DoglegType);
    options.initial_trust_region_radius = optStruct.InitialTrustRegionRadius;
    options.line_search_direction_type = static_cast<ceres::LineSearchDirectionType>(optStruct.LineSearchDirectionType);
    options.line_search_type = static_cast<ceres::LineSearchType>(optStruct.LineSearchType);
    if (optStruct.VerbosityLevel == 2) {
        options.logging_type = ceres::PER_MINIMIZER_ITERATION;
    } else {
        options.logging_type = ceres::SILENT;
    }

    options.update_state_every_iteration = optStruct.UpdateStateEveryIteration;
    mw_ceres::AbortSolverCallback callback(optStruct.AbortOptimization); 
    if (optStruct.AbortOptimization != nullptr){
        options.callbacks.push_back(&callback);
    }
    
    std::vector<int> CovarianceType = optStruct.CovarianceType;
    

    // reset Ceres problem object and m_MapOfFactorIDtoResidualID
    ceres::Problem problem;
    m_MapOfFactorIDtoResidualID.clear();
    
    // map from variable type identifier to pointers of corresponding local parameterization objects,
    // variables of the same type will share the same local parameterization object
    // this map has to be re-created before every optimization 
    std::unordered_map<int, ceres::LocalParameterization*> mapOfLocalParameterizations;

    // vector storing the node IDs which will be optimized
    vector<int> optimizedNodeIDs;

    // vector storing the node IDs which are fixed
    vector<int> fixedNodeIDs;

    set<int> optimizedNodeIDsSet;
    set<int> fixedNodeIDsSet;

    if (ids.front() == -1) {
        for (const auto& fp : m_MapOfFactors) {
        
            vector<int> varIDs = fp.second->getVariableIDs();

            vector<double*> parameterBlocks;
            if (m_MapOfFactorIDtoFactorType[fp.first] == m_FactorType["Marginal_F"]) {
                // Marginal Factor
                for (const int& id : varIDs) {
                    auto varAtId = m_AllStates.data() + m_MapOfVariables[id];
                    parameterBlocks.push_back(varAtId);
                }
            }
            else {
                // Non-marginal Factor
                for (const int& id : varIDs) {

                    int localParamType = fp.second->getVariableType(id);
                    auto lpIt = mapOfLocalParameterizations.find(localParamType);
                    if (lpIt == mapOfLocalParameterizations.end()) {
                        mapOfLocalParameterizations[localParamType] = fp.second->getVariableLocalParameterization(id);
                    }

                    auto varAtId = m_AllStates.data() + m_MapOfVariables[id];
                    problem.AddParameterBlock(varAtId, m_MapOfVariableDims[id],
                        mapOfLocalParameterizations[fp.second->getVariableType(id)]);
                    parameterBlocks.push_back(varAtId);

                    // fixed or free?
                    if (m_MapOfVariableIsConstant.at(id)) {
                        problem.SetParameterBlockConstant(varAtId);
                        fixedNodeIDsSet.insert(id);
                    }
                    else {
                        problem.SetParameterBlockVariable(varAtId);
                        optimizedNodeIDsSet.insert(id);
                    }
                }

                fp.second->preOptimizationUpdate(parameterBlocks); // update factor before the graph optimization is run
            }
            ceres::CostFunction* costFcn = fp.second->createFactorCostFcn();
            ceres::LossFunctionWrapper* loss_function = fp.second->createFactorLossFcn();
            m_MapOfFactorIDtoResidualID[fp.first] = problem.AddResidualBlock(costFcn,
                                       loss_function, // loss_function
                                       parameterBlocks);
        }
    }
    else {
        // keep track of whether the factor is checked or not
        vector<int> factorIDs;
        for (auto poseid : ids) {
            for (auto fID : m_MapOfNodeIDtoFactorID[poseid]) {
                if (find(factorIDs.begin(), factorIDs.end(), fID) == factorIDs.end()) {
                    factorIDs.push_back(fID);
                    vector<int> varIDs = m_MapOfFactors[fID]->getVariableIDs();
                    // Skip the factor including other pose nodes
                    int skip = 0;
                    int fctrType = m_MapOfFactorIDtoFactorType[fID];
                    if (fctrType == 0 || fctrType == 1) {
                        // 0: TwoPoseSE2 1: TwoPoseSE3
                        for (const int& id : varIDs) {
                            if (std::find(ids.begin(), ids.end(), id) == ids.end()) {
                                skip = 1;
                                break;
                            }
                        }
                    }
                    else if (fctrType == 4) {
                        // 4: IMU
                        if (std::find(ids.begin(), ids.end(), varIDs[0]) == ids.end() || std::find(ids.begin(), ids.end(), varIDs[3]) == ids.end()) {
                            skip = 1;
                        }
                    }
                    else if (fctrType == m_FactorType["Marginal_F"]) {
                        // Marginal factor
                        auto vPoseSE3 = m_MapOfNodeTypes[0]; // POSE_SE3
                        auto vPoseSE2 = m_MapOfNodeTypes[1]; // POSE_SE2
                        for (auto vID : varIDs) {
                            if ((std::find(vPoseSE3.begin(), vPoseSE3.end(), vID) != vPoseSE3.end() || std::find(vPoseSE2.begin(), vPoseSE2.end(), vID) != vPoseSE2.end()) && (std::find(ids.begin(), ids.end(), vID) == ids.end()) ) {
                                skip = 1;
                            }
                        }
                    }
                    if (skip) continue;
                    vector<double*> parameterBlocks;
                    if (fctrType == m_FactorType["Marginal_F"]) {
                        // Marginal Factor
                        for (const int& id : varIDs) {
                            auto varAtId = m_AllStates.data() + m_MapOfVariables[id];
                            parameterBlocks.push_back(varAtId);
                        }
                    }
                    else {
                        // Non-marginal factor
                        for (const int& id : varIDs) {

                            int localParamType = m_MapOfFactors[fID]->getVariableType(id);
                            auto lpIt = mapOfLocalParameterizations.find(localParamType);
                            if (lpIt == mapOfLocalParameterizations.end()) {
                                mapOfLocalParameterizations[localParamType] = m_MapOfFactors[fID]->getVariableLocalParameterization(id);
                            }

                            auto varAtId = m_AllStates.data() + m_MapOfVariables[id];
                            problem.AddParameterBlock(varAtId, m_MapOfVariableDims[id],
                                mapOfLocalParameterizations[m_MapOfFactors[fID]->getVariableType(id)]);
                            parameterBlocks.push_back(varAtId);

                            // fixed or free?
                            if (m_MapOfVariableIsConstant.at(id)) {
                                problem.SetParameterBlockConstant(varAtId);
                                fixedNodeIDsSet.insert(id);
                            }
                            else {
                                problem.SetParameterBlockVariable(varAtId);
                                optimizedNodeIDsSet.insert(id);
                            }

                        }

                        m_MapOfFactors[fID]->preOptimizationUpdate(parameterBlocks); // update factor before the graph optimization is run
                    }

                    ceres::CostFunction* costFcn = m_MapOfFactors[fID]->createFactorCostFcn();
                    ceres::LossFunctionWrapper* loss_function = m_MapOfFactors[fID]->createFactorLossFcn();
                    m_MapOfFactorIDtoResidualID[fID] = problem.AddResidualBlock(costFcn,
                        loss_function, // loss_function
                        parameterBlocks);
                }
            }
        }
        // Check for non-pose prior factor (Vel)
        if (m_MapOfFactorType.find(m_FactorType["Vel3_Prior_F"]) != m_MapOfFactorType.end()) {
            auto velTypeMap = m_MapOfFactorType[m_FactorType["Vel3_Prior_F"]];
            if (!velTypeMap.empty()) {
                // Have vel prior factor
                auto velSet = velTypeMap[NodeTypeInt["VEL3"]];
                for (auto vel : velSet) {
                    // vel is the vel node ID
                    if (fixedNodeIDsSet.find(vel) != fixedNodeIDsSet.end() || optimizedNodeIDsSet.find(vel) != optimizedNodeIDsSet.end()) {
                        // The vel node is in the selected set
                        auto fVel = m_MapOfNodeIDtoFactorID[vel];
                        for (auto fVelID : fVel) {
                            if (m_MapOfFactorIDtoFactorType[fVelID] == m_FactorType["Vel3_Prior_F"]) {
                                // Prior factor found
                                factorIDs.push_back(fVelID);
                                vector<double*> parameterBlocks;
                                int localParamType = m_MapOfFactors[fVelID]->getVariableType(vel);
                                auto lpIt = mapOfLocalParameterizations.find(localParamType);
                                if (lpIt == mapOfLocalParameterizations.end()) {
                                    mapOfLocalParameterizations[localParamType] = m_MapOfFactors[fVelID]->getVariableLocalParameterization(vel);
                                }

                                auto velAtId = m_AllStates.data() + m_MapOfVariables[vel];
                                problem.AddParameterBlock(velAtId, m_MapOfVariableDims[vel],
                                    mapOfLocalParameterizations[m_MapOfFactors[fVelID]->getVariableType(vel)]);
                                parameterBlocks.push_back(velAtId);

                                // fixed or free?
                                if (m_MapOfVariableIsConstant.at(vel)) {
                                    problem.SetParameterBlockConstant(velAtId);
                                }
                                else {
                                    problem.SetParameterBlockVariable(velAtId);
                                }
                                m_MapOfFactors[fVelID]->preOptimizationUpdate(parameterBlocks); // update factor before the graph optimization is run

                                ceres::CostFunction* costFcn = m_MapOfFactors[fVelID]->createFactorCostFcn();
                                ceres::LossFunctionWrapper* loss_function = m_MapOfFactors[fVelID]->createFactorLossFcn();
                                m_MapOfFactorIDtoResidualID[fVelID] = problem.AddResidualBlock(costFcn,
                                    loss_function, // loss_function
                                    parameterBlocks);
                            }
                        }
                    }

                }
            }
        }
        // Check for non-pose prior factor (IMUBias)
        if (m_MapOfFactorType.find(m_FactorType["IMU_Bias_Prior_F"]) != m_MapOfFactorType.end()) {
            auto biasTypeMap = m_MapOfFactorType[m_FactorType["IMU_Bias_Prior_F"]];
            if (!biasTypeMap.empty()) {
                // Have IMUBias factor
                auto biasSet = biasTypeMap[NodeTypeInt["IMU_BIAS"]];
                for (auto bias : biasSet) {
                    // bias is the IMUBias node ID
                    if (fixedNodeIDsSet.find(bias) != fixedNodeIDsSet.end() || optimizedNodeIDsSet.find(bias) != optimizedNodeIDsSet.end()) {
                        // The bias node is in the selected set
                        auto fBias = m_MapOfNodeIDtoFactorID[bias];
                        for (auto fBiasID : fBias) {
                            if (m_MapOfFactorIDtoFactorType[fBiasID] == m_FactorType["IMU_Bias_Prior_F"]) {
                                // Bias factor found
                                factorIDs.push_back(fBiasID);
                                vector<double*> parameterBlocks;
                                int localParamType = m_MapOfFactors[fBiasID]->getVariableType(bias);
                                auto lpIt = mapOfLocalParameterizations.find(localParamType);
                                if (lpIt == mapOfLocalParameterizations.end()) {
                                    mapOfLocalParameterizations[localParamType] = m_MapOfFactors[fBiasID]->getVariableLocalParameterization(bias);
                                }

                                auto biasAtId = m_AllStates.data() + m_MapOfVariables[bias];
                                problem.AddParameterBlock(biasAtId, m_MapOfVariableDims[bias],
                                    mapOfLocalParameterizations[m_MapOfFactors[fBiasID]->getVariableType(bias)]);
                                parameterBlocks.push_back(biasAtId);

                                // fixed or free?
                                if (m_MapOfVariableIsConstant.at(bias)) {
                                    problem.SetParameterBlockConstant(biasAtId);
                                }
                                else {
                                    problem.SetParameterBlockVariable(biasAtId);
                                }
                                m_MapOfFactors[fBiasID]->preOptimizationUpdate(parameterBlocks); // update factor before the graph optimization is run

                                ceres::CostFunction* costFcn = m_MapOfFactors[fBiasID]->createFactorCostFcn();
                                ceres::LossFunctionWrapper* loss_function = m_MapOfFactors[fBiasID]->createFactorLossFcn();
                                m_MapOfFactorIDtoResidualID[fBiasID] = problem.AddResidualBlock(costFcn,
                                    loss_function, // loss_function
                                    parameterBlocks);
                            }
                        }
                    }

                }
            }
        }
    }

    optimizedNodeIDs.assign(optimizedNodeIDsSet.begin(), optimizedNodeIDsSet.end());
    fixedNodeIDs.assign(fixedNodeIDsSet.begin(), fixedNodeIDsSet.end());

    if (optStruct.LinearSolverOrdering.size() > 0)
    {
        // set linear solver ordering
        auto* ordering = new ceres::ParameterBlockOrdering;
        for (const auto &o : optStruct.LinearSolverOrdering)
        {
            ordering->AddElementToGroup((m_AllStates.data() + m_MapOfVariables[o.first]), o.second);
        }
        options.linear_solver_ordering.reset(ordering);
    }

    ceres::Solver::Summary summary;
    ceres::Solve(options, &problem, &summary);
    if (optStruct.VerbosityLevel >= 1) {
        std::cout << summary.FullReport() << endl;
    }

    vector<double> covariance{};
    set<int> covarianceNodeID{};
    if (CovarianceType.size() == 0)
        CovarianceType.push_back(-1);
    if (summary.termination_type != 2 && CovarianceType.front() != -1) {
        covarianceNodeID = getCovarianceNodeID(CovarianceType, ids);
        covariance = computeCovariance(problem, covarianceNodeID);
    }

    mw_ceres::CeresSolutionInfo infoStruct;
    infoStruct.Message = summary.message;
    infoStruct.TerminationType = summary.termination_type;
    infoStruct.IsSolutionUsable = summary.IsSolutionUsable();
    infoStruct.InitialCost = summary.initial_cost;
    infoStruct.FinalCost = summary.final_cost;
    infoStruct.NumSuccessfulSteps = summary.num_successful_steps;
    infoStruct.NumUnsuccessfulSteps = summary.num_unsuccessful_steps;
    infoStruct.TotalTime = summary.total_time_in_seconds;
    infoStruct.OptimizedNodeIDs = optimizedNodeIDs;
    infoStruct.FixedNodeIDs = fixedNodeIDs;

    if (storeProblem) {
        // Store the problem for advanced user to access outside of optimize function
        Problem = std::move(problem);
    }
    else {
        // Reset Problem
        Problem = ceres::Problem();
    }

    return infoStruct;
}

void mw_ceres::FactorGraph::optimize(double* opts, double* info, int* vid, int vidNum, int covarianceTypeNum, double* OptimizedIDs, double* OptimizedIDsLen,
    double* FixedIDs, double* FixedIDsLen) {
    mw_ceres::CeresSolverOptions optStruct;
    optStruct.MaxNumIterations = static_cast<int>(opts[0]);
    optStruct.FunctionTolerance = opts[1];
    optStruct.GradientTolerance = opts[2];
    optStruct.StepTolerance = opts[3];
    optStruct.VerbosityLevel = static_cast<int>(opts[4]);
    optStruct.TrustRegionStrategyType = static_cast<int>(opts[5]);
    std::vector<double> dCovTypes(opts+6,opts+6+static_cast<size_t>(covarianceTypeNum));
    std::vector<int> CovTypes(static_cast<size_t>(covarianceTypeNum));
    for(size_t k=0;k<CovTypes.size();k++){
        CovTypes[k] = static_cast<int>(dCovTypes[k]);
    }
    optStruct.CovarianceType = CovTypes;
    optStruct.InitialTrustRegionRadius = opts[6+static_cast<size_t>(covarianceTypeNum)];
    // internal optimization parameters not visible to users
    //optStruct.LinearSolverType = opts[7];
    //optStruct.DoglegType = opts[8];

    std::vector<int> ids(vid,vid+size_t(vidNum));

    // call optimize
    auto infoStruct = mw_ceres::FactorGraph::optimize(optStruct, ids);
    
    // fill output info
    double infoArray[] = {infoStruct.InitialCost,
                          infoStruct.FinalCost,
                          static_cast<double>(infoStruct.NumSuccessfulSteps),
                          static_cast<double>(infoStruct.NumUnsuccessfulSteps),
                          infoStruct.TotalTime,
                          static_cast<double>(infoStruct.TerminationType),
                          static_cast<double>(infoStruct.IsSolutionUsable)};
    for (int i=0;i<7;i++){
        *(info+i) = infoArray[i];
    }
    auto v1 = infoStruct.OptimizedNodeIDs;
    auto v2 = infoStruct.FixedNodeIDs;
    for(size_t k=0;k<v1.size();k++){
        OptimizedIDs[k] = static_cast<double>(v1[k]);
    }
    OptimizedIDsLen[0] = static_cast<double>(v1.size());
    for(size_t k=0;k<v2.size();k++){
        FixedIDs[k] = static_cast<double>(v2[k]);
    }
    FixedIDsLen[0] = static_cast<double>(v2.size());
}

void mw_ceres::FactorGraph::storeNodeIDs(unordered_map<int, std::set<int> >& map, int type, set<int> IDs) {
    if (map.find(type) == map.end()) {
        map[type] = IDs;
    } else {
        for (auto id : IDs)
            map[type].insert(id);
    }
}

void mw_ceres::FactorGraph::storeFactorTypes(unordered_map<int, unordered_map<int, set<int>>>& map,
    int fctrType, int node_type, set<int> IDs) {
    if (map.find(fctrType) == map.end()) {
        std::unordered_map<int, std::set<int>> m_nodetype{{node_type, IDs}};
        map[fctrType] = m_nodetype;
    } else {
        storeNodeIDs(map[fctrType], node_type, IDs);
    }
}

void mw_ceres::FactorGraph::storeGroups(unordered_map<int, unordered_map<int, unordered_map<int, set<int> > > >& map,
    int group, int fctrType, int node_type, set<int> IDs) {
    if (map.find(group) == map.end()) {
        unordered_map<int, unordered_map<int, set<int> > > m_fctrtype;
        unordered_map<int, set<int> > m_nodetype{{node_type, IDs}};
        m_fctrtype[fctrType] = m_nodetype;
        map[group] = m_fctrtype;
    } else {
        storeFactorTypes(map[group], fctrType, node_type, IDs);
    }
}

void mw_ceres::FactorGraph::storeByTwoGroupID(vector<int> GroupID, const size_t numGroupID, vector<int> IDs, const size_t numIds,
    int fctrType, int nodeType1, int nodeType2) {
    if (GroupID.front() != -1) {
        if (numGroupID == 2) {
            std::set<int> first;
            std::set<int> second;
            for (size_t i = 0; i < numIds; i++) {
                if (i % 2 == 0)
                    first.insert(IDs[i]);
                else
                    second.insert(IDs[i]);
            }
            storeGroups(m_MapOfGroup, GroupID[0], fctrType, nodeType1, first);
            storeGroups(m_MapOfGroup, GroupID[1], fctrType, nodeType2, second);
        } else {
            std::set<int> s;
            for (size_t i = 0; i < numGroupID; i++) {
                s = {IDs[i]};
                if (i % 2 == 0) storeGroups(m_MapOfGroup, GroupID[i], fctrType, nodeType1, s);
                else storeGroups(m_MapOfGroup, GroupID[i], fctrType, nodeType2, s);
            }
        }
    }
}

void mw_ceres::FactorGraph::storeByOneGroupID(vector<int> GroupID, const size_t numGroupID, vector<int> IDs, int fctrType,
    int nodeType, set<int> IDset) {
    if (GroupID.front() != -1) {
        if (numGroupID == 1) {
            storeGroups(m_MapOfGroup, GroupID[0], fctrType, nodeType, IDset);
        } else {
            std::set<int> s;
            for (size_t i = 0; i < numGroupID; i++) {
                s = {IDs[i]};
                storeGroups(m_MapOfGroup, GroupID[i], fctrType, nodeType, s);
            }
        }
    }
}

void mw_ceres::FactorGraph::storeIMU(std::vector<int> IDs, const std::vector<int>& groupID) {
    std::set<int> s;
    int fctrType = m_FactorType["IMU_F"];
    for (int& id : IDs) {
        s = { id };
        // Store node IDs under node types
        storeNodeIDs(m_MapOfNodeTypes, m_MapOfVariableTypes[id], s);
        // Store node types under factor types
        storeFactorTypes(m_MapOfFactorType, fctrType, m_MapOfVariableTypes[id], s);
    }
    // Store factor types and node types under groupID
    if (groupID.front() != -1) {
        if (groupID[0] == groupID[1]) {
            for (int& id : IDs) {
                s = { id };
                storeGroups(m_MapOfGroup, groupID[0], fctrType, m_MapOfVariableTypes[id], s);
            }
        }
        else {
            int id = 0;
            for (size_t i = 0; i < 3; i++) {
                id = IDs[i];
                s = { id };
                storeGroups(m_MapOfGroup, groupID[0], fctrType, m_MapOfVariableTypes[id], s);
            }
            for (size_t i = 3; i < 6; i++) {
                id = IDs[i];
                s = { id };
                storeGroups(m_MapOfGroup, groupID[1], fctrType, m_MapOfVariableTypes[id], s);
            }
        }
    }
}

void mw_ceres::FactorGraph::storeSIM3(std::vector<int> IDs, const std::vector<int>& groupID) {
    std::set<int> s;
    int id;
    int fctrType = FactorTypeEnum::Two_SIM3_F;
    bool validGroupID = (groupID.front() != -1);
    for (size_t i = 0; i < 3; i+=2) {
        id = IDs[i];
        s = { id };
        // Store node IDs under node types
        storeNodeIDs(m_MapOfNodeTypes, VariableType::Pose_SE3, s);
        // Store node types under factor types
        storeFactorTypes(m_MapOfFactorType, fctrType, VariableType::Pose_SE3, s);
        // Store factor types and node types under groupID
        if (validGroupID)
            storeGroups(m_MapOfGroup, groupID[0], fctrType, VariableType::Pose_SE3, s);
    }
    for (size_t i = 1; i < 4; i+=2) {
        id = IDs[i];
        s = { id };
        // Store node IDs under node types
        storeNodeIDs(m_MapOfNodeTypes, VariableType::Pose_SE3_Scale, s);
        // Store node types under factor types
        storeFactorTypes(m_MapOfFactorType, fctrType, VariableType::Pose_SE3_Scale, s);
        // Store factor types and node types under groupID
        if (validGroupID)
            storeGroups(m_MapOfGroup, groupID[1], fctrType, VariableType::Pose_SE3_Scale, s);
        }
}

/// Store factor ID information
void mw_ceres::FactorGraph::storeFactorID(int fID, int fctrType) {
    m_MapOfFactorIDtoFactorType[fID] = fctrType;
}

int mw_ceres::FactorGraph::addFactor(unique_ptr<mw_ceres::Factor> fctr) {
    auto factor = std::move(fctr);

    vector<int> varIDs = factor->getVariableIDs();
    if (varIDs.size() == 6) {
        // Validate factorIMU
        for (int& id : varIDs) {
            if (m_MapOfVariables.find(id) != m_MapOfVariables.end()) { // if the variable is already defined in the graph
                // reject if the variable dimension/type defined in factor does not match that in
                // graph and makes sure the factor graph is not affected in this case
                if (factor->getVariableDim(id) != m_MapOfVariableDims[id] ||
                    factor->getVariableType(id) != m_MapOfVariableTypes[id])
                    return -1;
            }
        }
    }

    for (int& id : varIDs) {
        // prepare variables if needed
        if (m_MapOfVariables.find(id) == m_MapOfVariables.end()) { // if variable has not yet been created with the graph
            auto defautState = factor->getDefaultState(id);
            size_t varIdx = m_AllStates.size();
            m_AllStates.insert(m_AllStates.end(), defautState.begin(), defautState.end());
            m_MapOfVariables[id] = varIdx; // initialize variable state to default values
            m_MapOfVariableDims[id] = factor->getVariableDim(id);
            m_MapOfVariableTypes[id] = factor->getVariableType(id);
            m_MapOfVariableIsConstant[id] = false;
        }
    }

    // only add the factor to internal map after its variable IDs check out
    m_MapOfFactors[m_UniqueFactorID] = std::move(factor);
    m_NumFactors = static_cast<int>(m_MapOfFactors.size());

    // the residual block related to this factor is NOT updated here, but right before graph optimization
    // see optimize() method

    int newFactorID = m_UniqueFactorID;
    m_UniqueFactorID++;

    // Add factorID under NodeID
    for (int& id : varIDs) {
        if (m_MapOfNodeIDtoFactorID.find(id) == m_MapOfNodeIDtoFactorID.end()) { // if node ID has not yet been added to the map
            unordered_set<int> s{ newFactorID };
            m_MapOfNodeIDtoFactorID[id] = s;
        }
        else {
            m_MapOfNodeIDtoFactorID[id].insert(newFactorID);
        }
    }

    return newFactorID;
}

std::vector<int> mw_ceres::FactorGraph::validateFactor(unique_ptr<mw_ceres::Factor> fctr, std::vector<int> IDs, int size) {
    std::vector<int> validness;
    int flag = 1;
    auto factor = std::move(fctr);
    size_t numIDs = IDs.size();
    for (size_t i = 0; i < numIDs; i++) {
        int id = IDs[i];
        if (m_MapOfVariables.find(id) != m_MapOfVariables.end()) { // if the variable is already defined in the graph
            // reject if the variable type defined in factor does not match that in graph
            // and makes sure the factor graph is not affected in this case
            int res = (static_cast<int>(i)) % size;
            if (factor->getVariableType(IDs[static_cast<size_t>(res)]) != m_MapOfVariableTypes[id]) {
                validness.push_back(id);
                flag = -1;
            }
        }
    }
    validness.push_back(flag);
    return validness;
}

std::vector<int> mw_ceres::FactorGraph::addCameraProjectionFactor(const char* factorType, const size_t factorTypeLen, const int* ids, const size_t numIds,
    const double* measurement, const size_t numMeasurement, const double* information, const size_t numInformation, const size_t numFactors,
    const int* groupID, const size_t numGroupID, const double* sensorTform) {

    std::vector<int> IDs(ids,ids+numIds);
    std::set<int> IDset;
    for (auto id : IDs) {
        IDset.insert(id);
    }
    std::vector<double> Measurement(measurement, measurement+numMeasurement);
    std::vector<double> Information(information, information+numInformation);
    std::vector<int> GroupID(groupID, groupID+numGroupID);

    std::vector<int> fId;
    std::string fctr_type(factorType, factorTypeLen);
    int fctrType = m_FactorType[fctr_type];

    ptrdiff_t lengthId = static_cast<ptrdiff_t>(numIds / numFactors);
    ptrdiff_t lengthMeasurement = static_cast<ptrdiff_t>(numMeasurement / numFactors);
    ptrdiff_t lengthInformation = static_cast<ptrdiff_t>(4);
    // Extract Ids for first factor
    std::vector<int>::iterator iterId = IDs.begin();
    std::vector<double>::iterator iterMeasurement = Measurement.begin();
    std::vector<double>::iterator iterInformation = Information.begin();
    std::vector<int> CurrentFactorIds(iterId, iterId + lengthId);
    std::vector<double> CurrentMeasurement(iterMeasurement, iterMeasurement + lengthMeasurement);
    std::vector<double> CurrentInformation(iterInformation, iterInformation + lengthInformation);
    std::vector<double> CurrentSensorTransform(sensorTform, sensorTform+16);

    auto f = std::make_unique<mw_ceres::FactorCameraSE3AndPointXYZ>(CurrentFactorIds);
    int nodeType1 = f->getVariableType(CurrentFactorIds[0]);
    int nodeType2 = f->getVariableType(CurrentFactorIds[1]);
    std::vector<int> validness = validateFactor(std::move(f), IDs, 2);
    if (validness.back() == -1) return validness;
    else {
        for (size_t i = 0; i < numFactors; i++) {
            CurrentFactorIds = { iterId, iterId + lengthId };
            CurrentMeasurement = { iterMeasurement, iterMeasurement + lengthMeasurement };
            CurrentInformation = { iterInformation, iterInformation + lengthInformation };
            f = std::make_unique<mw_ceres::FactorCameraSE3AndPointXYZ>(CurrentFactorIds);
            f->setMeasurement(CurrentMeasurement.data());
            if (f->getInformationLength() == numInformation) {
                // Shared information matrix
                f->setInformation(information);
            }
            else {
                f->setInformation(CurrentInformation.data());
                std::advance(iterInformation, lengthInformation);
            }
            f->setSensorTransform(CurrentSensorTransform.data());
            int newfID = addFactor(std::move(f));
            fId.push_back(newfID);
            m_MapOfFactorIDtoFactorType[newfID] = fctrType;
            std::advance(iterId, lengthId);
            std::advance(iterMeasurement, lengthMeasurement);
        }
        std::set<int> s1;
        std::set<int> s2;
        for (size_t i = 0; i < numIds; i++) {
            if (i % 2 == 0) s1.insert(IDs[i]);
            else s2.insert(IDs[i]);
        }
        storeNodeIDs(m_MapOfNodeTypes, nodeType1, s1);
        storeNodeIDs(m_MapOfNodeTypes, nodeType2, s2);
        storeFactorTypes(m_MapOfFactorType, fctrType, nodeType1, s1);
        storeFactorTypes(m_MapOfFactorType, fctrType, nodeType2, s2);
        storeByTwoGroupID(GroupID, numGroupID, IDs, numIds, fctrType, nodeType1, nodeType2);

    return fId;
    }
}

std::vector<int> mw_ceres::FactorGraph::addDistortedCameraProjectionFactor(const char* factorType, const size_t factorTypeLen, const int* ids, const size_t numIds,
    const double* measurement, const size_t numMeasurement, const double* information, const size_t numInformation, const size_t numFactors,
    const double* intrinsic,const size_t numIntrinsic, const double* sensorTransform,const size_t numSensorTransform, const int* groupID, const size_t numGroupID) {

    std::vector<int> IDs(ids,ids+numIds);
    std::set<int> IDset;
    for (auto id : IDs) {
        IDset.insert(id);
    }
    std::vector<double> Measurement(measurement, measurement+numMeasurement);
    std::vector<double> Information(information, information+numInformation);
    std::vector<double> tform(sensorTransform, sensorTransform+numSensorTransform);
    std::vector<int> GroupID(groupID, groupID+numGroupID);
    bool sharedGroupID = (numGroupID == 2);

    std::vector<int> fId;
    std::string fctr_type(factorType, factorTypeLen);
    int fctrType = FactorTypeEnum::Camera_SE3_Point3_F;//user-facing factor type for ID management

    // unified projection factor constructor
    auto projectionFactorConstructor = mw_ceres::createUnifiedProjectionFactorContructor(fctr_type);
    // intrinsic vector
    std::vector<double> ii;
    if (numIntrinsic > 0) {
        ii = std::vector<double>(intrinsic, intrinsic + static_cast<ptrdiff_t>(numIntrinsic));
    }

    // length of single factor input id, measurement and information matrix
    ptrdiff_t lengthId = static_cast<ptrdiff_t>(numIds / numFactors);
    ptrdiff_t lengthMeasurement = static_cast<ptrdiff_t>(numMeasurement / numFactors);
    ptrdiff_t lengthInformation = static_cast<ptrdiff_t>(numInformation / numFactors);
    ptrdiff_t lengthGroupID = static_cast<ptrdiff_t>(numGroupID / numFactors);
    std::vector<int> CurrentGroupIds;

    // Extract Ids for first factor
    std::vector<int>::iterator iterId = IDs.begin();
    std::vector<double>::iterator iterMeasurement = Measurement.begin();
    std::vector<double>::iterator iterInformation = Information.begin();
    std::vector<double>::iterator iterIntrinsic = ii.begin();
    std::vector<int>::iterator iterGroupID = GroupID.begin();
    std::vector<int> CurrentFactorIds(iterId, iterId + lengthId);
    std::vector<double> CurrentMeasurement(iterMeasurement, iterMeasurement + lengthMeasurement);
    std::vector<double> CurrentInformation(iterInformation, iterInformation + lengthInformation);

    // construct projection factor of specified type
    auto f = projectionFactorConstructor(CurrentFactorIds);
    size_t expectedNumNodes = f->getNumNodesToConnect();
    int nodeType1 = f->getVariableType(CurrentFactorIds[0]);
    int nodeType2, nodeType3;
    if (expectedNumNodes > 2){
        nodeType2 = f->getVariableType(CurrentFactorIds[expectedNumNodes-2]);
        nodeType3 = f->getVariableType(CurrentFactorIds[expectedNumNodes-1]);
    }
    else {
        nodeType2 = f->getVariableType(CurrentFactorIds[expectedNumNodes-1]);
        nodeType3 = -1;
    }
    size_t fixedIntrinsicLength = f->getFixedIntrinsicLength();
    ptrdiff_t lengthIntrinsic = static_cast<ptrdiff_t>(fixedIntrinsicLength);
    bool sharedIntrinsic = (numIntrinsic == fixedIntrinsicLength);
    bool validIntrinsic = (numIntrinsic > 0 && fixedIntrinsicLength > 0);
    bool sharedInformation = (f->getInformationLength() == numInformation);
    // validate the input ids, fill the factor and add it to the factor graph
    std::vector<int> validness = validateFactor(std::move(f), IDs, static_cast<int>(expectedNumNodes));
    if (validness.back() == -1) return validness;
    else {
        for (size_t i = 0; i < numFactors; i++) {
            CurrentFactorIds = { iterId, iterId + lengthId };
            CurrentMeasurement = { iterMeasurement, iterMeasurement + lengthMeasurement };
            f = projectionFactorConstructor(CurrentFactorIds);
            f->setMeasurement(CurrentMeasurement.data());
            f->setSensorTransform(tform);
            if (sharedInformation) {
                // Shared information matrix
                f->setInformation(information);
            }
            else {
                CurrentInformation = { iterInformation, iterInformation + lengthInformation };
                f->setInformation(CurrentInformation.data());
                std::advance(iterInformation, lengthInformation);
            }

            if (validIntrinsic && sharedIntrinsic)
                f->setIntrinsic(ii);
            else if (validIntrinsic && !sharedIntrinsic) {
                ii = {iterIntrinsic, iterIntrinsic + lengthIntrinsic};
                f->setIntrinsic(ii);
                std::advance(iterIntrinsic, lengthIntrinsic);
            }

            if (!sharedGroupID) {
                CurrentGroupIds = { iterGroupID, iterGroupID + lengthGroupID };
                storeGroups(m_MapOfGroup, CurrentGroupIds[0], fctrType, nodeType1, {CurrentFactorIds[0]});
                if (nodeType3 >= 0) {
                    storeGroups(m_MapOfGroup, CurrentGroupIds[0], fctrType, nodeType3, {CurrentFactorIds[expectedNumNodes-1]});
                    storeGroups(m_MapOfGroup, CurrentGroupIds[1], fctrType, nodeType2, {CurrentFactorIds[expectedNumNodes-2]}); 
                }
                else {
                    storeGroups(m_MapOfGroup, CurrentGroupIds[1], fctrType, nodeType2, {CurrentFactorIds[expectedNumNodes-1]});
                }
                std::advance(iterGroupID, lengthGroupID);
            }
            
            int newfID = addFactor(std::move(f));
            fId.push_back(newfID);
            m_MapOfFactorIDtoFactorType[newfID] = fctrType;
            std::advance(iterId, lengthId);
            std::advance(iterMeasurement, lengthMeasurement);
        }
        std::set<int> s1, s2, s3;
        for (size_t i = 0; i < numIds; i += expectedNumNodes) {
            if (nodeType3 >= 0) {
                s1.insert(IDs[i]);
                s2.insert(IDs[i+expectedNumNodes-2]);
                s3.insert(IDs[i+expectedNumNodes-1]);
            }
            else {
                s1.insert(IDs[i]);
                s2.insert(IDs[i+expectedNumNodes-1]);
            }
        }
        storeNodeIDs(m_MapOfNodeTypes, nodeType1, s1);
        storeNodeIDs(m_MapOfNodeTypes, nodeType2, s2);
        storeFactorTypes(m_MapOfFactorType, fctrType, nodeType1, s1);
        storeFactorTypes(m_MapOfFactorType, fctrType, nodeType2, s2);
        if (nodeType3 >= 0) {
            storeNodeIDs(m_MapOfNodeTypes, nodeType3, s3);
            storeFactorTypes(m_MapOfFactorType, fctrType, nodeType3, s3);
        }
        if (sharedGroupID) {
            storeGroups(m_MapOfGroup, GroupID[0], fctrType, nodeType1, s1);
            storeGroups(m_MapOfGroup, GroupID[1], fctrType, nodeType2, s2);
            if (nodeType3 >= 0)
                storeGroups(m_MapOfGroup, GroupID[0], fctrType, nodeType3, s3);
        }

    return fId;
    }
}

std::vector<int> mw_ceres::FactorGraph::addGaussianFactor(const char* factorType, const size_t factorTypeLen, const int* ids, const size_t numIds,
    const double* measurement, const size_t numMeasurement, const double* information, const size_t numInformation, const size_t numFactors,
    const int* groupID, const size_t numGroupID) {

    std::vector<int> IDs(ids,ids+numIds);
    std::set<int> IDset;
    for (auto id : IDs) {
        IDset.insert(id);
    }
    std::vector<double> Measurement(measurement, measurement+numMeasurement);
    std::vector<double> Information(information, information+numInformation);
    std::vector<int> GroupID(groupID, groupID+numGroupID);
    bool sharedGroupID = (numGroupID == 2);

    std::vector<int> fId;
    std::unique_ptr<mw_ceres::FactorGaussianNoiseModel> f;
    std::string fctr_type(factorType, factorTypeLen);
    int fctrType = m_FactorType[fctr_type];

    ptrdiff_t lengthId = static_cast<ptrdiff_t>(numIds / numFactors);
    ptrdiff_t lengthMeasurement = static_cast<ptrdiff_t>(numMeasurement / numFactors);
    ptrdiff_t lengthInformation = static_cast<ptrdiff_t>(numInformation / numFactors);
    ptrdiff_t lengthGroupID = static_cast<ptrdiff_t>(numGroupID / numFactors);
    // Extract Ids for first factor
    std::vector<int>::iterator iterId = IDs.begin();
    std::vector<double>::iterator iterMeasurement = Measurement.begin();
    std::vector<double>::iterator iterInformation = Information.begin();
    std::vector<int>::iterator iterGroupID = GroupID.begin();
    std::vector<int> CurrentFactorIds(iterId, iterId + lengthId);
    std::vector<double> CurrentMeasurement(iterMeasurement, iterMeasurement + lengthMeasurement);
    std::vector<double> CurrentInformation(iterInformation, iterInformation + lengthInformation);
    std::vector<int> CurrentGroupIds;

    switch (m_FactorType[fctr_type]) {
        case mw_ceres::FactorTypeEnum::Two_SE2_F: {
            // Generate factor for validation
            f = std::make_unique<mw_ceres::FactorTwoPosesSE2>(CurrentFactorIds);
            int nodeType = f->getVariableType(CurrentFactorIds[0]);
            std::vector<int> validness = validateFactor(std::move(f), IDs, 2);
            if (validness.back() == -1) return validness;
            else {
                for (size_t i = 0; i < numFactors; i++) {
                    CurrentFactorIds = { iterId, iterId + lengthId };
                    CurrentMeasurement = { iterMeasurement, iterMeasurement + lengthMeasurement };
                    CurrentInformation = { iterInformation, iterInformation + lengthInformation };
                    f = std::make_unique<mw_ceres::FactorTwoPosesSE2>(CurrentFactorIds);
                    f->setMeasurement(CurrentMeasurement.data());
                    if (f->getInformationLength() == numInformation) {
                        // Shared information matrix
                        f->setInformation(information);
                    }
                    else {
                        f->setInformation(CurrentInformation.data());
                        std::advance(iterInformation, lengthInformation);
                    }
                    fId.push_back(addFactor(std::move(f)));
                    std::advance(iterId, lengthId);
                    std::advance(iterMeasurement, lengthMeasurement);
                }
                // Store node IDs under node types
                storeNodeIDs(m_MapOfNodeTypes, nodeType, IDset);
                // Store node types under factor types
                storeFactorTypes(m_MapOfFactorType, fctrType, nodeType, IDset);
                // Store factor types and node types under groupID
                storeByTwoGroupID(GroupID, numGroupID, IDs, numIds, fctrType, nodeType, nodeType);
            }
            break;
        }
        case mw_ceres::FactorTypeEnum::Two_SE3_F: {
            f = std::make_unique<mw_ceres::FactorTwoPosesSE3>(CurrentFactorIds);
            int nodeType = f->getVariableType(CurrentFactorIds[0]);
            lengthInformation = static_cast<ptrdiff_t>(f->getInformationLength());
            std::vector<int> validness = validateFactor(std::move(f), IDs, 2);
            if (validness.back() == -1) return validness;
            else {
                for (size_t i = 0; i < numFactors; i++) {
                    CurrentFactorIds = { iterId, iterId + lengthId };
                    CurrentMeasurement = { iterMeasurement, iterMeasurement + lengthMeasurement};
                    CurrentInformation = { iterInformation, iterInformation + lengthInformation};
                    f = std::make_unique<mw_ceres::FactorTwoPosesSE3>(CurrentFactorIds);
                    f->setMeasurement(CurrentMeasurement.data());
                    if (f->getInformationLength() == numInformation) {
                        // Shared information matrix
                        f->setInformation(information);
                    }
                    else {
                        f->setInformation(CurrentInformation.data());
                        std::advance(iterInformation, lengthInformation);
                    }
                    fId.push_back(addFactor(std::move(f)));
                    std::advance(iterId, lengthId);
                    std::advance(iterMeasurement, lengthMeasurement);
                }
                storeNodeIDs(m_MapOfNodeTypes, nodeType, IDset);
                storeFactorTypes(m_MapOfFactorType, fctrType, nodeType, IDset);
                storeByTwoGroupID(GroupID, numGroupID, IDs, numIds, fctrType, nodeType, nodeType);
            }
            break;
        }
        case mw_ceres::FactorTypeEnum::Two_SIM3_F: {
            f = std::make_unique<mw_ceres::FactorTwoPosesSIM3>(CurrentFactorIds);
            std::vector<int> validness = validateFactor(std::move(f), IDs, 2);
            if (validness.back() == -1) return validness;
            else {
                for (size_t i = 0; i < numFactors; i++) {
                    CurrentFactorIds = { iterId, iterId + lengthId };
                    CurrentMeasurement = { iterMeasurement, iterMeasurement + lengthMeasurement};
                    f = std::make_unique<mw_ceres::FactorTwoPosesSIM3>(CurrentFactorIds);
                    f->setMeasurement(CurrentMeasurement.data());
                    if (f->getInformationLength() == numInformation) {
                        // Shared information matrix
                        f->setInformation(information);
                    }
                    else {
                        CurrentInformation = { iterInformation, iterInformation + lengthInformation};
                        f->setInformation(CurrentInformation.data());
                        std::advance(iterInformation, lengthInformation);
                    }
                    fId.push_back(addFactor(std::move(f)));
                    if (sharedGroupID)
                        storeSIM3(CurrentFactorIds, GroupID);
                    else {
                        CurrentGroupIds = { iterGroupID, iterGroupID + lengthGroupID };
                        storeSIM3(CurrentFactorIds, CurrentGroupIds);
                        std::advance(iterGroupID, lengthGroupID);
                    }
                    std::advance(iterId, lengthId);
                    std::advance(iterMeasurement, lengthMeasurement);
                }
            }
            break;
        }
        case mw_ceres::FactorTypeEnum::GPS_F: {
            f = std::make_unique<mw_ceres::FactorSimpleGPS>(CurrentFactorIds);
            int nodeType = f->getVariableType(CurrentFactorIds[0]);
            std::vector<int> validness = validateFactor(std::move(f), IDs, 1);
            if (validness.back() == -1) return validness;
            else {
                for (size_t i = 0; i < numFactors; i++) {
                    CurrentFactorIds = { iterId, iterId + lengthId};
                    CurrentMeasurement = { iterMeasurement, iterMeasurement + lengthMeasurement};
                    CurrentInformation = { iterInformation, iterInformation + lengthInformation};
                    f = std::make_unique<mw_ceres::FactorSimpleGPS>(CurrentFactorIds);
                    f->setMeasurement(CurrentMeasurement.data());
                    if (f->getInformationLength() == numInformation) {
                        // Shared information matrix
                        f->setInformation(information);
                    }
                    else {
                        f->setInformation(CurrentInformation.data());
                        std::advance(iterInformation, lengthInformation);
                    }
                    fId.push_back(addFactor(std::move(f)));
                    std::advance(iterId, lengthId);
                    std::advance(iterMeasurement, lengthMeasurement);
                }
                storeNodeIDs(m_MapOfNodeTypes, nodeType, IDset);
                storeFactorTypes(m_MapOfFactorType, fctrType, nodeType, IDset);
                storeByOneGroupID(GroupID, numGroupID, IDs, fctrType, nodeType, IDset);
            }
            break;
        }
        case mw_ceres::FactorTypeEnum::SE3_Prior_F: {
            f = std::make_unique<mw_ceres::FactorPoseSE3Prior>(CurrentFactorIds);
            int nodeType = f->getVariableType(CurrentFactorIds[0]);
            std::vector<int> validness = validateFactor(std::move(f), IDs, 1);
            if (validness.back() == -1) return validness;
            else {
                for (size_t i = 0; i < numFactors; i++) {
                    CurrentFactorIds = { iterId, iterId + lengthId };
                    CurrentMeasurement = { iterMeasurement, iterMeasurement + lengthMeasurement };
                    CurrentInformation = { iterInformation, iterInformation + lengthInformation };
                    f = std::make_unique<mw_ceres::FactorPoseSE3Prior>(CurrentFactorIds);
                    f->setMeasurement(CurrentMeasurement.data());
                    if (f->getInformationLength() == numInformation) {
                        // Shared information matrix
                        f->setInformation(information);
                    }
                    else {
                        f->setInformation(CurrentInformation.data());
                        std::advance(iterInformation, lengthInformation);
                    }
                    fId.push_back(addFactor(std::move(f)));
                    std::advance(iterId, lengthId);
                    std::advance(iterMeasurement, lengthMeasurement);
                }
                storeNodeIDs(m_MapOfNodeTypes, nodeType, IDset);
                storeFactorTypes(m_MapOfFactorType, fctrType, nodeType, IDset);
                storeByOneGroupID(GroupID, numGroupID, IDs, fctrType, nodeType, IDset);
            }
            break;
        }
        case mw_ceres::FactorTypeEnum::SE2_Prior_F: {
            f = std::make_unique<mw_ceres::FactorPoseSE2Prior>(CurrentFactorIds);
            int nodeType = f->getVariableType(CurrentFactorIds[0]);
            std::vector<int> validness = validateFactor(std::move(f), IDs, 1);
            if (validness.back() == -1) return validness;
            else {
                for (size_t i = 0; i < numFactors; i++) {
                    CurrentFactorIds = { iterId, iterId + lengthId };
                    CurrentMeasurement = { iterMeasurement, iterMeasurement + lengthMeasurement };
                    CurrentInformation = { iterInformation, iterInformation + lengthInformation };
                    f = std::make_unique<mw_ceres::FactorPoseSE2Prior>(CurrentFactorIds);
                    f->setMeasurement(CurrentMeasurement.data());
                    if (f->getInformationLength() == numInformation) {
                        // Shared information matrix
                        f->setInformation(information);
                    }
                    else {
                        f->setInformation(CurrentInformation.data());
                        std::advance(iterInformation, lengthInformation);
                    }
                    fId.push_back(addFactor(std::move(f)));
                    std::advance(iterId, lengthId);
                    std::advance(iterMeasurement, lengthMeasurement);
                }
                storeNodeIDs(m_MapOfNodeTypes, nodeType, IDset);
                storeFactorTypes(m_MapOfFactorType, fctrType, nodeType, IDset);
                storeByOneGroupID(GroupID, numGroupID, IDs, fctrType, nodeType, IDset);
            }
            break;
        }
        case mw_ceres::FactorTypeEnum::IMU_Bias_Prior_F: {
            f = std::make_unique<mw_ceres::FactorIMUBiasPrior>(CurrentFactorIds);
            int nodeType = f->getVariableType(CurrentFactorIds[0]);
            std::vector<int> validness = validateFactor(std::move(f), IDs, 1);
            if (validness.back() == -1) return validness;
            else {
                for (size_t i = 0; i < numFactors; i++) {
                    CurrentFactorIds = { iterId, iterId + lengthId };
                    CurrentMeasurement = { iterMeasurement, iterMeasurement + lengthMeasurement };
                    CurrentInformation = { iterInformation, iterInformation + lengthInformation };
                    f = std::make_unique<mw_ceres::FactorIMUBiasPrior>(CurrentFactorIds);
                    f->setMeasurement(CurrentMeasurement.data());
                    if (f->getInformationLength() == numInformation) {
                        // Shared information matrix
                        f->setInformation(information);
                    }
                    else {
                        f->setInformation(CurrentInformation.data());
                        std::advance(iterInformation, lengthInformation);
                    }
                    fId.push_back(addFactor(std::move(f)));
                    std::advance(iterId, lengthId);
                    std::advance(iterMeasurement, lengthMeasurement);
                }
                storeNodeIDs(m_MapOfNodeTypes, nodeType, IDset);
                storeFactorTypes(m_MapOfFactorType, fctrType, nodeType, IDset);
                storeByOneGroupID(GroupID, numGroupID, IDs, fctrType, nodeType, IDset);
            }
            break;
        }
        case mw_ceres::FactorTypeEnum::Vel3_Prior_F: {
            f = std::make_unique<mw_ceres::FactorVel3Prior>(CurrentFactorIds);
            int nodeType = f->getVariableType(CurrentFactorIds[0]);
            std::vector<int> validness = validateFactor(std::move(f), IDs, 1);
            if (validness.back() == -1) return validness;
            else {
                for (size_t i = 0; i < numFactors; i++) {
                    CurrentFactorIds = { iterId, iterId + lengthId };
                    CurrentMeasurement = { iterMeasurement, iterMeasurement + lengthMeasurement };
                    CurrentInformation = { iterInformation, iterInformation + lengthInformation };
                    f = std::make_unique<mw_ceres::FactorVel3Prior>(CurrentFactorIds);
                    f->setMeasurement(CurrentMeasurement.data());
                    if (f->getInformationLength() == numInformation) {
                        // Shared information matrix
                        f->setInformation(information);
                    }
                    else {
                        f->setInformation(CurrentInformation.data());
                        std::advance(iterInformation, lengthInformation);
                    }
                    fId.push_back(addFactor(std::move(f)));
                    std::advance(iterId, lengthId);
                    std::advance(iterMeasurement, lengthMeasurement);
                }
                storeNodeIDs(m_MapOfNodeTypes, nodeType, IDset);
                storeFactorTypes(m_MapOfFactorType, fctrType, nodeType, IDset);
                storeByOneGroupID(GroupID, numGroupID, IDs, fctrType, nodeType, IDset);
            }
            break;
        }
        case mw_ceres::FactorTypeEnum::SE2_Point2_F: {
            // Validation all IDs. If any invalid, error out. If valid, add factors in sequence.
            // Create a factor for validation
            f = std::make_unique<mw_ceres::FactorPoseSE2AndPoint2>(CurrentFactorIds);
            int nodeType1 = f->getVariableType(CurrentFactorIds[0]);
            int nodeType2 = f->getVariableType(CurrentFactorIds[1]);
            std::vector<int> validness = validateFactor(std::move(f), IDs, 2);
            if (validness.back() == -1) return validness;
            else {
                for (size_t i = 0; i < numFactors; i++) {
                    CurrentFactorIds = { iterId, iterId + lengthId};
                    CurrentMeasurement = { iterMeasurement, iterMeasurement + lengthMeasurement};
                    CurrentInformation = { iterInformation, iterInformation + lengthInformation};
                    f = std::make_unique<mw_ceres::FactorPoseSE2AndPoint2>(CurrentFactorIds);
                    f->setMeasurement(CurrentMeasurement.data());
                    if (f->getInformationLength() == numInformation) {
                        // Shared information matrix
                        f->setInformation(information);
                    }
                    else {
                        f->setInformation(CurrentInformation.data());
                        std::advance(iterInformation, lengthInformation);
                    }
                    fId.push_back(addFactor(std::move(f)));
                    std::advance(iterId, lengthId);
                    std::advance(iterMeasurement, lengthMeasurement);
                }
                std::set<int> s1;
                std::set<int> s2;
                for (size_t i = 0; i < numIds; i++) {
                    if (i % 2 == 0) s1.insert(IDs[i]);
                    else s2.insert(IDs[i]);
                }
                storeNodeIDs(m_MapOfNodeTypes, nodeType1, s1);
                storeNodeIDs(m_MapOfNodeTypes, nodeType2, s2);
                storeFactorTypes(m_MapOfFactorType, fctrType, nodeType1, s1);
                storeFactorTypes(m_MapOfFactorType, fctrType, nodeType2, s2);
                storeByTwoGroupID(GroupID, numGroupID, IDs, numIds, fctrType, nodeType1, nodeType2);
            }
            break;
        }
        case mw_ceres::FactorTypeEnum::SE3_Point3_F: {
            f = std::make_unique<mw_ceres::FactorPoseSE3AndPoint3>(CurrentFactorIds);
            int nodeType1 = f->getVariableType(CurrentFactorIds[0]);
            int nodeType2 = f->getVariableType(CurrentFactorIds[1]);
            std::vector<int> validness = validateFactor(std::move(f), IDs, 2);
            if (validness.back() == -1) return validness;
            else {
                for (size_t i = 0; i < numFactors; i++) {
                    CurrentFactorIds = { iterId, iterId + lengthId};
                    CurrentMeasurement = { iterMeasurement, iterMeasurement + lengthMeasurement};
                    CurrentInformation = { iterInformation, iterInformation + lengthInformation};
                    f = std::make_unique<mw_ceres::FactorPoseSE3AndPoint3>(CurrentFactorIds);
                    f->setMeasurement(CurrentMeasurement.data());
                    if (f->getInformationLength() == numInformation) {
                        // Shared information matrix
                        f->setInformation(information);
                    }
                    else {
                        f->setInformation(CurrentInformation.data());
                        std::advance(iterInformation, lengthInformation);
                    }
                    fId.push_back(addFactor(std::move(f)));
                    std::advance(iterId, lengthId);
                    std::advance(iterMeasurement, lengthMeasurement);
                }
                std::set<int> s1;
                std::set<int> s2;
                for (size_t i = 0; i < numIds; i++) {
                    if (i % 2 == 0) s1.insert(IDs[i]);
                    else s2.insert(IDs[i]);
                }
                storeNodeIDs(m_MapOfNodeTypes, nodeType1, s1);
                storeNodeIDs(m_MapOfNodeTypes, nodeType2, s2);
                storeFactorTypes(m_MapOfFactorType, fctrType, nodeType1, s1);
                storeFactorTypes(m_MapOfFactorType, fctrType, nodeType2, s2);
                storeByTwoGroupID(GroupID, numGroupID, IDs, numIds, fctrType, nodeType1, nodeType2);
            }
            break;
        }
        default:
            break;
    }
    for (auto newfID : fId) {
        m_MapOfFactorIDtoFactorType[newfID] = fctrType;
    }
    return fId;
}


bool mw_ceres::FactorGraph::isConnected(const vector<int>& IDs) {

    // use Union-Find algorithm to examine the connectivity of the graph
    auto Union = [](unordered_map<int, int>& parent, unordered_map<int, int>& count, int id1, int id2) {
        auto Find = [](unordered_map<int, int>& parent1, int id) -> int {
            while (parent1.at(id) != id) {
                parent1.at(id) = parent1.at(parent1.at(id));
                id = parent1.at(id);
            }
            return id;
        };
        int pid1 = Find(parent, id1);
        int pid2 = Find(parent, id2);
        if (pid1 == pid2)
            return;
        if (count.at(pid1) >= count.at(pid2)) {
            parent.at(pid2) = pid1;
            count.at(pid1) += count.at(pid2);
        } else {
            parent.at(pid1) = pid2;
            count.at(pid2) += count.at(pid1);
        }
        return;
    };

    unordered_map<int, int> parent;
    unordered_map<int, int> count;

    vector<int> allIDs{IDs};
    // Check existence


    if (IDs.front() == -1) {
        allIDs = getAllVariableIDs({-1}, "None", "None");
    }

    for (auto& id: allIDs) {
        parent[id] = id;
        count[id] = 1;
    }
    if (IDs.front() == -1) {
        map<int, unique_ptr<Factor>>::const_iterator it;
        for (it = m_MapOfFactors.begin(); it != m_MapOfFactors.end(); it++) {
            vector<int> vIds = it->second->getVariableIDs();
            int vid0 = vIds[0];
            for (size_t j = 1; j < vIds.size(); j++) {
                Union(parent, count, vid0, vIds[j]);
            }
        }
    }
    else {
        // keep track of whether the factor is checked or not
        vector<int> factorIDs;
        for (auto poseid: IDs) {
            for (auto fID : m_MapOfNodeIDtoFactorID[poseid]) {
                if (find(factorIDs.begin(), factorIDs.end(), fID) == factorIDs.end()) {
                    factorIDs.push_back(fID);
                    vector<int> varIDs = m_MapOfFactors[fID]->getVariableIDs();
                    // Skip the factor including other pose nodes
                    int skip = 0;
                    int fctrType = m_MapOfFactorIDtoFactorType[fID];
                    if (fctrType == 0 || fctrType == 1) {
                        // 0: TwoPoseSE2 1: TwoPoseSE3
                        for (const int& id : varIDs) {
                            if (std::find(IDs.begin(), IDs.end(), id) == IDs.end()) {
                                skip = 1;
                                break;
                            }
                        }
                    }
                    else if (fctrType == 4) {
                        // 4: IMU
                        if (std::find(IDs.begin(), IDs.end(), varIDs[0]) == IDs.end() || std::find(IDs.begin(), IDs.end(), varIDs[3]) == IDs.end()) {
                            skip = 1;
                            break;
                        }
                    }
                    if (skip) continue;
                    int varID0 = varIDs[0];
                    if (find(allIDs.begin(), allIDs.end(), varID0) == allIDs.end()) {
                        parent[varID0] = varID0;
                        count[varID0] = 1;
                        allIDs.push_back(varID0);
                    }
                    for (size_t j = 1; j < varIDs.size(); j++) {
                        if (find(allIDs.begin(), allIDs.end(), varIDs[j]) == allIDs.end()) {
                            parent[varIDs[j]] = varIDs[j];
                            count[varIDs[j]] = 1;
                            allIDs.push_back(varIDs[j]);
                        }
                        Union(parent, count, varID0, varIDs[j]);
                    }
                }
            }
        }
    }

    int numConnectedComponents = 0;
    for (auto& id: allIDs) {
        if (parent.at(id) == id) {
            numConnectedComponents++;
        }
    }

    return numConnectedComponents == 1 ? true : false;
}

bool mw_ceres::FactorGraph::isPoseNode(vector<int> IDs) {
    sort(IDs.begin(), IDs.end());
    vector<int> SE3nodes =  getAllVariableIDs({ -1 }, "POSE_SE3", "None");
    sort(SE3nodes.begin(), SE3nodes.end());
    if (includes(SE3nodes.begin(), SE3nodes.end(), IDs.begin(), IDs.end())) return true;
    vector<int> SE2nodes =  getAllVariableIDs({ -1 }, "POSE_SE2", "None");
    sort(SE2nodes.begin(), SE2nodes.end());
    if (includes(SE2nodes.begin(), SE2nodes.end(), IDs.begin(), IDs.end())) return true;
    return false;
}

int mw_ceres::FactorGraph::addVariable(int id, vector<double> state, int varType) {
    auto iter = m_MapOfVariables.find(id);
    // if the variable was already created, this function behaves like setVariableState
    if (iter != m_MapOfVariables.end()) {
        // reject if either the state dimension or variable type mismatches
        if (int(state.size()) != m_MapOfVariableDims[id] || varType != m_MapOfVariableTypes[id])
            return false;

        // only replace the vector content, but keep the underlying data array pointer unchanged
        // (cannot use copy assignment)
        auto data = m_AllStates.data() + iter->second;
        for (size_t i = 0; i < state.size(); i++) {
            data[i] = state[i];
        }
    } else {
        size_t varIdx = m_AllStates.size();
        m_AllStates.insert(m_AllStates.end(), state.begin(), state.end());
        m_MapOfVariables[id] = varIdx;
        m_MapOfVariableDims[id] = static_cast<int>(state.size());
        m_MapOfVariableTypes[id] = varType;
        m_MapOfVariableIsConstant[id] = false;
    }
    return true;
}

std::vector<int> mw_ceres::FactorGraph::setVariableState(const vector<int>& ids, const vector<double>& var, int size) {
    std::vector<int> validness = validateExistence(ids);

    if (validness.back() == -1) {
        // There are nodes not in the graph
        return validness;
    }

    int type = m_MapOfVariableTypes[ids[0]];
    validness = validateType(ids, type);
    if (validness.back() == -2) {
        // There are nodes with different types
        return validness;
    }

    if (size != m_MapOfVariableDims[ids[0]]) {
        // Wrong size for the given node type
        validness = {-3};
        return validness;
    }

    validness.pop_back();
    int base = 0;
    for (auto id : ids) {
        auto iter = m_MapOfVariables.find(id);
        // only replace the vector content, but keep the underlying data array pointer unchanged
        // (cannot use copy assignment)
        auto data = m_AllStates.data() + iter->second;
        for (int i = 0; i < size; i++) {
            data[i] = var[static_cast<size_t>(base + i)];
        }
        base += size;
    }
    return validness;
}

std::vector<int> mw_ceres::FactorGraph::getAllVariableIDs(std::vector<int> groupID, std::string nodeType, std::string factorType) const{
    std::set<int> ids;
    if (groupID.front() != -1) {
        // groupID specified   m_MapOfGroup
        if (factorType.compare("None") != 0) {
            // factor type specified 
            int fctrType = FactorTypeInt[factorType];
            if (nodeType.compare("None") != 0) {
                // node type specified
                int node_type = NodeTypeInt[nodeType];
                for (auto id : groupID) {
                    if (m_MapOfGroup.find(id) != m_MapOfGroup.end()) {
                        auto& m_factor = m_MapOfGroup.at(id);
                        if (m_factor.find(fctrType) != m_factor.end()) {
                            auto& m_node = m_factor.at(fctrType);
                            if (m_node.find(node_type) != m_node.end()) {
                                auto& s_node = m_node.at(node_type);
                                for (auto i : s_node) {
                                    ids.insert(i);
                                }
                            }
                        }
                    }
                }
            }
            else {
                // All node types
                for (auto id : groupID) {
                    if (m_MapOfGroup.find(id) != m_MapOfGroup.end()) {
                        auto& m_factor = m_MapOfGroup.at(id);
                        if (m_factor.find(fctrType) != m_factor.end()) {
                            auto& m_node = m_factor.at(fctrType);
                            for (auto& m : m_node) {
                                auto& s_node = m.second;
                                for (auto i : s_node) {
                                    ids.insert(i);
                                }
                            }
                        }
                    }
                }
            }
        }
        else {
            // All factor types
            if (nodeType.compare("None") != 0) {
                // node type specified
                int node_type = NodeTypeInt[nodeType];
                for (auto id : groupID) {
                    if (m_MapOfGroup.find(id) != m_MapOfGroup.end()) {
                        auto& m_factor = m_MapOfGroup.at(id);
                        for (auto& p : m_factor) {
                            auto& m_node = p.second;
                            if (m_node.find(node_type) != m_node.end()) {
                                auto& s_node = m_node.at(node_type);
                                for (auto i : s_node) {
                                    ids.insert(i);
                                }
                            }
                        }
                    }
                }
            } else {
                // All node types
                for (auto id : groupID) {
                    if (m_MapOfGroup.find(id)!=m_MapOfGroup.end()) {
                        auto& m_factor = m_MapOfGroup.at(id);
                        for (auto& p : m_factor) {
                            auto& m_node = p.second;
                            for (auto& m : m_node) {
                                auto& s_node = m.second;
                                for (auto i : s_node) {
                                    ids.insert(i);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    else {
        // All group IDs
        if (factorType.compare("None") != 0) {
            // factor type specified   m_MapOfFactorType
            int fctrType = FactorTypeInt[factorType];
            if (nodeType.compare("None") != 0) {
                // node type specified
                int node_type = NodeTypeInt[nodeType];
                if (m_MapOfFactorType.find(fctrType) != m_MapOfFactorType.end()) {
                    auto& m_node = m_MapOfFactorType.at(fctrType);
                    if (m_node.find(node_type) != m_node.end()) {
                        auto& s_node = m_node.at(node_type);
                        for (auto i : s_node) {
                            ids.insert(i);
                        }
                    }
                }
            } else {
                // All node types
                if (m_MapOfFactorType.find(fctrType) != m_MapOfFactorType.end()) {
                    auto& m_node = m_MapOfFactorType.at(fctrType);
                    for (auto& m : m_node) {
                        auto& s_node = m.second;
                        for (auto i : s_node) {
                            ids.insert(i);
                        }
                    }
                }
            }
        } else {
            // All factor types
            if (nodeType.compare("None") != 0) {
                // node type specified  m_MapOfNodeTypes
                int node_type = NodeTypeInt[nodeType];
                if (m_MapOfNodeTypes.find(node_type) != m_MapOfNodeTypes.end()) {
                    auto& s_node = m_MapOfNodeTypes.at(node_type);
                    for (auto i : s_node) {
                        ids.insert(i);
                    }
                }
            } else {
                // All node types
                for (auto& p : m_MapOfVariables) {
                    ids.insert(p.first);
                }
            }
        }
    }

    std::vector<int> idsVec;
    idsVec.assign(ids.begin(), ids.end());
    return idsVec;
}

std::vector<int> mw_ceres::FactorGraph::getEdge(int fctrType) {
    std::vector<int> edge;
    vector<int> varIDs;
    for (const auto& fp : m_MapOfFactors) {
        int factorType = m_MapOfFactorIDtoFactorType[fp.first];
        if (fctrType == factorType) {
            varIDs = fp.second->getVariableIDs();
            for (const int& id : varIDs) {
                edge.push_back(id);
            }
        }
    }
    return edge;
}

std::vector<int> mw_ceres::FactorGraph::removeFactor(const std::vector<int>& id) {
    // Check whether the factor exist in the graph
    std::vector<int> validness = validateFactorExistence(id);

    if (validness.back() == -1) {
        // There are factors not in the graph
        return validness;
    }

    removeFactorByFactorID(id);
    return removeDanglingNode();
}

std::vector<int> mw_ceres::FactorGraph::removeNode(const std::vector<int>& id) {
    // Check whether the nodes exist in the graph
    std::vector<int> validness = validateExistence(id);
    if (validness.back() == -1) {
        // There are nodes not in the graph
        return validness;
    }

    std::vector<int> removedSumFactorIDs;
    for (auto node : id) {
        // Find related factor ids
        auto& factors = m_MapOfNodeIDtoFactorID[node];
        std::vector<int> vf(factors.begin(), factors.end());
        removeFactorByFactorID(vf);
        removedSumFactorIDs.insert(removedSumFactorIDs.end(), vf.begin(), vf.end());
    }

    std::vector<int> output;
    output = removeDanglingNode();
    int nodeSize = static_cast<int>(output.size());
    std::sort(removedSumFactorIDs.begin(), removedSumFactorIDs.end());
    output.insert(output.end(), removedSumFactorIDs.begin(), removedSumFactorIDs.end());
    output.push_back(nodeSize);

    return output;
}

std::vector<int> mw_ceres::FactorGraph::removeDanglingNode() {
    // Iterate the node list, if they are dangling remove them
    std::vector<int> removedNodeIDs;

    for (auto node : m_DanglingNodes) {
        // Check whether the node is dangling
        if (m_MapOfNodeIDtoFactorID[node].size() == 0) {
            int nodeType = m_MapOfVariableTypes[node];
            m_MapOfVariables.erase(node);
            m_MapOfVariableDims.erase(node);
            m_MapOfVariableTypes.erase(node);
            m_MapOfVariableIsConstant.erase(node);
            m_MapOfNodeTypes[nodeType].erase(node);
            if (m_MapOfNodeTypes[nodeType].empty()) m_MapOfNodeTypes.erase(nodeType);
            for (auto it = m_MapOfFactorType.begin(); it != m_MapOfFactorType.end(); ) {
                bool isErased = false;
                if (it->second.find(nodeType) != it->second.end()) {
                    auto& nodeMap = it->second;
                    if (nodeMap[nodeType].find(node) != nodeMap[nodeType].end()) {
                        nodeMap[nodeType].erase(node);
                        if (nodeMap[nodeType].empty()) {
                            nodeMap.erase(nodeType);
                            if (it->second.empty()) {
                                it = m_MapOfFactorType.erase(it);
                                isErased = true;
                            }
                        }
                    }
                }
                if(!isErased) ++it;
            }
            for (auto& groupMap : m_MapOfGroup) {
                for (auto& factorMap : groupMap.second) {
                    if (factorMap.second.find(nodeType) != factorMap.second.end()) {
                        auto& nodeMap = factorMap.second;
                        if (nodeMap[nodeType].find(node) != nodeMap[nodeType].end()) {
                            nodeMap[nodeType].erase(node);
                            if (nodeMap[nodeType].empty()) {
                                nodeMap.erase(nodeType);
                            }
                        }
                    }
                }
            }
            m_MapOfNodeIDtoFactorID.erase(node);
            removedNodeIDs.push_back(node);
        }
    }

    // Clear m_DanglingNodes set
    m_DanglingNodes.clear();
    std::sort(removedNodeIDs.begin(), removedNodeIDs.end());
    return removedNodeIDs;
}

void mw_ceres::FactorGraph::removeFactorByFactorID(const std::vector<int>& id) {
    // Remove the given factor ids
    for (auto factor : id) {
        // Retrieve factor pointer
        auto& fp = m_MapOfFactors[factor];
        // Record potential dangling node IDs
        std::vector<int> nodeIDs = fp->getVariableIDs();
        for (auto node : nodeIDs) {
            m_MapOfNodeIDtoFactorID[node].erase(factor);
        }
        std::copy(nodeIDs.begin(), nodeIDs.end(),
                  std::inserter(m_DanglingNodes, m_DanglingNodes.end()));
        // Destroy factor object
        fp.reset();
        m_MapOfFactors.erase(factor);
        m_MapOfFactorIDtoFactorType.erase(factor);
        m_MapOfFactorIDtoResidualID.erase(factor);
    }
    m_NumFactors -= static_cast<int>(id.size());
}

std::unordered_map<int, std::unordered_map<int, std::vector<double> > > mw_ceres::FactorGraph::getIndividualFactorResidual(const std::set<int>& ids,
    int factorType) {
    ceres::Problem::EvaluateOptions options;
    std::unordered_map<int, std::unordered_map<int, std::vector<double> > > m_MapOfNodeIDtoFactorResidual{};
    for (const auto id : ids) {
        auto factorIDs = m_MapOfNodeIDtoFactorID[id];
        double totalCost = 0.0;
        // Initialize a vector to store residual block IDs
        std::vector<ceres::ResidualBlockId> residualIDs{};
        // Initialize a vector to store the factor IDs will be evaluated
        std::vector<int> selectedFactorIDs{};
        for (auto fID : factorIDs) {
            if (m_MapOfFactorIDtoFactorType[fID] == factorType) {
                residualIDs.push_back(m_MapOfFactorIDtoResidualID[fID]);
                selectedFactorIDs.push_back(fID);
            }
        }

        if (residualIDs.size() == 0) {
            //No residual block is selected. Skip to next node
            continue;
        }

        options.residual_blocks = residualIDs;
        std::vector<double> evaluatedResiduals;
        bool flag = Problem.Evaluate(options, &totalCost, &evaluatedResiduals, nullptr, nullptr);
        if (!flag) {
            cout << "The problem is not evaluated successfully!!!" << flag << endl;
            m_MapOfNodeIDtoFactorResidual.clear();
            return m_MapOfNodeIDtoFactorResidual;
        }

        ptrdiff_t residualDim = static_cast<ptrdiff_t>(evaluatedResiduals.size()/residualIDs.size());
        std::unordered_map<int, std::vector<double> > m_MapOfFactorIDtoResidual{};
        std::vector<double>::iterator iterResidual = evaluatedResiduals.begin();
        for (size_t i = 0; i < residualIDs.size(); i++) {
            m_MapOfFactorIDtoResidual[selectedFactorIDs[i]] = { iterResidual, iterResidual + residualDim };
            std::advance(iterResidual, residualDim);
        }
        m_MapOfNodeIDtoFactorResidual[id] = m_MapOfFactorIDtoResidual;
    }
    return m_MapOfNodeIDtoFactorResidual;
}

std::unordered_map<int, std::unordered_map<int, std::vector<double> > > mw_ceres::FactorGraph::getIndividualFactorResidualAssumingStateUnchanged(const std::set<int>& ids,
    int factorType) {
    std::unordered_map<int, std::unordered_map<int, std::vector<double> > > m_MapOfNodeIDtoFactorResidual{};
    // Use the first factor to get the residual dimension
    auto firstFactorID = *m_MapOfNodeIDtoFactorID[*ids.begin()].begin();
    auto& firstFactor = m_MapOfFactors[firstFactorID];
    ceres::CostFunction* costFcn = firstFactor->createFactorCostFcn();
    auto residualDim = costFcn->num_residuals();
    delete costFcn;

    for (const auto id : ids) {
        auto factorIDs = m_MapOfNodeIDtoFactorID[id];
        // Initialize a vector to store residual block IDs
        std::unordered_map<int, std::vector<double> > m_MapOfFactorIDtoResidual{};
        for (const auto fID : factorIDs) {
            if (m_MapOfFactorIDtoFactorType[fID] == factorType) {
                std::vector<double> evaluatedResiduals(static_cast<size_t>(residualDim));
                if (!Problem.EvaluateResidualBlockAssumingParametersUnchanged(m_MapOfFactorIDtoResidualID[fID], false, nullptr, evaluatedResiduals.data(), nullptr)) {
                    // The problem is not evaluated successfully.
                    m_MapOfNodeIDtoFactorResidual.clear();
                    return m_MapOfNodeIDtoFactorResidual;
                }
                else m_MapOfFactorIDtoResidual[fID] = evaluatedResiduals;
            }
        }
        if (m_MapOfFactorIDtoResidual.size()) m_MapOfNodeIDtoFactorResidual[id] = m_MapOfFactorIDtoResidual;
    }
    return m_MapOfNodeIDtoFactorResidual;
}

std::set<int> mw_ceres::FactorGraph::getCovarianceNodeID(const std::vector<int>& CovarianceType, const std::vector<int>& ids) {
    std::set<int> CovarianceNodeID{};
    if (ids.front() == -1) {
        // All nodes
        for (auto type : CovarianceType) {
            if (type == -1) return CovarianceNodeID;
            else if (type == -2) {
                auto allNodes = getAllVariableIDs({ -1 }, "None", "None");
                CovarianceNodeID.insert(allNodes.begin(), allNodes.end());
            }
            else {
                auto nodes = getAllVariableIDs({ -1 }, VariableTypeString.at(static_cast<VariableType>(type)), "None");
                CovarianceNodeID.insert(nodes.begin(), nodes.end());
            }
        }
    }
    else {
        // Given nodes
        if (CovarianceType.front() == -1) return CovarianceNodeID;
        auto allRelavantIDs = findNodesInPartialGraphByPoseNodes(ids);
        for (auto type : CovarianceType) {
            if (type == -2) {
                return allRelavantIDs;
            }
            else {
                auto nodes = getAllVariableIDs({ -1 }, VariableTypeString.at(static_cast<VariableType>(type)), "None");
                for (auto id : nodes) {
                    if (allRelavantIDs.find(id) != allRelavantIDs.end()) CovarianceNodeID.insert(id);
                }
            }
        }
    }
    return CovarianceNodeID;
}

std::vector<double> mw_ceres::FactorGraph::computeCovariance(ceres::Problem& problem, const std::set<int>& covarianceNodeID) {
    std::vector<double> covariances{};
    ceres::Covariance::Options options;
    options.algorithm_type = ceres::DENSE_SVD; // It can handle full-rank as well as rank deficient Jacobians. The rank deficiency arises from overparameterization. e.g., a four dimensional quaternion used to parameterize SO(3).
    options.null_space_rank = -1; // for deficient Jacobian matrix
    ceres::Covariance covariance(options);
    vector<pair<const double*, const double*> > covariance_blocks;

    for (auto id : covarianceNodeID) {
        auto node = m_AllStates.data() + m_MapOfVariables[id];
        covariance_blocks.push_back(make_pair(node, node));
    }

    if (covarianceNodeID.size() > 100) {
        // Give notification to user for long estimation time
        cout << "Optimization completed. Now estimating node state covariance for the specified " << covarianceNodeID.size() << " nodes." << endl;
        cout << "Estimating the node state covariance may require additional time due to the large number of nodes. Consider using the sliding window optimization technique to speed up the covariance estimation." << endl;
    }

    // Calculate covariance
    covariance.Compute(covariance_blocks, &problem); // after problem is optimized

    for (auto id : covarianceNodeID) {
        auto node = m_AllStates.data() + m_MapOfVariables[id];
        int dim = m_MapOfVariableDims[id]*m_MapOfVariableDims[id];
        double* covariance_node = new double[static_cast<size_t>(dim)];
        covariance.GetCovarianceBlock(node, node, covariance_node);
        covariances.push_back(dim); // size information
        covariances.insert(covariances.end(), covariance_node, covariance_node + dim);
        // Store covariance in map
        vector<double> currentCovariances(covariance_node, covariance_node + dim);
        m_MapOfNodeCovariances[id]=currentCovariances;
        delete[] covariance_node;
    }

    return covariances;
}

std::set<int> mw_ceres::FactorGraph::findNodesInPartialGraphByPoseNodes(const std::vector<int>& ids) {
    std::vector<int> factorIDs{};
    std::set<int> nodeIDs{};
    // Inputs need to be pose nodes
    if (!isPoseNode(ids)) return nodeIDs;
    for (auto poseid : ids) {
        nodeIDs.insert(poseid);
        for (auto fID : m_MapOfNodeIDtoFactorID[poseid]) {
            if (find(factorIDs.begin(), factorIDs.end(), fID) == factorIDs.end()) {
                factorIDs.push_back(fID);
                vector<int> varIDs = m_MapOfFactors[fID]->getVariableIDs();
                // Skip the factor including other pose nodes
                if (isUnselectedPoseNodeIncluded(ids, fID, varIDs)) {
                    continue;
                }
                nodeIDs.insert(varIDs.begin(), varIDs.end());
            }
        }
    }
    return nodeIDs;
}

bool mw_ceres::FactorGraph::isUnselectedPoseNodeIncluded(const std::vector<int>& selectedIDs, int fID, const std::vector<int>& includedNodeIDs) {
    bool flag = 0;
    int fctrType = m_MapOfFactorIDtoFactorType[fID];
    if (fctrType == 0 || fctrType == 1) {
        // 0: TwoPoseSE2 1: TwoPoseSE3. All nodes are pose nodes
        for (const int& id : includedNodeIDs) {
            if (std::find(selectedIDs.begin(), selectedIDs.end(), id) == selectedIDs.end()) {
                flag = 1;
            }
        }
    }
    else if (fctrType == 4) {
        // 4: IMU. Only the first and fourth node are pose nodes
        if (std::find(selectedIDs.begin(), selectedIDs.end(), includedNodeIDs[0]) == selectedIDs.end() ||
            std::find(selectedIDs.begin(), selectedIDs.end(), includedNodeIDs[3]) == selectedIDs.end()) {
            flag = 1;
        }
    }
    return flag;
}

std::unordered_set<int> mw_ceres::FactorGraph::findFactorsInPartialGraphByPoseNode(int poseID) {
    // Find all the factors being marginalized in the frame
    set<int> optimizedNodeIDsSet;
    set<int> fixedNodeIDsSet;
    auto factorIDs = m_MapOfNodeIDtoFactorID[poseID];
    for (auto fID : factorIDs) {
        vector<int> varIDs = m_MapOfFactors[fID]->getVariableIDs();
        vector<double*> parameterBlocks;
        for (const int& id : varIDs) {
            // fixed or free?
            if (m_MapOfVariableIsConstant.at(id)) {
                fixedNodeIDsSet.insert(id);
            } else {
                optimizedNodeIDsSet.insert(id);
            }
        }
    }
    // Check for non-pose prior factor (Vel)
    if (m_MapOfFactorType.find(m_FactorType["Vel3_Prior_F"]) != m_MapOfFactorType.end()) {
        auto velTypeMap = m_MapOfFactorType[m_FactorType["Vel3_Prior_F"]];
        if (!velTypeMap.empty()) {
            // Have vel prior factor
            auto velSet = velTypeMap[NodeTypeInt["VEL3"]];
            for (auto vel : velSet) {
                // vel is the vel node ID
                if (fixedNodeIDsSet.find(vel) != fixedNodeIDsSet.end() ||
                    optimizedNodeIDsSet.find(vel) != optimizedNodeIDsSet.end()) {
                    // The vel node is in the selected set
                    auto fVel = m_MapOfNodeIDtoFactorID[vel];
                    for (auto fVelID : fVel) {
                        assert(m_MapOfFactorIDtoFactorType.find(fVelID) != m_MapOfFactorIDtoFactorType.end());
                        if (m_MapOfFactorIDtoFactorType[fVelID] == m_FactorType["Vel3_Prior_F"]) {
                            // Prior factor found
                            factorIDs.insert(fVelID);
                        }
                    }
                }
            }
        }
    }
    // Check for non-pose prior factor (IMUBias)
    if (m_MapOfFactorType.find(m_FactorType["IMU_Bias_Prior_F"]) != m_MapOfFactorType.end()) {
        auto biasTypeMap = m_MapOfFactorType[m_FactorType["IMU_Bias_Prior_F"]];
        if (!biasTypeMap.empty()) {
            // Have IMUBias factor
            auto biasSet = biasTypeMap[NodeTypeInt["IMU_BIAS"]];
            for (auto bias : biasSet) {
                // bias is the IMUBias node ID
                if (fixedNodeIDsSet.find(bias) != fixedNodeIDsSet.end() ||
                    optimizedNodeIDsSet.find(bias) != optimizedNodeIDsSet.end()) {
                    // The bias node is in the selected set
                    auto fBias = m_MapOfNodeIDtoFactorID[bias];
                    for (auto fBiasID : fBias) {
                        if (m_MapOfFactorIDtoFactorType[fBiasID] == m_FactorType["IMU_Bias_Prior_F"]) {
                            // Bias factor found
                            factorIDs.insert(fBiasID);
                        }
                    }
                }
            }
        }
    }
    return factorIDs;
}

std::vector<int> mw_ceres::FactorGraph::marginalize(std::unique_ptr<MarginalFactor>& mFactor) {
    // Store necessary information for marginalization
    auto fIDs = mFactor->fIDs;
    std::unordered_map<int, int> m_MapOfParameterBlockSize;
    for (auto fID : fIDs) {
        auto& factor = m_MapOfFactors[fID];
        vector<double*> pBlocks;
        vector<int> varIDs = factor->getVariableIDs();
        for (const int& id : varIDs) {
            auto varAtId = m_AllStates.data() + m_MapOfVariables[id];
            pBlocks.push_back(varAtId);
            m_MapOfParameterBlockSize[id] = static_cast<int>(m_MapOfVariableDims[id]);
        }
        // compute jacobian and residual
        factor->setJacobianAndResidual(pBlocks);
    }

    mFactor->m_MapOfParameterBlockSize = m_MapOfParameterBlockSize;
    // Find nodes being marginalized: Iterate factors -> find relevant nodes -> check whether nodes are dangling after marginalization -> if so add to the list
    // Use the nIDs to keep tracking of checked nodes
    std::vector<int> nIDs{};
    // Use the mIDs to keep tracking of nodes being marginalized
    std::vector<int> mIDs{};
    // Use the vIDs to keep tracking of retained nodes
    std::vector<int> vIDs{};

    for (auto fID : fIDs) {
        const auto& factor = m_MapOfFactors[fID];
        auto IDs = factor->getVariableIDs();
        for (auto ID : IDs) {
            bool marginalize = true;
            if (std::find(nIDs.begin(), nIDs.end(), ID) == nIDs.end()) {
                // The node is not checked yet
                nIDs.push_back(ID);
                auto allFactors = m_MapOfNodeIDtoFactorID[ID];
                for (auto f : allFactors) {
                    if (find(fIDs.begin(), fIDs.end(), f) == fIDs.end()) {
                        // The node has unmarginalized factor connect to it
                        marginalize = false;
                        break;
                    }
                }
                // The node has no factors left after marginalization
                if (marginalize) mIDs.push_back(ID);
                else vIDs.push_back(ID);
            }
        }
    }

    // Error out if no retained node after marginalization
    if (vIDs.size() == 0) return { -2 };

    // Error out if any fixed nodes will be marginalized
    std::vector<int> fixedNodes{};
    bool isMarginalizedNodeFixed = false;
    if (mIDs.size() != 0) {
        for (auto id : mIDs) {
            if (m_MapOfVariableIsConstant.at(id)) {
                isMarginalizedNodeFixed = true;
                fixedNodes.push_back(id);
            } 
        }
    }
    if (isMarginalizedNodeFixed) {
        fixedNodes.push_back(-3);
        return fixedNodes;
    }

    // Store the node IDs
    mFactor->marginalizedIDs = mIDs;
    mFactor->m_VariableIDs = vIDs;
    std::unordered_map<int, int> m_MapOfParameterBlockIndex;
    int marginalizedBlockSize = 0;
    int retainedBlockSize = 0;

    for (auto nID : mIDs) {
        // Add nodes to the map with a given index in the Hessian
        m_MapOfParameterBlockIndex[nID] = marginalizedBlockSize;
        // Update the overall size of the marginalized nodes
        if (m_MapOfVariableTypes[nID] == VariableType::Pose_SE3) {
            // Switch from global size (7 - Quaternion) to local size (6)
            marginalizedBlockSize += 6;
        }
        else marginalizedBlockSize += m_MapOfParameterBlockSize[nID];
    }

    // Store the linearized points when marginalization happens
    for (auto it : m_MapOfParameterBlockSize) {
        double* pBlock = m_MapOfVariables[it.first] + m_AllStates.data();
        size_t blockSize = static_cast<size_t>(it.second);
        std::vector<double> pBlockLineared(blockSize);
        memcpy(pBlockLineared.data(), pBlock, sizeof(double) * blockSize);
        mFactor->m_MapOfLinearizationPoints[it.first] = pBlockLineared;
    }

    // Find the retained nodes and assign it with an index in the Hessian matrix
    for (const auto& pb : m_MapOfParameterBlockSize) {
        if (m_MapOfParameterBlockIndex.find(pb.first) == m_MapOfParameterBlockIndex.end()) {
            // The node will not be marginalized. Add the node to the Hessian matrix with current index
            m_MapOfParameterBlockIndex[pb.first] = marginalizedBlockSize + retainedBlockSize;
            // Update the overall size of the retained parameters
            if (m_MapOfVariableTypes[pb.first] == VariableType::Pose_SE3) {
                // Switch from global size (7 - Quaternion) to local size (6)
                retainedBlockSize += 6;
            }
            else retainedBlockSize += pb.second;
        }
    }
    mFactor->m_MapOfParameterBlockIndex = m_MapOfParameterBlockIndex;
    mFactor->marginalizedBlockSize = marginalizedBlockSize;
    mFactor->retainedBlockSize = retainedBlockSize;

    // Set retained nodes information
    for (const auto &it : m_MapOfParameterBlockIndex) {
        if (it.second >= marginalizedBlockSize) {
            mFactor->retainedParameterSize[it.first] = m_MapOfParameterBlockSize[it.first];
            mFactor->retainedParameterIndex[it.first] = m_MapOfParameterBlockIndex[it.first];
            mFactor->retainedParameterType[it.first] = m_MapOfVariableTypes[it.first];
            mFactor->retainedParameterValue[it.first] = mFactor->m_MapOfLinearizationPoints[it.first];
        }
    }
    int overallBlockSize = marginalizedBlockSize + retainedBlockSize;
    Eigen::MatrixXd H(overallBlockSize, overallBlockSize);
    H.setZero();
    Eigen::VectorXd b(overallBlockSize);
    b.setZero();

    // Set H and b. Add marginal factor here
    for (auto fID : fIDs) {
        auto& factor = m_MapOfFactors[fID];
        vector<double*> pBlocks;
        vector<int> varIDs = factor->getVariableIDs();
        for (size_t i = 0; i < varIDs.size(); i++) {
            // Get the jacobian for one parameter block
            int id = varIDs[i];
            int index = m_MapOfParameterBlockIndex[id];
            int size = m_MapOfParameterBlockSize[id];
            if (m_MapOfVariableTypes[id] == VariableType::Pose_SE3) {
                // For pose node, change the size to 6
                size = 6;
            }
            auto jacobians = factor->getJacobian();
            auto jacobian_i = jacobians[i].leftCols(size);

            for (size_t j = i; j < varIDs.size(); j++) {
                // Get the jacobian for the other parameter block. It can be itself
                int id2 = varIDs[j];
                int index2 = m_MapOfParameterBlockIndex[id2];
                int size2 = m_MapOfParameterBlockSize[id2];
                if (m_MapOfVariableTypes[id2] == VariableType::Pose_SE3) {
                    // For pose node, change the size to 6
                    size2 = 6;
                }
                auto jacobian_j = jacobians[j].leftCols(size2);
                // H = J^T*J
                if (i == j) {
                    // Hessian for one parameter block (Block-diagonal)
                    H.block(index, index, size, size) += jacobian_i.transpose() * jacobian_j;
                }
                else {
                    // Hessian between two parameter blocks. symmetric w.r.t the diagonal line
                    H.block(index, index2, size, size2) += jacobian_i.transpose() * jacobian_j;
                    H.block(index2, index, size2, size) = H.block(index, index2, size, size2).transpose();
                }
            }
            // b = J^T*r
            b.segment(index, size) += jacobian_i.transpose() * factor->getResidual();
        }
    }
    // Segment H into four blocks
    auto Hmm = H.block(0, 0, marginalizedBlockSize, marginalizedBlockSize);
    auto Hrr = H.block(marginalizedBlockSize, marginalizedBlockSize, retainedBlockSize, retainedBlockSize);
    auto Hmr = H.block(0, marginalizedBlockSize, marginalizedBlockSize, retainedBlockSize);
    auto Hrm = H.block(marginalizedBlockSize, 0, retainedBlockSize, marginalizedBlockSize);
    // Segment b into two parts
    auto bm = b.segment(0, marginalizedBlockSize);
    auto br = b.segment(marginalizedBlockSize, retainedBlockSize);

    auto newH = Hrr;
    auto newb = br;
    // Define a small epsilon value to threshold small eigenvalues
    double eps = 1e-6;

    if (marginalizedBlockSize != 0) {
        // The Hmm is supposed to be symmetric, so add the transpose to avoid the precision issue
        Hmm = 0.5 * (Hmm + Hmm.transpose());
        // Instantiate the SelfAdjointEigenSolver and compute the eigenvalues and eigenvectors for Hmm
        // Hmm = eigenV * eigenM * eigenV^T
        Eigen::SelfAdjointEigenSolver<Eigen::MatrixXd> eigenSolver(Hmm);

        // Inverse eigenvalues if greater than eps, otherwise set to zero
        Eigen::VectorXd eigenVInv = (eigenSolver.eigenvalues().array() > eps).select(eigenSolver.eigenvalues().array().inverse(), 0);

        // Compute the inverse of A using the spectral decomposition
        // Hmm_inv = eigenV * eigenM_inv * eigenV^T
        Eigen::MatrixXd Hmm_inv = eigenSolver.eigenvectors() * eigenVInv.asDiagonal() * eigenSolver.eigenvectors().transpose();

        // Schur complement
        newH = Hrr - Hrm * Hmm_inv * Hmr;
        newb = br - Hrm * Hmm_inv * bm;
    }

    // Instantiate the SelfAdjointEigenSolver and compute the eigenvalues and eigenvectors for newH
    // newH = eigenV * eigenM * eigenV^T = J^T * J = (eigenM_sqrt * eigenV^T)^T * (eigenM_sqrt * eigenV^T)
    // eigenM is block-diagonal
    Eigen::SelfAdjointEigenSolver<Eigen::MatrixXd> newEigenSolver(newH);

    // Maintain the eigenvalues if greater than eps, otherwise set to zero
    Eigen::VectorXd newEigen = (newEigenSolver.eigenvalues().array() > eps).select(newEigenSolver.eigenvalues().array(), 0);
    // Inverse eigenvalues if greater than eps, otherwise set to zero
    Eigen::VectorXd newEigen_inv = (newEigen.array() > eps).select(newEigen.array().inverse(), 0);
    auto newEigenV = newEigenSolver.eigenvectors();

    // J = eigenM_sqrt * eigenV^T
    mFactor->marginalizedJacobian = newEigen.cwiseSqrt().asDiagonal() * newEigenV.transpose();

    // r = (J^T)_inv*b = (eigenM_sqrt * eigenV^T)^T_inv*b = eigenM_sqrt_inv * eigenV^T * b
    mFactor->marginalizedResidual = newEigen_inv.cwiseSqrt().asDiagonal() * newEigenV.transpose() * newb;

    // return marginalized node IDs
    return mIDs;
}

std::vector<int> mw_ceres::FactorGraph::marginalizeFactor(const std::vector<int>& id) {
    // Check whether the factor exist in the graph
    std::vector<int> validness = validateFactorExistence(id);

    if (validness.back() == -1) {
        // There are factors not in the graph
        return validness;
    }

    // Create a marginal factor
    auto mFactor = std::make_unique<mw_ceres::MarginalFactor>(id);
    auto mIDs = marginalize(mFactor);
    // Return mIDs if no retained node after marginalization or fixed node being marginalized
    if (!mIDs.empty() && mIDs.back() < 0) return mIDs;
    // Remove marginalized factors and nodes
    removeFactor(id);
    int fMarginalID = addMarginalFactor(std::move(mFactor));
    std::vector<int> output{fMarginalID};
    std::sort(mIDs.begin(), mIDs.end());
    output.insert(output.end(), mIDs.begin(), mIDs.end());
    return output;
}

std::vector<int> mw_ceres::FactorGraph::marginalizeNode(int id) {
    // Check whether the node exist in the graph
    std::vector<int> validness = validateExistence({ id });
    if (validness.back() == -1) {
       // There are nodes not in the graph
       return validness;
    }

    // Find the factors being marginalized
    auto factorBeingMarginalized = findFactorsInPartialGraphByPoseNode(id);

    // Create a marginal factor
    auto mFactor = std::make_unique<mw_ceres::MarginalFactor>(factorBeingMarginalized);
    auto mIDs = marginalize(mFactor);
    // Return mIDs if no retained node after marginalization or fixed node being marginalized
    if (mIDs.back() < 0) return mIDs;
    vector<int> v_fIDs;
    v_fIDs.insert(v_fIDs.end(), factorBeingMarginalized.begin(), factorBeingMarginalized.end());
    // Remove factors and nodes
    removeFactor(v_fIDs);
    int fMarginalID = addMarginalFactor(std::move(mFactor));
    std::vector<int> output{fMarginalID};
    int nodeSize = static_cast<int>(mIDs.size());
    std::sort(mIDs.begin(), mIDs.end());
    std::sort(v_fIDs.begin(), v_fIDs.end());
    output.insert(output.end(), mIDs.begin(), mIDs.end());
    output.insert(output.end(), v_fIDs.begin(), v_fIDs.end());
    output.push_back(nodeSize);
    return output;
}

int mw_ceres::FactorGraph::addMarginalFactor(std::unique_ptr<MarginalFactor> fctr) {
    auto factor = std::move(fctr);
    vector<int> varIDs = factor->getVariableIDs();

    // only add the factor to internal map after its variable IDs check out
    m_MapOfFactors[m_UniqueFactorID] = std::move(factor);
    m_NumFactors = static_cast<int>(m_MapOfFactors.size());

    int newFactorID = m_UniqueFactorID;
    m_UniqueFactorID++;

    // Add factorID under NodeID
    for (int& id : varIDs) {
        if (m_MapOfNodeIDtoFactorID.find(id) == m_MapOfNodeIDtoFactorID.end()) {
            std::cerr << "Node in marginal factor does not exist in the node ID to factor ID map." << std::endl;
            return -1;
        }
        else {
            m_MapOfNodeIDtoFactorID[id].insert(newFactorID);
        }
    }
    m_MapOfFactorIDtoFactorType[newFactorID] = m_FactorType["Marginal_F"];
    return newFactorID;
}
