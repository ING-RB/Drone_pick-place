classdef imufilter < fusion.internal.IMUFilterMATLABBase & ...
        fusion.internal.UnitDisplayer & ...
        fusion.internal.tuner.FilterTuner
%IMUFILTER Orientation from accelerometer and gyroscope readings 
%
%   FUSE = IMUFILTER returns an indirect Kalman filter System object FUSE
%   for sensor fusion of accelerometer and gyroscope data to estimate
%   device orientation. The filter uses a 9 element state vector tracking
%   the error in the device orientation estimate (as a rotation vector),
%   the error in the gyroscope bias estimate, and the error in the
%   linear acceleration estimate. 
%
%   FUSE = IMUFILTER('ReferenceFrame', RF) returns an IMUFILTER System 
%   object that fuses accelerometer and gyroscope data to estimate device 
%   orientation relative to the reference frame RF. Specify the reference 
%   frame as 'NED' (North-East-Down) or 'ENU' (East-North-Up). The default 
%   value is 'NED'.
%
%   FUSE = IMUFILTER('PropertyName', PropertyValue, ...) returns
%   an indirect Kalman sensor fusion filter, FUSE, with each specified
%   property set to a specified value.
%
%   Step method syntax:
%
%   [ORNT, AV] = step(FUSE, ACC, GYRO) fuses the accelerometer data
%   ACC and gyroscope data GYRO, to compute device orientation ORNT and
%   angular velocity AV.
%
%   [ORNT, AV, INTERDATA] = step(FUSE, ACC, GYRO) fuses the accelerometer
%   data ACC and gyroscope data GYRO to compute device orientation ORNT,
%   angular velocity AV, and intermediate data INTERDATA.
%
%   The inputs are:
%       ACC       - N-by-3 array of accelerometer readings in m/s^2
%       GYRO      - N-by-3 array of gyroscope readings in rad/s
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
%                   ResidualCovariance. Residual is a 3-element row vector
%                   in m/s^2 and ResidualCovariance is a 3-by-3 matrix.
%   where, M is computed as N/DecimationFactor.
%
%   System objects may be called directly like a function instead of
%   using the step method. For example, y = step(obj, a, g) and 
%   y = obj(a, g) are equivalent.
%
%   IMUFILTER methods:
%
%   step                - See above description for use of this method
%   release             - Allow changes to non-tunable property
%                         values and input characteristics
%   clone               - Create a IMUFILTER object with the same
%                         property values and internal states
%   isLocked            - Locked status (logical)
%   reset               - Reset the internal states to initial
%                         conditions
%   tune                - Tune filter parameters to reduce estimation error
%   residual            - Residual and residual covariance from sensor data
%
%   IMUFILTER properties:
%   
%   SampleRate                      - Input sample rate of the sensor 
%                                     data in Hz
%   DecimationFactor                - Decimation factor
%   AccelerometerNoise              - Accelerometer noise variance in
%                                     (m/s^2)^2
%   GyroscopeNoise                  - Gyroscope noise variance in
%                                     (rad/s)^2
%   GyroscopeDriftNoise             - Gyroscope bias noise variance in 
%                                     (rad/s)^2
%   LinearAccelerationNoise         - Linear acceleration noise 
%                                     variance in (m/s^2)^2
%   LinearAccelerationDecayFactor   - Linear acceleration noise decay 
%                                     factor 
%   InitialProcessNoise             - Initial process noise covariance 
%                                     matrix
%   OrientationFormat               - quaternion or rotation matrix
%
%   % EXAMPLE: Estimate orientation from recorded IMU data.
%
%   % The data in rpy_9axis.mat is recorded accelerometer, gyroscope
%   % and magnetometer sensor data from a device oscillating in pitch
%   % (around y-axis) then yaw (around z-axis) then roll (around
%   % x-axis). The device's x-axis was pointing southward when
%   % recorded. The AHRSFILTER fusion correctly estimates the
%   % orientation in the NED coordinate system. IMUFILTER fusion correctly
%   % estimates the change in orientation from an assumed north-facing 
%   % initial orientation
%
%   ld = load('rpy_9axis.mat');    
%   accel = ld.sensorData.Acceleration;
%   gyro = ld.sensorData.AngularVelocity;
%
%   Fs  = ld.Fs;  % Hz
%   decim = 2;    % Decimate by 2 to lower computational cost
%   fuse = imufilter('SampleRate', Fs, 'DecimationFactor', decim);
%
%   % Fuse accelerometer and gyroscope
%   q = fuse(accel, gyro);
%       
%   % Plot Euler angles in degrees
%   plot( eulerd( q, 'ZYX', 'frame'));
%   title('Orientation Estimate');
%   legend('Z-rotation', 'Y-rotation', 'X-rotation');
%   ylabel('Degrees');
%
%   See also AHRSFILTER, ECOMPASS, QUATERNION

%   Copyright 2017-2023 The MathWorks, Inc.

    properties (Constant, Hidden)
        SampleRateUnits = 'Hz'
        AccelerometerNoiseUnits = ['(m/s' char(178) ')' char(178)];
        GyroscopeNoiseUnits = ['(rad/s)' char(178)];
        GyroscopeDriftNoiseUnits = ['(rad/s)' char(178)];
        LinearAccelerationNoiseUnits = ['(m/s' char(178) ')' char(178)];     
    end    

    methods
        function obj = imufilter(varargin)
            setProperties(obj,nargin,varargin{:});
        end
    end 
    methods (Access = protected)
        function displayScalarObject(obj)
            displayScalarObjectWithUnits(obj);
        end
        function groups = getPropertyGroups(obj)
            list.SampleRate                         = obj.SampleRate;
            list.DecimationFactor                   = obj.DecimationFactor;
            list.AccelerometerNoise                 = obj.AccelerometerNoise;
            list.GyroscopeNoise                     = obj.GyroscopeNoise;
            list.GyroscopeDriftNoise                = obj.GyroscopeDriftNoise;
            list.LinearAccelerationNoise            = obj.LinearAccelerationNoise;
            list.LinearAccelerationDecayFactor      = obj.LinearAccelerationDecayFactor;
            list.InitialProcessNoise                = obj.InitialProcessNoise;
            list.OrientationFormat                  = obj.OrientationFormat;
            groups = matlab.mixin.util.PropertyGroup(list);
        end
    end
    methods (Hidden, Static)
        function name = matlabCodegenRedirect(~)
            name = 'fusion.internal.coder.imufiltercg';
        end
        function flag = isAllowedInSystemBlock
            flag = false;
        end
    end

    methods (Hidden, Static)
        function p = defaultProcessNoise()
            p = fusion.internal.IMUFilterBase.getInitialProcCov();
        end
    end
    
    % Methods related to autotuner (tune() function).
    % Facade for methods in fusion.internal.tuner.imufilter
    methods
        function varargout = tune(obj, varargin)
        %TUNE Tune filter parameters to reduce orientation error
        %   TUNE(FILT, SENSORDATA, GROUNDTRUTH) adjusts the properties of the
        %   imufilter, FILT, to reduce the root-mean-squared (RMS) quaternion
        %   distance error between the fused sensor data and ground truth.
        %   The function fuses the sensor readings in SENSORDATA to estimate
        %   the orientation, which is compared to the orientation in
        %   GROUNDTRUTH. The function uses the property values in FILT as the
        %   starting guess for the optimization algorithm.  The SENSORDATA
        %   input is a table with two variables, 'Accelerometer' and
        %   'Gyroscope'. Both variables are an array of N-by-3 matrices of
        %   the corresponding sensor readings. The GROUNDTRUTH input is a
        %   table with a single variable, 'Orientation', specified as an
        %   array of 3-by-3 rotation matrices or an array of quaternion
        %   objects. The TUNE function processes each row of both tables
        %   sequentially to calculate the estimated orientation error.
        %
        %   TUNE(..., CFG) adjusts the properties of the imufilter, FILT,
        %   according to CFG which is produced by the tunerconfig() function.
        %   If CFG.Cost is set to Custom then any types are allowed for
        %   SENSORDATA and GROUNDTRUTH.
        %
        %   Example : Tune filter to optimize orientation estimate
        %   
        %   % Load recorded sensor data and ground truth
        %   ld = load('imufilterTuneData.mat');
        %   qTrue = ld.groundTruth.Orientation; % true orientation
        %   fuse = imufilter;
        %   
        %   % Fuse with an untuned filter
        %   qEstUntuned = fuse(ld.sensorData.Accelerometer, ...
        %       ld.sensorData.Gyroscope);
        %   
        %   % Automatically tune the imufilter improve the orientation estimate 
        %   cfg = tunerconfig('imufilter', 'ObjectiveLimit', 0.03);
        %   tune(fuse, ld.sensorData, ld.groundTruth, cfg);
        %   % Fuse again with the tuned filter
        %   qEstTuned = fuse(ld.sensorData.Accelerometer, ...
        %       ld.sensorData.Gyroscope);
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
        %   title('imufilter - Tuned vs Untuned Error')
        %   xlabel('Time (s)');
        %   ylabel('Orientation Error (degrees)');
        %
        %   See also TUNERCONFIG

            [varargout{1:nargout}] = tune@fusion.internal.tuner.FilterTuner(obj, varargin{:}); 
        end
    end
    methods (Static, Hidden)
        function [tunerparams, staticparams]  = getParamsForAutotune
            [tunerparams, staticparams]  = fusion.internal.tuner.imufilter.getParamsForAutotune;
        end
        function [cost, stateEst] = tunerfuse(params, sensorData, groundTruth, cfg)
            [cost, stateEst] = fusion.internal.tuner.imufilter.tunerfuse(params, sensorData, groundTruth, cfg);
        end
        function measNoise = getMeasNoiseExemplar
            measNoise = fusion.internal.tuner.imufilter.getMeasNoiseExemplar;
        end
        function tf = hasMeasNoise
            tf = fusion.internal.tuner.imufilter.hasMeasNoise;
        end
    end
    methods (Access = protected)
        function sensorData = processSensorData(~, sensorData)
            sensorData = fusion.internal.tuner.imufilter.processSensorData(sensorData);
        end
        function groundTruth = processGroundTruth(~, groundTruth)
            groundTruth = fusion.internal.tuner.imufilter.processGroundTruth(groundTruth);
        end
        function varargout = makeTunerOutput(obj, info, ~)
            [varargout{1:nargout}] = fusion.internal.tuner.imufilter.makeTunerOutput(obj, info);
        end
       function crossValidateInputs(obj, sensorData, groundTruth)
           coder.internal.assert(height(groundTruth) * obj.DecimationFactor == height(sensorData), ...
               'shared_positioning:tuner:DecimFactorMismatch', 'imufilter', 'DecimationFactor');
       end
    end

    
end

