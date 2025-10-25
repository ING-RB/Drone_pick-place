classdef insEKF < positioning.internal.insEKFBase & ...
    matlab.mixin.CustomDisplay & positioning.internal.insEKFTuner
% INSEKF Inertial Navigation System using an Extended Kalman Filter
%
%   FILT = INSEKF implements an extended Kalman filter which is capable of
%   fusing accelerometer and gyroscope data to estimate orientation. 
%
%   FILT = INSEKF(SENSOR1, SENSOR2, ..., SENSORN) implements a filter which
%   fuses data from SENSOR1, SENSOR2, ..., and SENSORN to estimate
%   orientation or pose. 
%
%   FILT = INSEKF(..., MOTIONMODEL) implements a filter which
%   fuses data from several sensors to estimate orientation or pose based
%   on a motion model defined by MOTIONMODEL. 
%
%   FILT = INSEKF(..., OPTS) implements a filter based on the options
%   defined in an INSOPTS object OPTS.
%
%   INSEKF Methods:
%
%   predict                 - Propagate state estimates forward in time
%   fuse                    - Fuse sensor data to correct states
%   residual                - Residuals and residual covariance from data
%   correct                 - Correct states with direct state measurement
%   stateparts              - Get and set portions of the State vector
%   statecovparts           - Get and set portions of the StateCovariance
%   stateinfo               - Indices of a portion of the State vector
%   estimateStates          - Batch fusion of sensor data
%   tune                    - Automatic noise parameter tuning
%   createTunerCostTemplate - Sample cost function for filter tuning
%   tunerCostFcnParam       - Example input argument of tuner cost function
%
%   INSEKF Properties:
%
%   State                - State vector of the extended Kalman filter
%   StateCovariance      - State covariance of the extended Kalman filter
%   AdditiveProcessNoise - Additive process noise for the filter
%   MotionModel          - Handle to motion model used by the filter
%   Sensors              - Cell array of handles of sensors being fused
%   SensorNames          - Cell array of names of sensors being fused
%   ReferenceFrame       - Reference frame for data, either NED or ENU
%
%   % Example: Create filters for fusion of various sensors
%   
%   % Fusion of accelerometer and gyroscope
%   filt1 = insEKF;  
%
%   % Fusion of accelerometer, gyroscope, and magnetometer fusion with 
%   % a motion model tracking orientation
%   filt2 = insEKF(insAccelerometer, insGyroscope, insMagnetometer, ...
%       insMotionOrientation);
%
%   % Fusion of accelerometer, gyroscope, and GPS in the 
%   % ENU reference frame
%   opts = insOptions(ReferenceFrame="ENU");
%   filt3 = insEKF(insAccelerometer, insGyroscope, insGPS, opts);
%
%   % Example: Batch fusion of accelerometer and gyroscope data
%
%   ld = load("accelGyroINSEKFData.mat");
%   filt = insEKF;
%   stateparts(filt, "Orientation", compact(ld.initOrient));
%   statecovparts(filt, "Orientation", 1e-2);
%
%   % Use optimal noise parameters obtained using the tune function. See
%   % help insEKF/tune for more information.
%   mnoise = struct("AccelerometerNoise", 0.1739, ...
%       "GyroscopeNoise", 1.1129);
%   apn = diag([...
%     2.8586 1.3718 0.8956 3.2148 4.3574 2.5411 3.2148 0.5465 0.2811 ...
%     1.7149 0.1739 0.7752 0.1739]);
%   filt.AdditiveProcessNoise = apn;
%   
%   % Estimate states
%   est = estimateStates(filt, ld.sensorData, mnoise);
%   plot(rad2deg(dist(est.Orientation, ld.groundTruth.Orientation)))
%   title("Orientation Estimate Error (degrees)")
%
%   % Example: Sample-by-sample fusion of accelerometer and gyroscope
%   ld = load("accelGyroINSEKFData.mat");
%   accel = insAccelerometer;
%   gyro = insGyroscope;
%   filt = insEKF(accel,gyro);
%   stateparts(filt, "Orientation", compact(ld.initOrient));
%   statecovparts(filt, "Orientation", 1e-2);
%
%   % Use optimal noise parameters obtained using the tune function. See
%   % help insEKF/tune for more information.
%   accNoise = 0.1739;
%   gyroNoise = 1.1129;
%   apn = diag([...
%     2.8586 1.3718 0.8956 3.2148 4.3574 2.5411 3.2148 0.5465 0.2811 ...
%     1.7149 0.1739 0.7752 0.1739]);
%   filt.AdditiveProcessNoise = apn;
%
%   N = size(ld.sensorData,1);
%   estOrient = quaternion.zeros(N,1);
%   dt = seconds(diff(ld.sensorData.Properties.RowTimes));
%   for ii=1:N
%       if ii~=1   
%           % Step forward in time
%           predict(filt, dt(ii-1));
%       end
%       fuse(filt,accel, ld.sensorData.Accelerometer(ii,:), accNoise);
%       fuse(filt,gyro, ld.sensorData.Gyroscope(ii,:), gyroNoise);
%       estOrient(ii) = quaternion(stateparts(filt, "Orientation"));
%   end
%   plot(rad2deg(dist(estOrient, ld.groundTruth.Orientation)))
%   title("Orientation Estimate Error (degrees)")
%
%   See also: insOptions, insAccelerometer,  insMotionOrientation

%   Copyright 2021-2022 The MathWorks, Inc.    

    %#codegen
   
    % Caches for names used in stateinfo, stateparts, statecovparts.
    % These are not used in codegen so they are not in the base class.
    % Used in getStateInfo>chkstring so they are Hidden.
    properties (Hidden)
        StatesCacheWithHandle
        StatesCacheWithoutHandle
    end

    methods (Hidden, Static)
        function name = matlabCodegenRedirect(~)
            name = 'positioning.internal.insEKFBase';
        end
    end



end
