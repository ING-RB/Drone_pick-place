function [gRot, info] = estimateGravityRotation(poses, gyroscopeReadings, accelerometerReadings, varargin)
%ESTIMATEGRAVITYROTATION Estimate gravity rotation using IMU measurements 
%   and factor graph optimization
%
%   The estimateGravityRotation function estimates the gravity rotation
%   that helps transform input poses to the local navigation reference
%   frame of IMU using IMU measurements and factor graph optimization. The
%   gravity rotation transforms the gravity vector from the local
%   navigation reference frame of IMU to the pose reference frame.
%
%   The accelerometer measurements contain constant gravity acceleration
%   that does not contribute to motion. You must remove this from the
%   measurements for accurate fusion with other sensor data. The input pose
%   reference frame may not always match the local navigation reference
%   frame of IMU, North-East-Down (NED) or East-North-Up (ENU) in which the
%   gravity direction is known. So, it is necessary to transform the input
%   poses to the local navigation frame to remove the known gravity effect.
%   The estimated rotation helps align the input pose reference frame and
%   local navigation reference frame of IMU.
%
%   [GROT,INFO] = estimateGravityRotation(poses, gyroscopeReadings,
%         accelerometerReadings, Name=Value) estimates the rotation
%   required to transform the gravity vector from the local navigation
%   reference frame of IMU (NED or ENU) to the input pose reference frame.
%
%   Note: Input poses must be in the initial IMU reference frame unless you
%   specify the SensorTransform name-value argument, then the poses can be
%   in a different frame.
%
%   Inputs:
%
%       poses - Camera or lidar poses, with similar metric units as 
%          IMU measurements estimated by stereo-visual-inertial or
%          lidar-inertial system respectively.
%
%       The poses must be specified in one of the following formats:
%          N-by-7 matrix | array of se3 objects | table 
%                                         | array of rigidtform3d objects
%
%       gyroscopeReadings - Gyroscope readings (radians/second) between 
%          consecutive poses.
%
%          Gyroscope readings must be specified as:           
%             (N-1)-element cell array of M-by-3 matrices
%
%
%       accelerometerReadings - Accelerometer readings (m/s^2) between
%           consecutive poses.
%
%           Accelerometer readings must be specified as:
%           (N-1)-element cell array of M-by-3 matrices
%
%
%   Outputs:
%
%      GROT    - Gravity rotation.
% 
%      Gravity rotation is the rotation required to transform the gravity
%      vector ([0,0,9.81] or [0,0,-9.81]) from the local navigation 
%      reference frame of IMU (NED or ENU) to the input pose reference
%      frame.
%
%      Gravity rotation will be returned in one of the following types
%      matching the input pose type:
%                3-by-3 matrix | se3 object | rigidtform3d object
% 
%      INFO    - Additional information returned as a struct.
%
%      Debug information fields:
%      
%      Status : Validation status specifying if all the validation
%         checks performed passed returned as a 
%         nav.GravityRotationEstimationStatus enum.
% 
%              PASSED : All validation checks passed.
%              FAILURE_BAD_PREDICTION : Prediction error is above 
%                 specified threshold.
%              FAILURE_BAD_BIAS : Bias variation from the initial value 
%                 is out of expected bounds computed from bias covariance 
%                 values provided.
%              FAILURE_BAD_PREDICTION_BIAS : Prediction error is above 
%                 specified threshold and bias variation from initial value
%                 is out of expected bounds.
%              FAILURE_BAD_OPTIMIZATION : Optimization ran into errors and 
%                 estimates are not usable.
%              FAILURE_NO_CONVERGENCE : Initialization optimization didn't 
%                 converge in specified number of iterations. Increase 
%                 the max number of iterations.
%
%      RotationalErrors : Rotation errors in IMU pose prediction after 
%          executing factor graph optimization to estimate the parameters
%          returned as an (N-1)-by-3 double matrix.
%
%          Rotation error is rotation vector (1-by-3)storing difference 
%          in relative rotation between successive poses computed directly 
%          from input poses and using IMU pose prediction. Lower rotation
%          error conveys that the relative rotation predicted using IMU 
%          measurements is very close to input pose estimates.
%                            
%      TranslationErrors: Translation errors in IMU pose prediction after
%          executing factor graph optimization to estimate parameters
%          returned as an (N-1)-by-3 double matrix.
%
%          Translation error is the difference in relative translation 
%          ([x,y,z]) between successive poses computed directly from input 
%          poses and using IMU pose prediction. Lower translation
%          error conveys that the relative translation predicted using IMU 
%          measurements is very close to input pose estimates.
%
%      Additional information fields useful in downstream workflows:
%
%      PosesInIMUReference : Refined poses transformed to IMU navigation 
%          reference frame using estimated gravity rotation and pose scale 
%          returned in the same format as input poses.
%
%      VelocityInIMUReference : Velocity estimates at input pose sampling 
%          times in IMU navigation reference frame returned 
%          as N-by-3 double matrix.
%
%          Use the velocity as initial guess for the newly added 
%          velocity nodes in visual-inertial factor graph.
%
%       Bias : Bias estimates at input pose sampling times returned as 
%          N-by-6 double matrix.
%
%          Use the bias as initial guess for the newly added bias nodes
%          in visual-inertial factor graph.
%
%       PoseToIMUTransform : Transformation from input pose reference frame
%          to IMU navigation reference frame returned as an se3 object.
%          This is the inverse of gravity rotation.
%
%      Factor graph optimization information fields:
%
%      InitialCost : Initial cost of the factor graph problem 
%          formulated for estimation returned as a scaler.
%
%      FinalCost : Final cost of the factor graph problem formulated 
%          for estimation. The lower the better.
%
%      NumSuccessfulSteps : Number of successful iterations in which 
%          the solver decreases the cost during estimation optimization.
%
%      NumUnsuccessfulSteps : Number of optimizer iterations in which 
%          the iteration is numerically invalid or the solver does not 
%          decrease the cost during the estimation. The sum of 
%          NumSuccessfulSteps and NumUnsuccessfulSteps indicates the 
%          total number of optimization iterations executed 
%          during estimation.
%
%      TotalTime : Total time in seconds spent for executing optimization 
%          iterations during estimation.
%   
%      TerminationType : Termination type of factor graph optimization 
%          executed during estimation returned as an integer in the 
%          range [0, 2]:
%          0 - Solver found a solution that meets convergence criterion 
%          and decreases in cost after optimization.
%          1 - Solver could not find a solution that meets convergence 
%          criterion after running for the maximum number of iterations.
%          2 - Solver terminated due to an error.
%
%          If the termination type is greater than zero that means there 
%          is still some scope for improvement. Increase the number of max
%          iterations specified in solver options or improve the input
%          measurements for better result.
%
%       IsSolutionUsable : The factor graph optimization formulated for 
%          estimation ran successfully without any issues and the estimates
%          of may be useful. The value is 1 (true) if the solution is 
%          usable and the value is 0 (false) if the solution is not usable.
%
%
%   estimateGravityRotation Name-Value arguments:
%
%      IMUParameters   - IMU parameters, specifying sample rate, 
%         IMU noise and bias covariances and IMU navigation reference
%         frame to use specified as a factorIMUParameters object.
%
%          It is very important to specify these parameters especially the 
%          sample rate noise and bias covariances. If covariances are 
%          unknown use allan variance analysis of static IMU measurements 
%          to estimate. The default IMU parameters specify identity noise 
%          covariances which is very large compared to practical 
%          IMU covariances.
%
%        factorIMUParameters() (default) | factorIMUParameters object
%
%      SolverOptions   - Factor graph solver options to use during the
%          estimation specified as a factorGraphSolverOptions object.
%
%          For example TrustRegionStrategyType parameter value 0 uses 
%          Levenberg Marquardt non-linear solver. 
%          Low InitialTrustRegionRadius parameter value of 0.1 makes 
%          the optimizer to have higher trust input pose estimates.
%          Increase the MaxIterations value whenever estimation failure is 
%          encountered due to NO_CONVERGENCE.
%
%   factorGraphSolverOptions() (default) |  factorGraphSolverOptions object
%
%      SensorTransform - Transformation consisting of 3-D translation and
%          rotation to transform a quantity like a pose or a point from 
%          input pose reference frame to corresponding IMU frame, 
%          specified as a se3 object.
%
%          For example input poses are often in initial camera reference 
%          frame where the first camera pose is at the origin of coordinate
%          frame. In this case the sensor transform specifies SE(3) 
%          transformation from camera to IMU that are rigidly attached to
%          each other. In some cases both camera and IMU may be attached 
%          rigidly to a common base and poses are computed in base
%          reference frame. Then the sensor transform specifies 
%          transformation from base to IMU.
%
%          It is very important to specify this parameter accurately. 
%          If this parameter is unknown use extrinsic calibration 
%          for estimating this. 
%
%        se3() (default) | se3 object
%
%        FixPoses - Flag to fix in poses during estimation. When true the
%            input poses are not refined during estimation process. When
%            false the input poses are also slightly refined during
%            estimation. Not fixing the poses gives more freedom to
%            estimator and achieve better results in general. If the input
%            poses are expected to be very highly accurate fixing them will
%            be computationally less expensive and may result in better
%            accuracy.
%
%            true (default) | logical
%
%        InitialVelocity - IMU initial velocity guess. By default the
%            initial velocity is considered unknown and set to NaN. Specify
%            initial velocity is whenever it is known. For example IMU
%            might be starting from zero velocity most often or initial
%            velocity can be computed from GPS.
%
%            [NaN,NaN,NaN] (default) | double
%
%        PredictionThreshold - IMU pose prediction threshold specified 
%            as a 1-by-2 double storing 
% [rotationErrorThreshold in meters, translationErrorThreshold in radians].
%
%             This is the measure how the IMU pose predictions aligned 
%             with input camera poses after estimation. The lower the 
%             better. If the input camera poses are not accurate
%             larger thresholds may also be acceptable.
%
%             [5e-2,5e-2] | double
%
%
%   Example:
%      % Specify input poses in the first camera pose reference frame.
%      poses = [0.1,0,0,0.7071,0,0,0.7071; ...
%               0.1,0.4755,-0.1545,0.7071,0,0,0.7071];
%
%      % Specify 10 gyroscope and accelerometer readings between
%      % consecutive camera frames.
%      accelReadings = repmat([97.9887,-3.0315,-22.0285],10,1);
%      gyroReadings = zeros(10,3);
%
%      % Specify IMU parameters.
%      params = factorIMUParameters(SampleRate=100,...
%                                   ReferenceFrame="NED");
%
%      % specify rigid transformation to convert poses from the first
%      % camera pose reference frame to the first IMU pose reference frame.
%      sensorTransform = se3(eul2rotm([-pi/2,0,0]),[0,0.1,0]);
%
%      % specify factor graph solver options
%      opts = factorGraphSolverOptions(MaxIterations=50); 
%       
%      % Estimate gravity rotation.
%      [gDir, solutionInfo] = ...
%                 estimateGravityRotation(...
%                 poses, {gyroReadings}, {accelReadings}, ...
%                 IMUParameters = params, ...
%                 SensorTransform = sensorTransform,...
%                 SolverOptions = opts);
%
%   References:
%
%   [1] C. Campos, R. Elvira, J. J. G. Rodriguez, J. M. M. Montiel and J.
%   D. Tardos, "ORB-SLAM3: An Accurate Open-Source Library for Visual,
%   Visual-Inertial, and Multimap SLAM," in IEEE Transactions on Robotics,
%   vol. 37, no. 6, pp. 1874-1890, Dec. 2021, doi:
%   10.1109/TRO.2021.3075644.
%
%
%   See also factorIMU, factorIMUParameters,
%   estimateGravityRotationAndPoseScale

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    narginchk(3,15);
    
    [gRot, ~, info] = nav.algs.internal.estimateGS(...
        false, 'estimateGravityRotation',...
        poses, gyroscopeReadings, accelerometerReadings, varargin{:});

end