classdef ahrsfilter <  fusion.internal.AHRSFilterMATLABBase & ...
        fusion.internal.UnitDisplayer & ...
        fusion.internal.tuner.FilterTuner
%AHRSFILTER Orientation from accelerometer, magnetometer, and gyroscope
%
%   FUSE = AHRSFILTER returns an indirect Kalman filter System object,
%   FUSE, for fusion of accelerometer, gyroscope, and magnetometer
%   data to estimate device orientation. The filter uses a 12 element
%   state vector to track the error in the device orientation estimate
%   (as a rotation vector), the error in the gyroscope bias estimate, the
%   error in the linear acceleration estimate, and the magnetic
%   disturbance error.
%
%   FUSE = AHRSFILTER('ReferenceFrame', RF) returns an AHRSFILTER System 
%   object that fuses accelerometer, gyroscope, and magnetometer data to 
%   estimate device orientation relative to the reference frame RF. Specify
%   the reference frame as 'NED' (North-East-Down) or 'ENU' 
%   (East-North-Up). The default value is 'NED'.
%
%   FUSE = AHRSFILTER('PropertyName', PropertyValue, ...) returns
%   an indirect Kalman sensor fusion filter, FUSE, with each specified
%   property set to a specified value.
%
%   Step method syntax:
%
%   [ORNT, AV] = step(FUSE, ACC, GYRO, MAG) fuses the accelerometer data
%   ACC, gyroscope data GYRO, and magnetometer data MAG,  to compute device
%   orientation ORNT and angular velocity AV. 
% 
%   [ORNT, AV, INTERDATA] = step(FUSE, ACC, GYRO, MAG) fuses the
%   accelerometer data ACC, gyroscope data GYRO, and magnetometer data MAG,
%   to compute device orientation ORNT, angular velocity AV, and
%   intermediate data INTERDATA.
%
%   The inputs are:
%       ACC       - N-by-3 array of accelerometer readings in m/s^2
%       GYRO      - N-by-3 array of gyroscope readings in rad/s
%       MAG       - N-by-3 array of magnetometer readings in uT
%   where N is the number of samples. The three columns of each input
%   array represent the [X Y Z] measurements. 
%
%   The outputs are:
%       ORNT      - an M-by-1 array of orientation quaternions that can be
%                   used to rotate quantities in the global frame of
%                   reference to the sensor frame of reference.
%       AV        - an M-by-3 array of angular velocity measurements in
%                   rad/s in the sensor's frame of reference, with the
%                   gyroscope bias removed.
%       INTERDATA - an M-by-1 struct with fields Residual and
%                   ResidualCovariance. Residual is a 6-element row vector
%                   of form [m/s^2 m/s^2 m/s^2 uT uT uT] and
%                   ResidualCovariance is a 6-by-6 matrix.
%   where, M is computed as N/DecimationFactor.
%
%   System objects may be called directly like a function instead of
%   using the step method. For example, y = step(obj, a, g, m) and y =
%   obj(a, g, m) are equivalent.
%
%   AHRSFILTER methods:
%
%   step                - See above description for use of this method
%   release             - Allow changes to non-tunable properties
%                         values and input characteristics
%   clone               - Create an AHRSFILTER object with the same
%                         property values and internal states
%   isLocked            - Locked status (logical)
%   reset               - Reset the internal states to initial
%                         conditions
%   tune                - Tune filter parameters to reduce estimation error
%   residual            - Residual and residual covariance from sensor data
%
%   AHRSFILTER properties:
%   
%   SampleRate                     - Sample rate of data from sensor
%   DecimationFactor               - Decimation factor
%   AccelerometerNoise             - Noise in accelerometer signal
%   MagnetometerNoise              - Noise in magnetometer signal
%   GyroscopeNoise                 - Noise in the gyroscope signal
%   GyroscopeDriftNoise            - Gyroscope bias drift noise
%   LinearAccelerationNoise        - Linear acceleration noise variance
%   LinearAccelerationDecayFactor  - Linear acceleration noise decay 
%                                    factor 
%   MagneticDisturbanceNoise       - Magnetic disturbance noise
%   MagneticDisturbanceDecayFactor - Magnetic Disturbance noise decay 
%                                    factor 
%   InitialProcessNoise            - Initial process covariance matrix
%   ExpectedMagneticFieldStrength  - Earth's magnetic field strength 
%   OrientationFormat              - Quaternion or rotation matrix
%
%   % EXAMPLE: Estimate orientation from recorded IMU data.
%   
%   %  The data in rpy_9axis.mat is recorded accelerometer, gyroscope
%   %  and magnetometer sensor data from a device oscillating in pitch
%   %  (around y-axis) then yaw (around z-axis) then roll (around
%   %  x-axis). The device's x-axis was pointing southward when
%   %  recorded. The IMUFILTER fusion ignores the MagneticField data
%   %  in the sensorData struct, and only uses the gyroscope and
%   %  accelerometer data in its fusion algorithm. The IMUFILTER
%   %  fusion algorithm correctly estimates the motion of the device
%   %  in roll and pitch. However, the algorithm assumes the device is
%   %  initially pointing northward (because it does not use the
%   %  magnetometer) and correctly computes relative change in yaw
%   %  from the starting yaw. To correctly estimate the orientation
%   %  with absolute yaw use the AHRSFILTER, which requires
%   %  magnetometer data.
%
%   ld = load('rpy_9axis.mat');    
%   accel = ld.sensorData.Acceleration;
%   gyro = ld.sensorData.AngularVelocity;
%   mag = ld.sensorData.MagneticField;
%
%   Fs  = ld.Fs;  % Hz
%   decim = 2;    % Decimate by 2 to lower computational cost
%   fuse = ahrsfilter('SampleRate', Fs, 'DecimationFactor', decim);
%
%   % Fuse accelerometer, gyroscope, and magnetometer
%   q = fuse(accel, gyro, mag);
%       
%   % Plot Euler angles in degrees
%   plot(rad2deg(unwrap(euler( q, 'ZYX', 'frame'))));
%   title('Orientation Estimate');
%   legend('Z-rotation', 'Y-rotation', 'X-rotation');
%   ylabel('Degrees');
%
%   See also IMUFILTER, ECOMPASS, QUATERNION

%   Copyright 2017-2023 The MathWorks, Inc.
    

    properties (Constant, Hidden)
        SampleRateUnits = 'Hz'
        AccelerometerNoiseUnits = ['(m/s' sqSym ')' sqSym];
        GyroscopeNoiseUnits = ['(rad/s)' sqSym];
        GyroscopeDriftNoiseUnits = ['(rad/s)' sqSym];
        LinearAccelerationNoiseUnits = ['(m/s' sqSym ')' sqSym];     
        MagneticDisturbanceNoiseUnits = [ '(' uTSym ')' sqSym];
        ExpectedMagneticFieldStrengthUnits = uTSym;
        MagnetometerNoiseUnits = [ '(' uTSym ')' sqSym];
    end    

    methods
        function obj = ahrsfilter(varargin)
            setProperties(obj,nargin,varargin{:});
        end
    end 
    
    methods (Access = protected)
        function displayScalarObject(obj)
            displayScalarObjectWithUnits(obj);
        end
        function groups = getPropertyGroups(obj)
            list.SampleRate                     = obj.SampleRate;
            list.DecimationFactor               = obj.DecimationFactor;
            list.AccelerometerNoise             = obj.AccelerometerNoise;
            list.GyroscopeNoise                 = obj.GyroscopeNoise;
            list.MagnetometerNoise              = obj.MagnetometerNoise;
            list.GyroscopeDriftNoise            = obj.GyroscopeDriftNoise;
            list.LinearAccelerationNoise        = obj.LinearAccelerationNoise;
            list.MagneticDisturbanceNoise       = obj.MagneticDisturbanceNoise;
            list.LinearAccelerationDecayFactor  = obj.LinearAccelerationDecayFactor;
            list.MagneticDisturbanceDecayFactor = obj.MagneticDisturbanceDecayFactor;
            list.ExpectedMagneticFieldStrength  = obj.ExpectedMagneticFieldStrength;
            list.InitialProcessNoise            = obj.InitialProcessNoise;
            list.OrientationFormat              = obj.OrientationFormat;
            groups = matlab.mixin.util.PropertyGroup(list);
        end
    end
    methods (Hidden, Static)
        function name = matlabCodegenRedirect(~)
            name = 'fusion.internal.coder.ahrsfiltercg';
        end
        function flag = isAllowedInSystemBlock
            flag = false;
        end
    end
    
    methods (Static)
        function p = defaultProcessNoise()
            p = fusion.internal.AHRSFilterBase.getInitialProcCov(); 
        end
    end

    % Methods related to autotuner (tune() function).
    % Facade for methods in fusion.internal.tuner.ahrsfilter
    methods
        function varargout = tune(obj, varargin)
        %TUNE Tune filter parameters to reduce orientation error
        %   TUNE(FILT, SENSORDATA, GROUNDTRUTH) adjusts the properties of the
        %   ahrsfilter, FILT, to reduce the root-mean-squared (RMS) quaternion
        %   distance error between the fused sensor data and ground truth.
        %   The function fuses the sensor readings in SENSORDATA to estimate
        %   the orientation, which is compared to the orientation in
        %   GROUNDTRUTH. The function uses the property values in FILT as the
        %   starting guess for the optimization algorithm.  The SENSORDATA
        %   input is a table with three variables, 'Accelerometer',
        %   'Gyroscope', and 'Magnetometer'. Each variable is an array of
        %   N-by-3 matrices of the corresponding sensor readings. The
        %   GROUNDTRUTH input is a table with a single variable,
        %   'Orientation', specified as an array of 3-by-3 rotation
        %   matrices or an array of quaternion objects. The TUNE function
        %   processes each row of both tables sequentially to calculate the
        %   estimated orientation error.
        %
        %   TUNE(..., CFG) adjusts the properties of the ahrsfilter, FILT,
        %   according to CFG which is produced by the tunerconfig() function.
        %   If CFG.Cost is set to Custom then any types are allowed for
        %   SENSORDATA and GROUNDTRUTH.
        %
        %   Example : Tune filter to optimize orientation estimate
        %   
        %   % Load recorded sensor data and ground truth
        %   ld = load('ahrsfilterTuneData.mat');
        %   qTrue = ld.groundTruth.Orientation; % true orientation
        %   fuse = ahrsfilter;
        %   
        %   % Fuse with an untuned filter
        %   qEstUntuned = fuse(ld.sensorData.Accelerometer, ...
        %       ld.sensorData.Gyroscope, ld.sensorData.Magnetometer);
        %   
        %   % Automatically tune the ahrsfilter improve the orientation estimate 
        %   cfg = tunerconfig('ahrsfilter', 'ObjectiveLimit', 0.08);
        %   tune(fuse, ld.sensorData, ld.groundTruth, cfg);
        %   % Fuse again with the tuned filter
        %   qEstTuned = fuse(ld.sensorData.Accelerometer, ... 
        %       ld.sensorData.Gyroscope, ld.sensorData.Magnetometer);
        %   
        %   % Compare the tuned vs untuned filter RMS error performance
        %   dUntuned = rad2deg(dist(qEstUntuned, qTrue));
        %   dTuned = rad2deg(dist(qEstTuned, qTrue));
        %   rmsUntuned = sqrt(mean(dUntuned.^2))
        %   rmsTuned = sqrt(mean(dTuned.^2))
        %   
        %   % Plot error over time
        %   N = numel(dUntuned);
        %   t = (0:N-1)./ fuse.SampleRate;
        %   plot(t, dUntuned, 'r', t, dTuned, 'b'); 
        %   legend('Untuned', 'Tuned');
        %   title('ahrsfilter - Tuned vs Untuned Error')
        %   xlabel('Time (s)');
        %   ylabel('Orientation Error (degrees)');
        %
        %   See also TUNERCONFIG

            [varargout{1:nargout}] = tune@fusion.internal.tuner.FilterTuner(obj, varargin{:}); 
        end
    end
    methods (Static, Hidden)
        function [tunerparams, staticparams]  = getParamsForAutotune
            [tunerparams, staticparams]  = fusion.internal.tuner.ahrsfilter.getParamsForAutotune;
        end
        function [cost, stateEst] = tunerfuse(params, sensorData, groundTruth, cfg)
            [cost, stateEst] = fusion.internal.tuner.ahrsfilter.tunerfuse(params, sensorData, groundTruth, cfg);
        end
        function measNoise = getMeasNoiseExemplar
            measNoise = fusion.internal.tuner.ahrsfilter.getMeasNoiseExemplar;
        end
        function tf = hasMeasNoise
            tf = fusion.internal.tuner.ahrsfilter.hasMeasNoise;
        end
    end
    methods (Access = protected)
        function sensorData = processSensorData(~, sensorData)
            sensorData = fusion.internal.tuner.ahrsfilter.processSensorData(sensorData);
        end
        function groundTruth = processGroundTruth(~, groundTruth)
            groundTruth = fusion.internal.tuner.ahrsfilter.processGroundTruth(groundTruth);
        end
        function varargout = makeTunerOutput(obj, info, ~)
            [varargout{1:nargout}] = fusion.internal.tuner.ahrsfilter.makeTunerOutput(obj, info);
        end
        function crossValidateInputs(obj, sensorData, groundTruth)
            coder.internal.assert(height(groundTruth) * obj.DecimationFactor == height(sensorData), ...
                'shared_positioning:tuner:DecimFactorMismatch', 'ahrsfilter', 'DecimationFactor');
        end
    end
end

function s = sqSym()
    s = char(178);
end

function s = uTSym()
    s = [char(181) 'T'];
end
