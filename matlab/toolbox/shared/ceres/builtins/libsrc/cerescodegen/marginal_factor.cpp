// Copyright 2024 The MathWorks, Inc.

#ifdef BUILDING_LIBMWCERESCODEGEN
    #include "cerescodegen/marginal_factor.hpp"
    #include "cerescodegen/factor_graph.hpp"
#else
    /* To deal with the fact that PackNGo has no include file hierarchy during test */
    #include "marginal_factor.hpp"
    #include "factor_graph.hpp"
#endif

using namespace std;

mw_ceres::MarginalFactorCost::MarginalFactorCost(const mw_ceres::MarginalFactor* _mFactor) : mFactor(_mFactor){
    vector<int> varIDs = _mFactor->getVariableIDs();
    auto m_retainedParameterSize = mFactor->retainedParameterSize;
    for (auto varID: varIDs) {
        mutable_parameter_block_sizes()->push_back(m_retainedParameterSize[varID]);
    }
    set_num_residuals(_mFactor->retainedBlockSize);
};

bool mw_ceres::MarginalFactorCost::Evaluate(double const* const* parameters, double* residuals, double** jacobians) const {
    // residuals is never nullptr, jacobians can be nullptr
    // Initialize delta_x vector
    Eigen::VectorXd delta_x(mFactor->retainedBlockSize);
    vector<int> varIDs = mFactor->getVariableIDs();
    auto m_retainedParameterSize = mFactor->retainedParameterSize;
    auto m_retainedParameterIndex = mFactor->retainedParameterIndex;
    auto m_retainedParameterType = mFactor->retainedParameterType;
    auto m_retainedParameterValue = mFactor->retainedParameterValue;
    for (size_t i = 0; i < varIDs.size(); i++)
    {
        auto varID = varIDs[i];
        int size = m_retainedParameterSize[varID];
        int index = m_retainedParameterIndex[varID] - mFactor->marginalizedBlockSize;
        Eigen::VectorXd cur_x = Eigen::Map<const Eigen::VectorXd>(parameters[i], size);
        Eigen::VectorXd old_x = Eigen::Map<const Eigen::VectorXd>(m_retainedParameterValue[varID].data(), size);
        if (m_retainedParameterType[varID] != VariableType::Pose_SE3) {
            // The parameter is not pose node. Directly compute the difference
            delta_x.segment(index, size) = cur_x - old_x;
        }
        else{
            // SE(3) pose in [x, y, z, qx, qy, qz, qw]
            // delta pos
            delta_x.segment<3>(index) = cur_x.head<3>() - old_x.head<3>();
            // Eigen quaternion constructions in qw,qx,qy,qz format
            auto old_q = Eigen::Quaterniond(old_x(6), old_x(3), old_x(4), old_x(5));
            auto cur_q = Eigen::Quaterniond(cur_x(6), cur_x(3), cur_x(4), cur_x(5));
            auto delta_q = old_q.inverse() * cur_q;
            // Make sure the quaternion difference has a positive scalar part (w)
            delta_q = delta_q.w() >= 0? delta_q : Eigen::Quaterniond(-delta_q.w(), -delta_q.x(), -delta_q.y(), -delta_q.z());
            // Use small-angle approximation: The quaternion difference's vector part represents half the rotation angle
            delta_x.segment<3>(index + 3) = 2.0 * delta_q.vec();
        }
    }
    // r = r0 + J*dx
    Eigen::Map<Eigen::VectorXd>(residuals, mFactor->retainedBlockSize) = mFactor->marginalizedResidual + mFactor->marginalizedJacobian * delta_x;
    if (jacobians) {
        // set jacobians
        for (size_t i = 0; i < varIDs.size(); i++) {
            if (jacobians[i]) {
                // If node is fixed, jacobian computation will be skipped
                auto varID = varIDs[i];
                int size = m_retainedParameterSize[varID];
                int local_size = size;
                if (m_retainedParameterType[varID] == VariableType::Pose_SE3) {
                    // For pose node, change the local size to 6
                    local_size = 6;
                }
                int index = m_retainedParameterIndex[varID] - mFactor->marginalizedBlockSize;
                Eigen::Map<Eigen::Matrix<double, Eigen::Dynamic, Eigen::Dynamic, Eigen::RowMajor>> jacobian(jacobians[i],
                    mFactor->retainedBlockSize, size);
                jacobian.setZero();
                jacobian.leftCols(local_size) = mFactor->marginalizedJacobian.middleCols(index, local_size);
            }
        }
    }
    return true;
}
