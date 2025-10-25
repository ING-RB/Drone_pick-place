// Copyright 2024 The MathWorks, Inc.
#include <Eigen/Core>
#include <Eigen/Geometry>

#ifdef BUILDING_LIBMWCERESCODEGEN
    #include "cerescodegen/cerescodegen_spec.hpp"
    #include "cerescodegen/factor_graph.hpp"
    #include "cerescodegen/common_factors_2.hpp"
    #include "cerescodegen/imu_factor.hpp"
#else
    /* To deal with the fact that PackNGo has no include file hierarchy */
    #include "cerescodegen_spec.hpp"
    #include "factor_graph.hpp"
    #include "common_factors_2.hpp"
    #include "imu_factor.hpp"
#endif

#ifndef IMU_INITIALIZATION_UTILITIES_HPP
#define IMU_INITIALIZATION_UTILITIES_HPP

namespace mw_ceres {

    enum IMUReferenceFrame {ENU, NED};

    enum IMUInitializationStatus {
        SUCCESS, // No failures
        FAILURE_BAD_SCALE, // Scale is below specified threshold.
        FAILURE_BAD_PREDICTION, // Prediction error is above specified threshold.
        FAILURE_BAD_BIAS, // Bias variation from the initial value is out of expected bounds computed from bias covariance values provided.
        FAILURE_BAD_SCALE_PREDICTION, // Scale is below specified threshold and prediction error is above specified threshold.
        FAILURE_BAD_SCALE_BIAS, // Scale is below specified threshold and bias variation from initial value is out of expected bounds.
        FAILURE_BAD_PREDICTION_BIAS, // Prediction error is above specified threshold and bias variation from initial value is out of expected bounds.
        FAILURE_BAD_SCALE_PREDICTION_BIAS, // Scale is below specified threshold, prediction error is above specified threshold and bias variation from initial value is out of expected bounds.
        FAILURE_BAD_OPTIMIZATION, // Optimization ran into errors and estimates are not usable.
        FAILURE_NO_CONVERGENCE // Initialization optimization didn't converge in specified number of iterations. Increase the max number of iterations.
    };

    /// IMU parameters
    struct CERESCODEGEN_API FactorIMUParameters {

        /** Gyroscope sensor bias noise covariance matrix*/
        Eigen::Matrix3d m_GyroscopeBiasNoise;

        /** Accelerometer sensor bias noise covariance matrix*/
        Eigen::Matrix3d m_AccelerometerBiasNoise;

        /** Raw angular velocity measurement noise covariance matrix*/
        Eigen::Matrix3d m_GyroscopeNoise;

        /** Raw linear acceleration measurement noise covariance matrix*/
        Eigen::Matrix3d m_AccelerometerNoise;

        /** Sample rate of IMU*/
        double m_SampleRate;

        /** Negative of Gravity acceleration in IMU reference frame NED ([0,0,-9.81]) or ENU ([0,0,9.81]).*/
        double m_negative_gravityAcceleration[3]{};

        FactorIMUParameters() {
            m_GyroscopeBiasNoise = Eigen::Matrix3d::Identity();
            m_AccelerometerBiasNoise = Eigen::Matrix3d::Identity();
            m_GyroscopeNoise = Eigen::Matrix3d::Identity();
            m_AccelerometerNoise = Eigen::Matrix3d::Identity();
            m_SampleRate = 100;
            m_negative_gravityAcceleration[2] = 9.81;
        }

        // Custom constructor to specify scalar noise covariance values. 
        // Popular visual-inertial datasets ship scalar noise standard 
        // deviation values in a YAML file. This signature is supports 
        // this common use-case. Note that the YAML files usually provide
        // noise standard deviation in kalibr_allan style. But we expect
        // noise variances which are squared values of standard deviation.
        FactorIMUParameters(double gyroBiasNoise, double accelBiasNoise, double gyroNoise, double accelNoise, double sampleRate = 100.0, IMUReferenceFrame refFrame = IMUReferenceFrame::ENU) {
            m_GyroscopeBiasNoise = gyroBiasNoise*Eigen::Matrix<double, 3, 3, Eigen::RowMajor>::Identity();
            m_AccelerometerBiasNoise = accelBiasNoise*Eigen::Matrix<double, 3, 3, Eigen::RowMajor>::Identity();
            m_GyroscopeNoise = gyroNoise*Eigen::Matrix<double, 3, 3, Eigen::RowMajor>::Identity();
            m_AccelerometerNoise = accelNoise*Eigen::Matrix<double, 3, 3, Eigen::RowMajor>::Identity();
            m_SampleRate = round(sampleRate);
            if (refFrame == IMUReferenceFrame::ENU)
                m_negative_gravityAcceleration[2] = 9.81;
            else
                m_negative_gravityAcceleration[2] = -9.81;
        }

        // custom constructor to specify noise covariance matrices using
        // vector data pointer for codegen workflows.
        FactorIMUParameters(const double* gyroBiasNoise, const double* accelBiasNoise, const double* gyroNoise, const double* accelNoise, const double& sampleRate, const IMUReferenceFrame& refFrame) {
            m_GyroscopeBiasNoise = Eigen::Map<const Eigen::Matrix<double, 3, 3, Eigen::RowMajor>>(gyroBiasNoise);
            m_AccelerometerBiasNoise = Eigen::Map<const Eigen::Matrix<double, 3, 3, Eigen::RowMajor>>(accelBiasNoise);
            m_GyroscopeNoise = Eigen::Map<const Eigen::Matrix<double, 3, 3, Eigen::RowMajor>>(gyroNoise);
            m_AccelerometerNoise = Eigen::Map<const Eigen::Matrix<double, 3, 3, Eigen::RowMajor>>(accelNoise);
            m_SampleRate = round(sampleRate);
            if (refFrame == ENU)
                m_negative_gravityAcceleration[2] = 9.81;
            else
                m_negative_gravityAcceleration[2] = -9.81;
        }

        // custom constructor to specify noise covariance matrices.
        FactorIMUParameters(const Eigen::Matrix<double, 3, 3, Eigen::RowMajor>& gyroBiasNoise, const Eigen::Matrix<double, 3, 3, Eigen::RowMajor>& accelBiasNoise, const Eigen::Matrix<double, 3, 3, Eigen::RowMajor>& gyroNoise, const Eigen::Matrix<double, 3, 3, Eigen::RowMajor>& accelNoise, const double& sampleRate = 100, const IMUReferenceFrame& refFrame = IMUReferenceFrame::ENU) {
            m_GyroscopeBiasNoise = gyroBiasNoise;
            m_AccelerometerBiasNoise = accelBiasNoise;
            m_GyroscopeNoise = gyroNoise;
            m_AccelerometerNoise = accelNoise;
            m_SampleRate = round(sampleRate);
            if (refFrame == IMUReferenceFrame::ENU)
                m_negative_gravityAcceleration[2] = 9.81;
            else
                m_negative_gravityAcceleration[2] = -9.81;
        }


        ~FactorIMUParameters() {
        }
    };

    /// IMU initialization options
    struct CERESCODEGEN_API IMUInitializationOptions {

        /** Pose reference frame to IMU sensor frame transform. The default
        sensor transform is identity, meaning that the pose reference frame
        and IMU reference frame are the same.*/
        Eigen::Matrix<double, 4, 4, Eigen::RowMajor> m_SensorTransform;

        /** Scale Threshold to consider the estimation successful.
        By default the threshold value NaN and estimated scale is considered
        to be valid.*/
        double m_ScaleThreshold;

        /** Translation and rotation prediction error threshold specified
        as an array of length 2. The default prediction threshold values
        are 1e-3 meters and 5e-2 radians respectively.*/
        double m_PredictionErrorThreshold[2];

        /** Bias covariance multiplier. The upper bound on bias variation
        from the initial bias is computed using this multiplier and bias
        covariance value. The default multiplier value is 3. Larger bias
        variations will be considered valid as the multiplier value increases. */
        double m_BiasCovarianceMultiplier;

        /** Flag to fix the sensor transform during the
        initialization optimization. The default value is true.*/
        bool m_FixSensorTransform;

        /** Flag to fix the scale value during optimization. The default
        value is false supporting monocular VIO workflow where the input
        poses will be at an unknown scale. In LIDAR and STEREO cases the
        poses will be at the same scale as IMU measurements. So fixing the
        scale value to default 1 is needed.*/
        bool m_FixScale;

        /** Flag to add a prior factor to the initial bias value. The default
        value is true to keep the optimized bias values as close to zero as
        possible and not choose large biases.*/
        bool m_AddInitialBiasPrior;

        /** Flag to add initial velocity prior during initialization
        optimization. The default value is false.*/
        bool m_AddInitialVelocityPrior;

        /** Initial bias guess. By default all the 6 bias values are expected
        to be zeros. Specify different values if known.*/
        double m_InitialBias[6]{};

        /** Initial velocity. By default the initial velocity is expected
        to be zeros.*/
        double m_InitialVelocity[3]{};

        /** Initial velocity prior factor weight. The default value is 1e6.
        The larger the weight, larger the initial velocity will be trusted.*/
        double m_InitialVelocityPriorWeight;

        /** Initial bias prior factor weight. The default value is 1. The
        larger the weight, larger the initial bias will be trusted.*/
        double m_InitialBiasPriorWeight;

        /** Pose prior weight. The default value is 1e6.*/
        double m_PosePriorWeight;

        /** Flag to fix poses initialization optimization whenever true.
        Whenever false pose priors will be added to provide optimizer 
        more flexibility to refine input poses slightly for better results.
        The default is true. */
        bool m_FixPoses;

        IMUInitializationOptions() {
            m_SensorTransform = Eigen::Matrix<double, 4, 4, Eigen::RowMajor>::Identity();
            m_ScaleThreshold = 1e-3;
            m_PredictionErrorThreshold[0] = 5e-2; // Translation prediction error.
            m_PredictionErrorThreshold[1] = 5e-2; // Rotation prediction error.
            m_BiasCovarianceMultiplier = 3;
            m_FixPoses = true;
            m_FixSensorTransform = true;
            m_FixScale = false;
            m_AddInitialBiasPrior = true;
            m_AddInitialVelocityPrior = false;
            m_InitialVelocityPriorWeight = 1e6;
            m_InitialBiasPriorWeight = 1;
            m_PosePriorWeight = 1e6;
        }


        ~IMUInitializationOptions() {
        }
    };

    // Reshape a large double vector to vector of double vectors of known size.
    static std::vector<std::vector<double>> reshapeToVectorOfVector(const std::vector<double>& largeVector, size_t chunkSize) {
        std::vector<std::vector<double>> result;

        for (size_t i = 0; i < largeVector.size(); i += chunkSize) {
            std::vector<double> chunk;
            // Use std::copy_n to safely copy a chunk of elements
            std::copy_n(largeVector.begin() + static_cast<std::vector<double>::difference_type>(i), std::min(chunkSize, largeVector.size() - i), std::back_inserter(chunk));
            result.push_back(std::move(chunk));
        }

        return result;
    }

    /// IMU initialization result
    struct CERESCODEGEN_API IMUInitializationResult {

        private:

        /** IMU Bias node states at input pose sampling times. Use these
        states for initializing the bias node states in visual-inertial
        factor graph while adding the IMU factors for the first time. */
        std::vector<double> Bias;

        /** IMU velocity node states at input pose sampling times. Use these
        states for initializing the bias node states in visual-inertial
        factor graph while adding the IMU factors for the first time. Note
        that the velocity states are converted to in IMU reference frame
        using the estimated gravity rotation and pose scale. */
        std::vector<double> VelocityInIMUReference;

        /** Poses in IMU reference frame. Input pose are transformed to IMU
        reference frame (either NED or ENU based on IMU initialization
        option) using estimated gravity rotation and pose scale. Whenever
        "m_FixPoses" is set to false, the input pose node states will
        be softly fixed and refined during the optimization. Whenever
        initialization status is success these poses can be trusted. */
        std::vector<double> PosesInIMUReference;

        public:

        /** Input pose reference frame to IMU sensor frame transform
        refined after IMU initialization optimization. Whenever .
        "m_FixSensorTransform" IMU initialization option is set to
        true the sensor transform is not refined during the optimization
        process and is equivalent to value specified in initialization
        options. */
        Eigen::Matrix<double, 4, 4, Eigen::RowMajor> SensorTransform;

        /** Pose scale computed using the IMU initialization optimization.
        Multiply the input pose translation with this scalar value to bring
        them to the same scale as IMU reference frame. */
        double Scale;

        /** 3-by-3 row major gravity rotation matrix computed from
        initialization optimization.This can transform gravity vector in IMU
        reference frame ([0,0,9.81] in NED, [0,0,-9.81] in ENU) to
        input pose reference frame. The inverse of this matrix can
        transform poses and points in pose reference frame to
        IMU reference frame.*/
        Eigen::Matrix<double, 3, 3, Eigen::RowMajor> GravityRotation;

        /** 4-by-4 row major Transformation matrix from input pose
        reference frame to IMU reference frame specified in IMU
        initialization options. */
        Eigen::Matrix<double, 4, 4, Eigen::RowMajor> TransformToIMUReference;

        /** Status of the IMU initialization. It can be:
        IMUInitializationStatus::SUCCESS, // No failures
        IMUInitializationStatus::FAILURE_BAD_SCALE, // Scale is below specified threshold.
        IMUInitializationStatus::FAILURE_BAD_PREDICTION, // Prediction error is above specified threshold.
        IMUInitializationStatus::FAILURE_BAD_BIAS, // Bias variation from the initial value is out of expected bounds computed from bias covariance values provided.
        IMUInitializationStatus::FAILURE_BAD_SCALE_PREDICTION, // Scale is below specified threshold and prediction error is above specified threshold.
        IMUInitializationStatus::FAILURE_BAD_SCALE_BIAS, // Scale is below specified threshold and bias variation from initial value is out of expected bounds.
        IMUInitializationStatus::FAILURE_BAD_PREDICTION_BIAS, // Prediction error is above specified threshold and bias variation from initial value is out of expected bounds.
        IMUInitializationStatus::FAILURE_BAD_SCALE_PREDICTION_BIAS, // Scale is below specified threshold, prediction error is above specified threshold and bias variation from initial value is out of expected bounds.
        IMUInitializationStatus::FAILURE_BAD_OPTIMIZATION, // Optimization ran into errors and estimates are not usable.
        IMUInitializationStatus::FAILURE_NO_CONVERGENCE // Initialization optimization didn't converge in specified number of iterations. Increase the max number of iterations.

        Bias out of bounds signifies that either IMU noise modelling needs improvement or the IMU is unable to track input poses properly. Large prediction errors signify that IMU pose prediction and input poses disagree. Very low scale value signifies that the pose scale estimation failed. To improve the results compute proper IMU noise parameters, choose thresholds empirically and continue executing initialization until success.
        */
        IMUInitializationStatus Status;

        /** Get optimized IMU bias node states at input pose sampling times
        as a vector of double vector. Use these states for initializing the
        bias node states in visual-inertial factor graph while adding the
        IMU factors for the first time. */
        std::vector<std::vector<double>> getBias() {
            return reshapeToVectorOfVector(Bias, 6);
        }

        /** Get optimized IMU bias node states at input pose sampling times
        as a double vector. This function is useful for factor graph
        code-generation workflow. Use getBias for retriving optimized bias
        values in a more readable format. */
        std::vector<double> getBiasAsVector() const {
            return Bias;
        }

        /** Get optimized IMU velocity node states in IMU reference frame
        at input pose sampling times as a vector of double vector. Use
        these states for initializing the velocity  node states in
        visual-inertial factor graph while adding the IMU factors for the
        first time. */
        std::vector<std::vector<double>> getVelocityInIMUReference() {
            return reshapeToVectorOfVector(VelocityInIMUReference, 3);
        }

        /**Get optimized IMU velocity node states in IMU reference frame
        at input pose sampling times as a double vector. This function
        is useful for factor graph code-generation workflow. Use
        getVelocityInIMUReference for retriving optimized bias
        values in a more readable format. */
        std::vector<double> getVelocityInIMUReferenceAsVector() const {
            return VelocityInIMUReference;
        }

        /** Get optimized pose node states in IMU reference frame
        at input pose sampling times as a vector of double vector. Use
        these states for initializing the pose  node states in
        visual-inertial factor graph while adding the IMU factors for the
        first time. Note that landmark nodes need to be updated upon
        using these optimized pose nodes. Use transformLandmarksToIMU method
        for this purpose. */
        std::vector<std::vector<double>> getPosesInIMUReference() {
            return reshapeToVectorOfVector(PosesInIMUReference, 7);
        }

        /**Get optimized pose node states in IMU reference frame
        at input pose sampling times as a double vector. This function
        is useful for factor graph code-generation workflow. Use
        getPosesInIMUReference for retriving optimized bias
        values in a more readable format. */
        std::vector<double> getPosesInIMUReferenceAsVector() const {
            return PosesInIMUReference;
        }

        /** Transform the landmarks to IMU navigation reference using 
        estimated gravity rotation and pose scale. */
        void transformLandmarksToIMU(std::vector<std::vector<double>>& landmarks){
            //Point transformation using quaternion is faster.
            Eigen::Quaterniond q(TransformToIMUReference.block<3,3>(0,0));
            for (auto& landmark : landmarks) {
                Eigen::Map<const Eigen::Matrix<double, 3, 1>> l(landmark.data());
                Eigen::Matrix<double, 3, 1> p = Scale * (q*l);
                landmark[0] = p[0];
                landmark[1] = p[1];
                landmark[2] = p[2];
            }          
        }


        friend IMUInitializationResult initializeIMU(const std::vector<std::vector<double>>& absolutePoses,
                                                     const std::vector<std::vector<double>>& gyroscopeMeasurements,
                                                     const std::vector<std::vector<double>>& accelerometerMeasurements,
                                                     const FactorIMUParameters& imuParams, const CeresSolverOptions& solverOptions,
                                                     const IMUInitializationOptions& initOptions);

    };


    /** Gravity and scale estimation*/
    IMUInitializationResult initializeIMU(const std::vector<std::vector<double>>& absolutePoses,
                                          const std::vector<std::vector<double>>& gyroscopeMeasurements,
                                          const std::vector<std::vector<double>>& accelerometerMeasurements,
                                          const FactorIMUParameters& imuParams, const CeresSolverOptions& solverOptions,
                                          const IMUInitializationOptions& initOptions) {

        // initialize factor graph node ids
        int gravityId = 0;
        int scaleId = 1;
        int tformId = 2;
        std::vector<int> ids{3,4,5,6,7,8,gravityId,scaleId,tformId};
        Eigen::Quaterniond sensorTransformQuat(initOptions.m_SensorTransform.block<3,3>(0,0));
        std::vector<double> sensorTransformVector = {initOptions.m_SensorTransform(0,3),initOptions.m_SensorTransform(1,3),initOptions.m_SensorTransform(2,3),sensorTransformQuat.x(),sensorTransformQuat.y(),sensorTransformQuat.z(),sensorTransformQuat.w()};

        // create the factor graph
        auto fg = FactorGraph();

        // velocity prior
        if (initOptions.m_AddInitialVelocityPrior){
            auto velPriorFctr = make_unique<FactorVel3Prior>(vector<int>{ 4 });
            velPriorFctr->setMeasurement(initOptions.m_InitialVelocity);

            // velocity information matrix
            vector<double> priorVelInfo{ initOptions.m_InitialVelocityPriorWeight, 0.0, 0.0,  0.0, initOptions.m_InitialVelocityPriorWeight, 0.0,  0.0, 0.0, initOptions.m_InitialVelocityPriorWeight };
            velPriorFctr->setInformation(priorVelInfo.data());
            fg.addFactor(std::move(velPriorFctr));
        }

        // imu bias prior
        if (initOptions.m_AddInitialBiasPrior) {
            auto biasPriorFctr = make_unique<FactorIMUBiasPrior>(vector<int>{ 5 });
            biasPriorFctr->setMeasurement(initOptions.m_InitialBias);
            // information matrix
            vector<double> priorBiasInfo(36, 0.0);
            Eigen::Map<Eigen::Matrix<double, 6, 6, Eigen::RowMajor>> infoMatBias(priorBiasInfo.data());
            infoMatBias.diagonal() << initOptions.m_InitialBiasPriorWeight, initOptions.m_InitialBiasPriorWeight, initOptions.m_InitialBiasPriorWeight, initOptions.m_InitialBiasPriorWeight, initOptions.m_InitialBiasPriorWeight, initOptions.m_InitialBiasPriorWeight;
            biasPriorFctr->setInformation(priorBiasInfo.data());
            fg.addFactor(std::move(biasPriorFctr));
        }

        // pose prior information matrix
        vector<double> priorPoseInfo(36, 0.0);
        Eigen::Map<Eigen::Matrix<double, 6, 6, Eigen::RowMajor>> infoMatPose(priorPoseInfo.data());
        infoMatPose.diagonal() << initOptions.m_PosePriorWeight, initOptions.m_PosePriorWeight, initOptions.m_PosePriorWeight, initOptions.m_PosePriorWeight, initOptions.m_PosePriorWeight, initOptions.m_PosePriorWeight;

        // add the first pose variable and set it's state using addVariable
        fg.addVariable(ids[0], absolutePoses[0], int(VariableType::Pose_SE3));
        // hardly fix the pose variables
        fg.fixVariable(vector<int>{ ids[0] });

        // store all pose, velocity and bias ids.
        std::vector<int> allPoseIds{3}, allVelocityIds{4}, allBiasIds{5};
        // loop to add IMU factors with gravity, scale and sensor transform nodes
        for (size_t i=0; i < (absolutePoses.size()-1); i++) {

            auto imufctr = make_unique<FactorIMUGST>(ids.data(), imuParams.m_SampleRate, imuParams.m_negative_gravityAcceleration,
                                                               imuParams.m_GyroscopeBiasNoise.data(), imuParams.m_AccelerometerBiasNoise.data(), imuParams.m_GyroscopeNoise.data(), imuParams.m_AccelerometerNoise.data(),
                                                               gyroscopeMeasurements[i].data(), accelerometerMeasurements[i].data(), accelerometerMeasurements[i].size(), initOptions.m_SensorTransform.data());

            fg.addFactor(std::move(imufctr));
            // set initial guess for poses
            fg.setVariableState({ids[3]}, absolutePoses[i+1],7);

            if (initOptions.m_FixPoses) {
                // fix poses completely
                fg.fixVariable({ids[3]});
            }
            else {
                // add pose priors instead of fixing poses completely
                auto posePriorFctr = make_unique<FactorPoseSE3Prior>(vector<int>{ ids[3] });
                posePriorFctr->setMeasurement(absolutePoses[i+1].data());
                posePriorFctr->setInformation(priorPoseInfo.data());
                fg.addFactor(std::move(posePriorFctr));
            }

            // update current pose, velocity and bias ids
            for (size_t kk=0; kk < 6; kk++) {ids[kk] = ids[kk] + 3;}

            allPoseIds.push_back(ids[0]);
            allVelocityIds.push_back(ids[1]);
            allBiasIds.push_back(ids[2]);
        }

        // Fix scale variable if requested.
        if (initOptions.m_FixScale) {
            fg.fixVariable({scaleId});
        }

        // Fix sensor transform variable if requested.
        fg.setVariableState({tformId}, sensorTransformVector, 7);
        if (initOptions.m_FixSensorTransform) {
            fg.fixVariable({tformId});
        }

        // Execute factor graph optimization to initialize IMU.
        auto solutionInfo = fg.optimize(solverOptions, {-1});

        // Retrieve estimated pose scale, gravity rotation, sensor transform,
        // IMU bias and IMU velocity.
        auto result = IMUInitializationResult();
        result.Scale = 0.2;

        if (!solutionInfo.IsSolutionUsable){
            // The optimization didn't run successfully and failed in between.
            // The estimates will not be useful.
            result.Status = IMUInitializationStatus::FAILURE_BAD_OPTIMIZATION;
            return result;
        }

        // fill result after optimization.
        result.PosesInIMUReference = fg.getVariableState(allPoseIds);
        result.VelocityInIMUReference = fg.getVariableState(allVelocityIds);
        result.Bias = fg.getVariableState(allBiasIds);
        auto logOfScale = fg.getVariableState({scaleId});
        std::vector<double> scaleVector{exp(logOfScale[0])};
        result.Scale = scaleVector[0];
        auto gravityQuaternionVectorXYZW = fg.getVariableState({gravityId});
        Eigen::Map<const Eigen::Quaternion<double>> gravityQuaternion(gravityQuaternionVectorXYZW.data());
        result.GravityRotation = gravityQuaternion.toRotationMatrix();
        Eigen::Quaternion<double> gi = gravityQuaternion.inverse();

        // update quaternion representation to [qw,qx,qy,qz]
        std::vector<double> gravityQuaternionVector{gravityQuaternionVectorXYZW[3], gravityQuaternionVectorXYZW[0], gravityQuaternionVectorXYZW[1], gravityQuaternionVectorXYZW[2]};
        auto tformVector = fg.getVariableState({tformId});
        Eigen::Map<const Eigen::Quaternion<double>> tformQuaternion(tformVector.data() + 3);
        Eigen::Matrix<double, 4, 4, Eigen::RowMajor> sensorTransform = Eigen::Matrix<double, 4, 4, Eigen::RowMajor>::Identity();
        sensorTransform.block<3,3>(0,0) = tformQuaternion.toRotationMatrix();
        sensorTransform.block<3,1>(0,3) << tformVector[0], tformVector[1], tformVector[2];
        result.SensorTransform = sensorTransform;
        Eigen::Matrix<double, 4, 4, Eigen::RowMajor> transformToIMUReference = Eigen::Matrix<double, 4, 4, Eigen::RowMajor>::Identity();
        transformToIMUReference.block<3,3>(0,0) = gi.toRotationMatrix();
        result.TransformToIMUReference = transformToIMUReference;

        // validate the result
        std::vector<std::vector<double>> translationErrors, rotationErrors;
        if  (solutionInfo.TerminationType > 0) {
            // The initialization optimization didn't converge. Tune optimization
            // parameters to increase the iterations or reduce the tolerances,
            // use different data for convergence.
            result.Status = IMUInitializationStatus::FAILURE_NO_CONVERGENCE;
        }
        else {
            // compute prediction errors and see if they are within bounds.
            // Low prediction errors convey that the IMU is able to track poses
            // nicely using estimated gravity rotation, sensor transform and
            // scale.
            bool badPrediction = false;
            for (size_t k=0; k < (absolutePoses.size()-1); k++) {
                std::vector<int> ids1{allPoseIds[k],allVelocityIds[k],allBiasIds[k],allPoseIds[k+1],allVelocityIds[k+1],allBiasIds[k+1],gravityId, scaleId, tformId};
                auto imufctr = make_unique<FactorIMUGST>(ids1.data(), imuParams.m_SampleRate, imuParams.m_negative_gravityAcceleration,
                                                                   imuParams.m_GyroscopeBiasNoise.data(), imuParams.m_AccelerometerBiasNoise.data(), imuParams.m_GyroscopeNoise.data(), imuParams.m_AccelerometerNoise.data(),
                                                                   gyroscopeMeasurements[k].data(), accelerometerMeasurements[k].data(), accelerometerMeasurements[k].size(), initOptions.m_SensorTransform.data());

                // predict
                std::vector<double> predictedPose(7,0), predictedVelocity(3,0);
                imufctr->predict(result.Bias.data() + k*6, result.PosesInIMUReference.data() + k*7, result.VelocityInIMUReference.data() + k*3,
                                 gravityQuaternionVector.data(), scaleVector.data(), tformVector.data(), predictedPose.data(), predictedVelocity.data());

                auto rotDiffQuat = Eigen::Map<const Eigen::Quaternion<double>>(absolutePoses[k+1].data()+3) * (Eigen::Map<const Eigen::Quaternion<double>>(predictedPose.data()+3).inverse());
                Eigen::AngleAxisd rotDiffAxis(rotDiffQuat);
                // Extract the rotation angle (in radians)
                double angle = rotDiffAxis.angle();
                // Extract the rotation axis
                Eigen::Vector3d vec = rotDiffAxis.axis();
                std::vector<double> rotDiff{vec[0]*angle,vec[1]*angle,vec[2]*angle};
                std::vector<double> transDiff{result.Scale*(absolutePoses[k+1][0]-predictedPose[0]),result.Scale*(absolutePoses[k+1][1]-predictedPose[1]),result.Scale*(absolutePoses[k+1][2]-predictedPose[2])};
                translationErrors.push_back(transDiff);
                rotationErrors.push_back(rotDiff);
                if (!badPrediction && ((transDiff[0]*transDiff[0] + transDiff[1]*transDiff[1] + transDiff[2]*transDiff[2]) > initOptions.m_PredictionErrorThreshold[0]) && ((rotDiff[0]*rotDiff[0] + rotDiff[1]*rotDiff[1] + rotDiff[2]*rotDiff[2]) > initOptions.m_PredictionErrorThreshold[1])) {
                    badPrediction = true;
                }
            }

            // compute if bias is within bounds
            bool badBias = false;
            double dt = 1/imuParams.m_SampleRate;
            double t = 0;
            auto initialBias = std::vector<double>(result.Bias.data(),result.Bias.data()+6);
            double biasVariance[6] = {sqrt(imuParams.m_GyroscopeBiasNoise(0,0)),
                    sqrt(imuParams.m_GyroscopeBiasNoise(1,1)),
                    sqrt(imuParams.m_GyroscopeBiasNoise(2,2)),
                    sqrt(imuParams.m_AccelerometerBiasNoise(0,0)),
                    sqrt(imuParams.m_AccelerometerBiasNoise(1,1)),
                    sqrt(imuParams.m_AccelerometerBiasNoise(2,2)) };
            size_t ind = 6;
            for (size_t k=0; k < (absolutePoses.size()-1); k++) {
                t = t + dt * static_cast<double>(gyroscopeMeasurements[k].size())/3;
                if ((result.Bias[ind]  > initialBias[0]  + sqrt(t)*initOptions.m_BiasCovarianceMultiplier*biasVariance[0]) ||
                    (result.Bias[ind]  < initialBias[0]  - sqrt(t)*initOptions.m_BiasCovarianceMultiplier*biasVariance[0]) ||
                    (result.Bias[ind+1] > initialBias[1] + sqrt(t)*initOptions.m_BiasCovarianceMultiplier*biasVariance[1]) ||
                    (result.Bias[ind+1] < initialBias[1] - sqrt(t)*initOptions.m_BiasCovarianceMultiplier*biasVariance[1]) ||
                    (result.Bias[ind+2] > initialBias[2] + sqrt(t)*initOptions.m_BiasCovarianceMultiplier*biasVariance[2]) ||
                    (result.Bias[ind+2] < initialBias[2] - sqrt(t)*initOptions.m_BiasCovarianceMultiplier*biasVariance[2]) ||
                    (result.Bias[ind+3] > initialBias[3] + sqrt(t)*initOptions.m_BiasCovarianceMultiplier*biasVariance[3]) ||
                    (result.Bias[ind+3] < initialBias[3] - sqrt(t)*initOptions.m_BiasCovarianceMultiplier*biasVariance[3]) ||
                    (result.Bias[ind+4] > initialBias[4] + sqrt(t)*initOptions.m_BiasCovarianceMultiplier*biasVariance[4]) ||
                    (result.Bias[ind+4] < initialBias[4] - sqrt(t)*initOptions.m_BiasCovarianceMultiplier*biasVariance[4]) ||
                    (result.Bias[ind+5] > initialBias[5] + sqrt(t)*initOptions.m_BiasCovarianceMultiplier*biasVariance[5]) ||
                    (result.Bias[ind+5] < initialBias[5] - sqrt(t)*initOptions.m_BiasCovarianceMultiplier*biasVariance[5]) ) {

                    // bias is out of bounds
                    badBias = true;
                    break;
                }
                ind += 6;
            }

            bool badScale = false;
            if ((!std::isnan(initOptions.m_ScaleThreshold)) && (result.Scale < initOptions.m_ScaleThreshold))
                // do the scale validation when a non-NaN scale threshold is provided
                badScale = true;

            if (badPrediction & (!badBias) & (!badScale))
                result.Status = IMUInitializationStatus::FAILURE_BAD_PREDICTION;
            else if ((!badPrediction) & badBias & (!badScale))
                result.Status = IMUInitializationStatus::FAILURE_BAD_BIAS;
            else if ((!badPrediction) & (!badBias) & badScale)
                result.Status = IMUInitializationStatus::FAILURE_BAD_SCALE;
            else if (badPrediction & badBias & (!badScale))
                result.Status = IMUInitializationStatus::FAILURE_BAD_PREDICTION_BIAS;
            else if ((!badPrediction) & badBias & badScale)
                result.Status = IMUInitializationStatus::FAILURE_BAD_SCALE_BIAS;
            else if (badPrediction & (!badBias) & badScale)
                result.Status = IMUInitializationStatus::FAILURE_BAD_SCALE_PREDICTION;
            else if (badPrediction & badBias & badScale)
                result.Status = IMUInitializationStatus::FAILURE_BAD_SCALE_PREDICTION_BIAS;
            else
                result.Status = IMUInitializationStatus::SUCCESS;
        }

        // Scale the velocity estimates to IMU reference frame.
        for (size_t i = 0; i < result.VelocityInIMUReference.size(); ++i) {
            result.VelocityInIMUReference[i] = result.Scale * result.VelocityInIMUReference[i];
        }

        
        // transform the poses to IMU reference frame.
        size_t numPoses = result.PosesInIMUReference.size()/7;
        size_t ind = 0;
        for (size_t i = 0; i < numPoses; ++i) {
            // scale translation and rotate using inverse of gravity quaternion.
            Eigen::Matrix<double, 3, 1> t =  result.Scale * (gi * Eigen::Map<const Eigen::Matrix<double, 3, 1>>(result.PosesInIMUReference.data() + ind));
            Eigen::Quaternion<double> q = gi * Eigen::Map<const Eigen::Quaternion<double>>(result.PosesInIMUReference.data() + ind + 3);
            result.PosesInIMUReference[ind] = t[0];
            result.PosesInIMUReference[ind+1] = t[1];
            result.PosesInIMUReference[ind+2] = t[2];
            result.PosesInIMUReference[ind+3] = q.x();
            result.PosesInIMUReference[ind+4] = q.y();
            result.PosesInIMUReference[ind+5] = q.z();
            result.PosesInIMUReference[ind+6] = q.w();
            ind += 7;
        }
        
        return result;
    }
}

#endif //IMU_INITIALIZATION_UTILITIES_HPP
