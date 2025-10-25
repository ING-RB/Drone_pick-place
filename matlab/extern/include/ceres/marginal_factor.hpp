// Copyright 2024 The MathWorks, Inc.

#ifdef BUILDING_LIBMWCERESCODEGEN
    #include "cerescodegen/cerescodegen_spec.hpp"
    #include "cerescodegen/group_utilities.hpp"
    #include "cerescodegen/factor.hpp"
#else
    /* To deal with the fact that PackNGo has no include file hierarchy */
    #include "cerescodegen_spec.hpp"
    #include "group_utilities.hpp"
    #include "factor.hpp"
#endif

#ifndef MARGINAL_FACTOR_HPP
#define MARGINAL_FACTOR_HPP

namespace mw_ceres {

class MarginalFactor;

class MarginalFactorCost : public ceres::CostFunction {
  public:
    MarginalFactorCost(const MarginalFactor* _mFactor);
    bool Evaluate(double const* const* parameters,
                          double* residuals,
                          double** jacobians) const override;
  protected:
    const MarginalFactor* mFactor;
};

class FactorGraph;

// Represents a marginal factor after marginalizing the given factors
class MarginalFactor : public Factor {
  public:
    // Constructor that accepts std::unordered_set<int>
    MarginalFactor(std::unordered_set<int> factors)
        : marginalizedBlockSize(0), retainedBlockSize(0), fIDs(factors){
    }

    // Constructor that accepts std::vector<int>
    MarginalFactor(std::vector<int> factors)
        : marginalizedBlockSize(0), retainedBlockSize(0), fIDs(factors.begin(), factors.end()) {
    }

    ceres::CostFunction* createFactorCostFcn() const override{
        return new MarginalFactorCost(this);
    }

    ceres::LocalParameterization* getVariableLocalParameterization(int /*variableID*/) override {
        throw std::logic_error("MarginalFactor::getVariableLocalParameterization is not supported.");
    }

    std::vector<double> getDefaultState(int /*variableID*/) const override {
        throw std::logic_error("MarginalFactor::getDefaultState is not supported.");
    }

    std::vector<int> getMarginalizedNodeIDs() {
        return marginalizedIDs;
    }

    // Declare MarginalFactorCost as a friend of MarginalFactor
    friend class MarginalFactorCost;
    friend class FactorGraph;

  protected:

    // Map of parameter block id to its size - Global size
    std::unordered_map<int, int> m_MapOfParameterBlockSize;
    // Map of parameter block id to its index in Hessian matrix - Local size
    std::unordered_map<int, int> m_MapOfParameterBlockIndex;
    // Map of parameter block id to its linearization point
    std::unordered_map<int, std::vector<double>> m_MapOfLinearizationPoints;

    // The sum of marginalized parameters' state size - Local size
    int marginalizedBlockSize; 
    // The sum of retained parameters' state size - Local size
    int retainedBlockSize;
    // Variable IDs being marginalized
    std::vector<int> marginalizedIDs;
    // Ordered map of the retained parameter block id to its size - Global size
    std::map<int, int> retainedParameterSize;
    // Map of the retained parameter block id to its index in Hessian matrix - Local size
    std::unordered_map<int, int> retainedParameterIndex;
    // Map of the retained parameter block id to its type
    std::unordered_map<int, int> retainedParameterType;
    // The node state of the retained nodes when linearization happened
    std::unordered_map<int, std::vector<double>> retainedParameterValue;

    // Marginalized jacobian
    Eigen::MatrixXd marginalizedJacobian;
    // Marginalized residual
    Eigen::VectorXd marginalizedResidual;

    // Marginalized factors
    std::unordered_set<int> fIDs;
};

} // namespace mw_ceres

#endif
