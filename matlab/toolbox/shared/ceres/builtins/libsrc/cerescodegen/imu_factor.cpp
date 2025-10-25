// Copyright 2021-2023 The MathWorks, Inc.

#ifdef BUILDING_LIBMWCERESCODEGEN
    #include "cerescodegen/preintegration_utilities.hpp"
    #include "cerescodegen/imu_factor.hpp"
#else
    /* To deal with the fact that PackNGo has no include file hierarchy */
    #include "preintegration_utilities.hpp"
    #include "imu_factor.hpp"
#endif

void mw_ceres::FactorIMU::preOptimizationUpdate(std::vector<double*>& currVariableStates) {

    Eigen::Vector3d currentGyroBiasEstimate;
    currentGyroBiasEstimate << currVariableStates[2][0], currVariableStates[2][1], currVariableStates[2][2];
    Eigen::Vector3d currentAccelBiasEstimate;
    currentAccelBiasEstimate << currVariableStates[2][3], currVariableStates[2][4], currVariableStates[2][5];

    m_NominalBiasAcc = currentAccelBiasEstimate;
    m_NominalBiasGyro = currentGyroBiasEstimate;

    // re-run pre-integration at the beginning of each graph optimization

    mw_ceres::OnManifoldPreIntegrator integrator(currentGyroBiasEstimate, currentAccelBiasEstimate, m_DeltaT);
    integrator.setGyroscopeNoise(m_GyroscopeNoise/m_DeltaT); // need to convert to discrete-time measurement noise covariance
    integrator.setAccelerometerNoise(m_AccelerometerNoise/m_DeltaT);
    size_t N = m_GyroReadings.size() / 3;
    m_SumDeltaT = 0.0;
    for (size_t i = 0; i < N; i++) {
        Eigen::Vector3d gyroMeas(m_GyroReadings.data() + i * 3);
        Eigen::Vector3d accMeas(m_AccelReadings.data() + i * 3);
        integrator.integrateMeasurement(gyroMeas, accMeas);
        m_SumDeltaT += m_DeltaT;
    }

    m_PreIntegratedPos = integrator.deltaPos(); // pre-integrated measurements
    m_PreIntegratedVel = integrator.deltaVel();
    m_PreIntegratedQuat = integrator.deltaQuat();
    m_dRot_dBg = integrator.Jacobian_dR_dBiasGyro(); // Jacobians w.r.t. biases
    m_dPos_dBa = integrator.Jacobian_dP_dBiasAcc();
    m_dPos_dBg = integrator.Jacobian_dP_dBiasGyro();
    m_dVel_dBa = integrator.Jacobian_dV_dBiasAcc();
    m_dVel_dBg = integrator.Jacobian_dV_dBiasGyro();
    m_PreIntegCovariance = integrator.deltaCovariance(); // pre-integrated measurement noise
    m_BiasRandWalkCovariance.block<3, 3>(0, 0) = m_SumDeltaT * m_GyroscopeBiasNoise;
    m_BiasRandWalkCovariance.block<3, 3>(3, 3) = m_SumDeltaT * m_AccelerometerBiasNoise; // process noise

}


void mw_ceres::FactorIMU::predict(const double* prevBias, const double* prevPose, const double* prevVel,
                double* predictedPose, double* predictedVel) const {

    Eigen::Map<const Eigen::Vector3d> prevP(prevPose);
    Eigen::Map<const Eigen::Quaterniond> prevQ(prevPose + 3);
    Eigen::Map<const Eigen::Vector3d> prevV(prevVel);

    // transform pose to IMU frame by right multiplication with inverse of sensor transform
    Eigen::Matrix3d R = (prevQ*m_SensorTransform_q.inverse()).toRotationMatrix();
    Eigen::Vector3d v = prevV;
    Eigen::Vector3d p = prevP - prevQ*m_SensorTransform_q.inverse()*m_SensorTransform_t;
    // integrate gyroscope and accelerometer readings
    predictInternal(prevBias,R,v,p,m_GravityAcceleration);
    // transform pose back to pose reference frame by right multiplication with sensor transform
    Eigen::Quaterniond q(R*m_SensorTransform_q);
    q.normalize();
    p = p + R*m_SensorTransform_t;
    
    // fill output
    double pPose[7] = {p[0], p[1], p[2], q.x(), q.y(), q.z(), q.w()};
    for (int k=0; k < 7 ; k++) {
        predictedPose[k] = pPose[k];
    }

    for (int k=0; k < 3 ; k++) {
        predictedVel[k] = v[k];
    }
}

void mw_ceres::FactorIMU::predictInternal(const double* prevBias, Eigen::Matrix3d& R, Eigen::Vector3d& v, Eigen::Vector3d& p,
                Eigen::Vector3d g) const {

    Eigen::Map<const Eigen::Vector3d> prevBg(prevBias);
    Eigen::Map<const Eigen::Vector3d> prevBa(prevBias + 3);

    double deltaTSquared = m_DeltaT * m_DeltaT;
    size_t N = m_GyroReadings.size() / 3;
    for (size_t i = 0; i < N; i++) {
        Eigen::Vector3d gyroMeas(m_GyroReadings.data() + i * 3);
        Eigen::Vector3d accMeas(m_AccelReadings.data() + i * 3);
        Eigen::Vector3d dTheta = (gyroMeas - prevBg) * m_DeltaT;

        Eigen::Vector3d correctedAcc = accMeas - prevBa;
        // predict the position update first using current position,  
        // current velocity and acceleration (p = p + u*t + (1/2)*a*t^2)
        p = p + v * m_DeltaT + 0.5 * g * deltaTSquared + 0.5 * R * correctedAcc * deltaTSquared;
        // predict the velocity using current acceleration (v = v + a*t)
        v = v + g * m_DeltaT + R * correctedAcc * m_DeltaT;
        // predict orientation using current angular velocity (th = th + omega*t)
        R = R * mw_ceres::SO3::expm<double>(dTheta);
    }
}

void mw_ceres::FactorIMUGST::predict(const double* prevBias, const double* prevPose, const double* prevVel,
                const double* gRot, const double* scale, const double* sensorTform, double* predictedPose, double* predictedVel) const {

    Eigen::Map<const Eigen::Vector3d> prevP(prevPose);
    Eigen::Map<const Eigen::Quaterniond> prevQ(prevPose + 3);
    Eigen::Map<const Eigen::Vector3d> prevV(prevVel);
    Eigen::Map<const Eigen::Vector3d> st(sensorTform);
    Eigen::Map<const Eigen::Quaterniond> sQ(sensorTform + 3);
    Eigen::Quaterniond gQ({gRot[0],gRot[1],gRot[2],gRot[3]});
    double s = scale[0];

    // transform pose to IMU frame by right multiplication with inverse of sensor transform
    Eigen::Matrix3d R = (prevQ*sQ.inverse()).toRotationMatrix();
    // Compute previous velocity in IMU reference frame.
    Eigen::Vector3d v = s*prevV;
    Eigen::Vector3d p = s*prevP - prevQ*sQ.inverse()*st;
    // Transform gravity vector to pose reference frame
    auto g = gQ*m_GravityAcceleration;
    // integrate gyroscope and accelerometer readings
    predictInternal(prevBias,R,v,p,g);
    // transform pose back to pose reference frame by right multiplication with sensor transform
    Eigen::Quaterniond q(R*sQ);
    q.normalize();
    p = (p + (R*st))/s;
    
    // fill output
    double pPose[7] = {p[0], p[1], p[2], q.x(), q.y(), q.z(), q.w()};
    for (int k=0; k < 7 ; k++) {
        predictedPose[k] = pPose[k];
    }

    for (int k=0; k < 3 ; k++) {
        predictedVel[k] = v[k]/s;
    }
}
