classdef insfilterNonholonomic < fusion.internal.tuner.FilterTuner & ...
        fusion.internal.NHConstrainedIMUGPSFuserBase ...
        & fusion.internal.UnitDisplayer
%INSFILTERNONHOLONOMIC Pose estimation with nonholonomic constraints
%   FUSE = INSFILTERNONHOLONOMIC returns an object, FUSE, that estimates
%   pose in the navigation reference frame from IMU and GPS data. The
%   filter uses a 16-element state vector to track the orientation
%   quaternion, position, velocity, and IMU sensor biases. The FUSE object
%   uses an extended Kalman filter to estimate these quantities.
%
%   FUSE = INSFILTERNONHOLONOMIC('ReferenceFrame', RF) returns an inertial
%   navigation filter that estimates pose relative to the reference frame
%   RF. Specify the reference frame as 'NED' (North-East-Down) or 'ENU'
%   (East-North-Up). The default value is 'NED'.
%
%   INSFILTERNONHOLONOMIC methods:
%
%   predict        - Update states using accelerometer and gyroscope 
%                    measurements
%   residualgps    - Residuals and residual covariance from GPS
%   fusegps        - Correct states using GPS
%   residual       - Residuals and residual covariance from direct 
%                    state measurements
%   correct        - Correct states using direct state measurements
%   pose           - Current position, orientation, and velocity estimate
%   reset          - Set state and state estimation error covariance to 
%                    default values
%   stateinfo      - Display state vector information
%   tune           - Tune filter parameters to reduce error
%   copy           - Create a deep copy of the filter
%
%   INSFILTERNONHOLONOMIC properties:
%
%   IMUSampleRate                   - IMU sampling rate (Hz)
%   ReferenceLocation               - Origin of local NED reference frame
%   DecimationFactor                - Decimation factor
%   State                           - State vector
%   StateCovariance                 - State estimation error covariance
%   GyroscopeNoise                  - Noise in the gyroscope signal 
%                                     (rad/s)^2
%   AccelerometerNoise              - Noise in the accelerometer signal 
%                                     (m/s^2)^2
%   GyroscopeBiasNoise              - Gyroscope bias drift noise (rad/s)^2
%   GyroscopeBiasDecayFactor        - Gyroscope bias noise decay factor
%   AccelerometerBiasNoise          - Accelerometer bias drift noise
%                                     (m/s^2)^2
%   AccelerometerBiasDecayFactor    - Accelerometer bias noise decay factor
%   ZeroVelocityConstraintNoise     - Velocity constraints noise (m/s)^2
%
%   % EXAMPLE: Estimate the pose of a ground vehicle.
%   
%   % Load logged data of a ground vehicle following a circular trajectory.
%   % The .mat file contains IMU and GPS sensor measurements and ground 
%   % truth orientation and position.
%   load('loggedGroundVehicleCircle.mat', ...
%       'imuFs', 'localOrigin', ...
%       'initialState', 'initialStateCovariance', ...
%       'accelData', 'gyroData', ...
%       'gpsFs', 'gpsLLA', 'Rpos', 'gpsVel', 'Rvel', ...
%       'trueOrient', 'truePos');
%   
%   % Initialize filter.
%   filt = insfilterNonholonomic('IMUSampleRate', imuFs, ...
%       'ReferenceLocation', localOrigin, 'State', initialState, ...
%       'StateCovariance', initialStateCovariance);
%   
%   imuSamplesPerGPS = imuFs / gpsFs;
%   
%   % Log data for final metric computation.
%   numIMUSamples = size(accelData, 1);
%   estOrient = quaternion.ones(numIMUSamples, 1);
%   estPos = zeros(numIMUSamples, 3);
%   
%   gpsIdx = 1;
%   for idx = 1:numIMUSamples
%       % Use the predict method to estimate the filter state based on the
%       % accelData and gyroData arrays.
%       predict(filt, accelData(idx,:), gyroData(idx,:));
%       
%       if (mod(idx, imuSamplesPerGPS) == 0)
%           % Correct the filter states based on the GPS data.
%           fusegps(filt, gpsLLA(gpsIdx,:), Rpos, gpsVel(gpsIdx,:), Rvel);
%           gpsIdx = gpsIdx + 1;
%       end
%       % Log estimated pose.
%       [estPos(idx,:), estOrient(idx,:)] = pose(filt);
%   end
%   
%   % Calculate RMS errors.
%   posd = estPos - truePos;
%   quatd = rad2deg(dist(estOrient, trueOrient));
%   
%   % Display RMS errors.
%   fprintf('Position RMS Error\n');
%   msep = sqrt(mean(posd.^2));
%   fprintf('\tX: %.2f , Y: %.2f, Z: %.2f (meters)\n\n', msep(1), ...
%       msep(2), msep(3));
%   
%   fprintf('Quaternion Distance RMS Error\n');
%   fprintf('\t%.2f (degrees)\n\n', sqrt(mean(quatd.^2)));
%
%   See also INSFILTERMARG, INSFILTERASYNC, INSFILTERERRORSTATE

%   Copyright 2018-2020 The MathWorks, Inc.

%#codegen
    
    properties (Constant, Hidden)
        IMUSampleRateUnits = 'Hz';
        ReferenceLocationUnits = '[deg deg m]';
        GyroscopeNoiseUnits = ['(rad/s)', squared];
        AccelerometerNoiseUnits = ['(', acceleration, ')', squared];
        GyroscopeBiasNoiseUnits = ['(rad/s)', squared];
        AccelerometerBiasNoiseUnits = ['(', acceleration, ')', squared];
        ZeroVelocityConstraintNoiseUnits = ['(m/s)', squared];
    end
    
    methods
        function obj = insfilterNonholonomic(varargin)
            obj@fusion.internal.NHConstrainedIMUGPSFuserBase(varargin{:});
        end
        
        function cpObj = copy(obj)
        %COPY Creates a copy of the filter
        %   NEWFILT = COPY(FILT) creates a deep copy of the
        %   insfilterNonholonomic object with the same properties.
        
            s = saveObject(obj);
            cpObj = insfilterNonholonomic('ReferenceFrame', ...
                obj.ReferenceFrame);
            loadObject(cpObj, s);
        end
    end
    
    methods (Access = protected)
        function displayScalarObject(obj)
            displayScalarObjectWithUnits(obj);
        end
        
        function groups = getPropertyGroups(obj)
            % Add section titles to property display.
            if ~isscalar(obj)
                groups = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            else
                basicList.IMUSampleRate = obj.IMUSampleRate;
                basicList.ReferenceLocation = obj.ReferenceLocation;
                basicList.DecimationFactor = obj.DecimationFactor;
                
                ekfValueList.State = obj.State;
                ekfValueList.StateCovariance = obj.StateCovariance;

                processNoiseList.GyroscopeNoise = obj.GyroscopeNoise;
                processNoiseList.AccelerometerNoise = obj.AccelerometerNoise;
                processNoiseList.GyroscopeBiasNoise = obj.GyroscopeBiasNoise;
                processNoiseList.GyroscopeBiasDecayFactor = obj.GyroscopeBiasDecayFactor;
                processNoiseList.AccelerometerBiasNoise = obj.AccelerometerBiasNoise;
                processNoiseList.AccelerometerBiasDecayFactor = obj.AccelerometerBiasDecayFactor;
                
                measNoiseList.ZeroVelocityConstraintNoise = obj.ZeroVelocityConstraintNoise;
                
                basicGroup = matlab.mixin.util.PropertyGroup(basicList);
                ekfValueGroup = matlab.mixin.util.PropertyGroup( ...
                    ekfValueList, 'Extended Kalman Filter Values');
                processNoiseGroup = matlab.mixin.util.PropertyGroup( ...
                    processNoiseList, 'Process Noise Variances');
                measNoiseGroup = matlab.mixin.util.PropertyGroup( ...
                    measNoiseList, 'Measurement Noise Variances');
                
                groups = [basicGroup, ekfValueGroup, processNoiseGroup, ...
                    measNoiseGroup];
            end
        end
    end
    
    methods (Hidden, Static)
        function name = matlabCodegenRedirect(~)
            name = 'fusion.internal.coder.insfilterNonholonomicCG';
        end
    end

    % Methods related to autotuner (tune() function).
    % Facade for methods in fusion.internal.tuner.insfilterNonholonomic
    methods
        function varargout = tune(obj, varargin)
        %TUNE Tune filter parameters to reduce estimation error
        %   TN = TUNE(FILT, MEASNOISE, SENSORDATA, GROUNDTRUTH) adjusts the
        %   properties of the insfilterNonholonomic, FILT, to reduce the
        %   root-mean-squared (RMS) state estimation error between the
        %   fused sensor data and ground truth.  The function fuses the
        %   sensor readings in SENSORDATA to form a state estimate 
        %   which is compared to variables in GROUNDTRUTH. The
        %   function uses the property values in FILT and the values in the
        %   MEASNOISE struct as the starting guess for the optimization
        %   algorithm. The returned TN is a struct, with the same fields
        %   as MEASNOISE, containing optimized measurement noise values.
        %
        %   The sensorData input is a table with variables,
        %   'Accelerometer','Gyroscope', 'GPSPosition', and
        %   'GPSVelocity'.  Each variable is an array of 1-by-3 matrices of the
        %   corresponding sensor readings. Gaps in sensor data is denoted with
        %   missing.  The groundTruth input is a timetable which may contain
        %   any of the variables:
        %     Variable                  Row Elements
        %     Orientation               1-by-1 quaternions or 3-by-3
        %                                    rotation matrices
        %     Position                  1-by-3 positions, navigation frame
        %     Velocity                  1-by-3 velocities, navigation frame
        %     GyroscopeBias	        1-by-3 gyroscope biases, body 
        %                                   frame
        %     AccelerometerBias	        1-by-3 accelerometer biases, body 
        %                                   frame
        %   
        %   The tune function processes each row of both tables
        %   sequentially to calculate the state estimate and RMS error from
        %   ground truth. State variables not present in groundTruth are
        %   ignored for the comparison. The tables must have the same
        %   number of rows.
        %
        %   TN = TUNE(..., CFG) adjusts the properties of the
        %   insfilterNonholonomic, FILT, according to CFG which is produced by the
        %   tunerconfig() function.  If CFG.Cost is set to Custom then any
        %   types are allowed for SENSORDATA and GROUNDTRUTH.
        %   
        %   Example : Tune filter to optimize pose estimate
        %   
        %   % Load recorded sensor data and ground truth
        %   load('insfilterNonholonomicTuneData.mat');
        %   % Create tables for the tune function
        %   sensorData = table(Accelerometer, Gyroscope, ...
        %       GPSPosition, GPSVelocity);
        %   groundTruth = table(Orientation, Position);
        %
        %   % Automatically tune the insfilterNonholonomic to improve the pose 
        %   % estimate. 
        %   fuseTuned = insfilterNonholonomic('State', initialState, ...
        %       'StateCovariance', initialStateCovariance, ...
        %       'DecimationFactor', 1);
        %   cfg = tunerconfig('insfilterNonholonomic', 'MaxIterations', 30);
        %   
        %   % An exemplar measurement noise structure. 
        %   measNoise = tunernoise('insfilterNonholonomic');
        %   
        %   % Automatically tune the filter.
        %   tunedmn = tune(fuseTuned, measNoise, sensorData, ...
        %       groundTruth, cfg);
        %   % Fuse the sensor data with the tuned filter
        %   N = size(sensorData,1);
        %   qEstTuned = quaternion.zeros(N,1);
        %   posEstTuned = zeros(N,3);
        %   for ii=1:N
        %       predict(fuseTuned, Accelerometer(ii,:), Gyroscope(ii,:));
        %       if all(~isnan(GPSPosition(ii,1)))
        %           fusegps(fuseTuned, GPSPosition(ii,:), ...
        %               tunedmn.GPSPositionNoise, GPSVelocity(ii,:), ...
        %               tunedmn.GPSVelocityNoise);
        %       end
        %       [posEstTuned(ii,:), qEstTuned(ii,:)] = pose(fuseTuned);
        %   end
        %   
        %   % Compute error and plot
        %   orientationErrorTuned = rad2deg(dist(qEstTuned, Orientation));
        %   rmsOrientationErrorTuned = sqrt(mean(orientationErrorTuned.^2))
        %   positionErrorTuned = sqrt(sum((posEstTuned - Position).^2, 2));
        %   rmsPositionErrorTuned = sqrt(mean( positionErrorTuned.^2))
        %   
        %   figure;
        %   t = (0:N-1)./ fuseTuned.IMUSampleRate; 
        %   subplot(2,1,1)
        %   plot(t, positionErrorTuned, 'b');
        %   title("Tuned insfilterNonholonomic" + newline + ...
        %       "Euclidean Distance Position Error")
        %   xlabel('Time (s)');
        %   ylabel('Position Error (meters)')
        %   subplot(2,1,2)
        %   plot(t, orientationErrorTuned, 'b');
        %   title("Orientation Error")
        %   xlabel('Time (s)');
        %   ylabel('Orientation Error (degrees)');
        %
        %   See also TUNERCONFIG, TUNERNOISE

            [varargout{1:nargout}] = tune@fusion.internal.tuner.FilterTuner(obj, varargin{:}); 
        end
    end
    methods (Static, Hidden)
        function [tunerparams, staticparams]  = getParamsForAutotune
            [tunerparams, staticparams]  = fusion.internal.tuner.insfilterNonholonomic.getParamsForAutotune;
        end
        function [cost, stateEst] = tunerfuse(params, sensorData, groundTruth, cfg)
            [cost, stateEst] = fusion.internal.tuner.insfilterNonholonomic.tunerfuse(params, sensorData, groundTruth, cfg);
        end
        function measNoise = getMeasNoiseExemplar
            measNoise = fusion.internal.tuner.insfilterNonholonomic.getMeasNoiseExemplar;
        end
        function tf = hasMeasNoise
            tf = fusion.internal.tuner.insfilterNonholonomic.hasMeasNoise;
        end
    end
    methods (Access = protected)
        function sensorData = processSensorData(~, sensorData)
            sensorData = fusion.internal.tuner.insfilterNonholonomic.processSensorData(sensorData);
        end
        function groundTruth = processGroundTruth(~, groundTruth)
            groundTruth = fusion.internal.tuner.insfilterNonholonomic.processGroundTruth(groundTruth);
        end
        function varargout = makeTunerOutput(obj, info, measNoise)
            [varargout{1:nargout}] = fusion.internal.tuner.insfilterNonholonomic.makeTunerOutput(obj, info, measNoise);
        end
        function crossValidateInputs(~, sensorData, groundTruth) 
            fusion.internal.tuner.insfilterNonholonomic.crossValidateInputs(sensorData, groundTruth) 
        end
    end
end %classdef


function s = squared
s = char(178);
end

function s = acceleration
s = ['m/s', squared];
end
