classdef ahrs10filter < fusion.internal.AHRS10FilterBase & ...
    fusion.internal.UnitDisplayer & fusion.internal.tuner.FilterTuner 
    %AHRS10FILTER  Height and orientation from MARG and altimeter
    %
    %   FILT = AHRS10FILTER returns a filter that estimates height and
    %   orientation based on altimeter, accelerometer, gyroscope, and
    %   magnetometer measurements. 
    %
    %   FILT = AHRS10FILTER(..., 'ReferenceFrame', RF) returns a filter
    %   that estimates height and orientation relative to the reference
    %   frame RF. Specify the reference frame as 'NED' (North-East-Down) or
    %   'ENU' (East-North-Up). The default value is 'NED'.
    %
    %   FILT = AHRS10FILTER(..., 'Name', Value, ...) returns a filter with
    %   each specified property name set to the specified value. You can
    %   specify additional name-value pair arguments in any order as
    %   (Name1,Value1,...,NameN,ValueN).
    %
    %   AHRS10FILTER implements sensor fusion of MARG and altimeter
    %   data to estimate height and orientation in the navigation reference
    %   frame. MARG (magnetic-angular rate-gravity) data is typically
    %   derived from magnetometer, gyroscope and accelerometer data,
    %   respectively. The filter uses a 18-element state vector to track
    %   the orientation quaternion, vertical velocity, vertical position,
    %   MARG sensor biases, and geomagnetic vector. The AHRS10FILTER class
    %   uses an extended Kalman filter to estimate these quantities.
    %
    %   AHRS10FILTER Methods: 
    %
    %       predict             - Update states using accelerometer and 
    %                             gyroscope
    %       residualmag         - Residuals and residual covariance from
    %                             magnetometer data
    %       fusemag             - Correct states using magnetometer data
    %       residualaltimeter   - Residuals and residual covariance from
    %                             altimeter data
    %       fusealtimeter       - Correct states using altimeter data
    %       residual            - Residuals and residual covariance from
    %                             direct state measurements
    %       correct             - Correct states with direct state 
    %                             measurements
    %       pose                - Estimated altitude and orientation 
    %       reset               - Reinitialize internal states
    %       stateinfo           - Definition of State property vector
    %       tune                - Tune filter parameters to reduce error
    %       copy                - Create a deep copy of the filter
    %   
    %   AHRS10FILTER Properties:
    %
    %       IMUSampleRate          - Sample rate of the IMU (Hz)
    %       GyroscopeNoise         - Gyroscope process noise variance
    %                                (rad/s)^2
    %       AccelerometerNoise     - Accelerometer process noise variance
    %                                (m/s^2)^2
    %       GyroscopeBiasNoise     - Gyroscope bias process noise variance
    %                                (rad/s)^2
    %       AccelerometerBiasNoise - Accelerometer bias process noise 
    %                                variance (m/s^2)^2
    %       GeomagneticVectorNoise - Geomagnetic vector process noise 
    %                                variance (uT^2)
    %       MagnetometerBiasNoise  - Magnetometer bias process noise 
    %                                variance (uT^2)
    %       State                  - State vector of extended Kalman Filter
    %       StateCovariance        - State error covariance for 
    %                                extended Kalman Filter
    %   
    %   Example : Estimate orientation and height
    %   
    %   % Load logged sensor data and ground truth pose
    %   ld = load('fuse10ex.mat');
    %   imuFs = ld.imuFs;
    %   accel = ld.accel;
    %   gyro = ld.gyro;
    %   mag = ld.mag;
    %   alt = ld.alt;
    %   imuSamplesPerAlt = fix(imuFs/ld.altFs);
    %   imuSamplesPerMag = fix(imuFs/ld.magFs);
    %
    %   % Setup the fusion filter
    %   f = ahrs10filter;
    %   f.IMUSampleRate = imuFs;
    %   f.AccelerometerNoise = 0.1;
    %   f.StateCovariance = ld.initcov;
    %   f.State = ld.initstate;
    %
    %   Ralt = 0.24;
    %   Rmag = 0.9;
    %
    %   N = size(accel,1);
    %   p = zeros(N,1);
    %   q = zeros(N,1, 'quaternion');
    %
    %   % Fuse accelerometer, gyroscope, magnetometer and altimeter
    %   for ii=1:size(accel,1)
    %       % Fuse IMU
    %       f.predict(accel(ii,:), gyro(ii,:));
    %
    %       % Fuse magnetometer
    %       if ~mod(ii, imuSamplesPerMag)
    %           f.fusemag(mag(ii,:), Rmag);
    %       end
    %
    %       % Fuse altimeter
    %       if ~mod(ii, imuSamplesPerAlt)
    %           f.fusealtimeter(alt(ii), Ralt);
    %       end
    %
    %       [p(ii),q(ii)] = pose(f);
    %   end
    %
    %   % RMS errors
    %   posErr = ld.expectedAlt - p;
    %   qErr = rad2deg(dist(ld.expectedOrient,q));
    %   pRMS = sqrt(mean(posErr.^2));
    %   qRMS = sqrt(mean(qErr.^2));
    %   fprintf('Altitude RMS Error\n');
    %   fprintf('\t%.2f (meters)\n\n', pRMS);
    %   fprintf('Quaternion Distance RMS Error\n');
    %   fprintf('\t%.2f (degrees)\n\n', qRMS);
    %
    %   See also insfilter, ahrsfilter
    
    %   Copyright 2018-2020 The MathWorks, Inc.

    %#codegen

    properties (Constant, Hidden)
        IMUSampleRateUnits          = 'Hz';
        GyroscopeNoiseUnits        = ['(rad/s)' char(178)];
        AccelerometerNoiseUnits     = ['(m/s' char(178) ')' char(178)];
        GyroscopeBiasNoiseUnits    = ['(rad/s)' char(178)];
        AccelerometerBiasNoiseUnits = ['(m/s' char(178) ')' char(178)];
        GeomagneticVectorNoiseUnits = ['uT' char(178)];
        MagnetometerBiasNoiseUnits  = ['uT' char(178)];
    end    

    methods
        function obj = ahrs10filter(varargin) 
            obj@fusion.internal.AHRS10FilterBase(varargin{:});
        end
        
        function cpObj = copy(obj)
        %COPY Creates a copy of the filter
        %   NEWFILT = COPY(FILT) creates a deep copy of the ahrs10filter
        %   object with the same properties.
        
            s = saveObject(obj);
            cpObj = ahrs10filter('ReferenceFrame', obj.ReferenceFrame);
            loadObject(cpObj, s);
        end
    end

    methods (Access = protected)

        function displayScalarObject(obj)
            displayScalarObjectWithUnits(obj);
        end
        function groups = getPropertyGroups(~)
            % Add section titles to property display
            basic = {'IMUSampleRate'};
            multprocNoise = {'GyroscopeNoise', 'AccelerometerNoise', ...
                'GyroscopeBiasNoise', 'AccelerometerBiasNoise'};

            addprocNoise = {'GeomagneticVectorNoise', ...
                'MagnetometerBiasNoise'};
            
            initVals = {'State', 'StateCovariance'};
            
            g1 = matlab.mixin.util.PropertyGroup(cat(2, basic, initVals));
            g2 = matlab.mixin.util.PropertyGroup(multprocNoise, ...
                'Multiplicative Process Noise Variances');
            g3 = matlab.mixin.util.PropertyGroup(addprocNoise, ...
                'Additive Process Noise Variances');
            groups = [g1,g2,g3];        
        end
    end
    
    methods (Access=public, Hidden, Static)
        function name = matlabCodegenRedirect(~)
            name = 'fusion.internal.coder.ahrs10filtercg';
        end
    end

    % Methods related to autotuner (tune() function).
    % Facade for methods in fusion.internal.tuner.ahrs10filter
    methods
        function varargout = tune(obj, varargin)
        %TUNE Tune filter parameters to reduce estimation error
        %   TN = TUNE(FILT, MEASNOISE, SENSORDATA, GROUNDTRUTH) adjusts the
        %   properties of the ahrs10filter, FILT, to reduce the
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
        %   'Accelerometer','Gyroscope','Magnetometer',  and
        %   'Altimeter'.  Each variable is an array of 1-by-3 matrices of the
        %   corresponding sensor readings, except 'Altimeter' which is an array
        %   of 1-by-1 matrices. Gaps in sensor data are denoted with missing.
        %   The groundTruth input is a timetable which may contain
        %   any of the variables:
        %     Variable                  Row Elements
        %     Orientation               1-by-1 quaternions or 3-by-3
        %                                    rotation matrices
        %     Altitude                  1-by-1 altitude, navigation frame
        %     VerticalVelocity          1-by-1 velocity, navigation frame
        %     DeltaAngleBias	        1-by-3 delta angle biases, body 
        %                                   frame
        %     DeltaVelocityBias	        1-by-3 delta velocity biases, body 
        %                                   frame
        %     GeomagneticFieldVector    1-by-3 geomagnetic field vectors, 
        %                                   navigation frame
        %     MagnetometerBias	        1-by-3 magnetometer biases, body 
        %                                   frame
        %   
        %   The tune function processes each row of both tables
        %   sequentially to calculate the state estimate and RMS error from
        %   ground truth. State variables not present in groundTruth are
        %   ignored for the comparison. The tables must have the same
        %   number of rows.
        %
        %   TN = TUNE(..., CFG) adjusts the properties of the
        %   ahrs10filter, FILT, according to CFG which is produced by the
        %   tunerconfig() function.  If CFG.Cost is set to Custom then any
        %   types are allowed for SENSORDATA and GROUNDTRUTH.
        %   
        %   Example : Tune filter to optimize pose estimate
        %   
        %
        %     % Load recorded sensor data and ground truth
        %     load('ahrs10filterTuneData.mat');
        %     % Create tables for the tune function
        %     sensorData = table(Accelerometer, Gyroscope, ...
        %         Magnetometer, Altimeter);
        %     groundTruth = table(Orientation, Altitude);
        %
        %     % Automatically tune the ahrs10filter to improve the pose
        %     % estimate. Skip tuning some properties.
        %     fuseTuned = ahrs10filter('State', initialState, ...
        %         'StateCovariance', initialStateCovariance);
        %     cfg = tunerconfig('ahrs10filter', 'MaxIterations', 10, ...
        %         'ObjectiveLimit', 1e-3 );
        %     measNoise = tunernoise('ahrs10filter');
        %    % Automatically tune the filter.
        %     tunedmn = tune(fuseTuned, measNoise, sensorData, ...
        %         groundTruth, cfg);
        %     % Fuse the sensor data with the tuned filter
        %     N = size(sensorData,1);
        %     qEstTuned = quaternion.zeros(N,1);
        %     altEstTuned = zeros(N,1);
        %     for ii=1:N
        %         predict(fuseTuned, Accelerometer(ii,:), Gyroscope(ii,:));
        %         if all(~isnan(Magnetometer(ii,1)))
        %             fusemag(fuseTuned, Magnetometer(ii,:), ...
        %                 tunedmn.MagnetometerNoise);
        %         end
        %         if ~isnan(Altimeter(ii))
        %             fusealtimeter(fuseTuned, Altimeter(ii), ...
        %                 tunedmn.AltimeterNoise);
        %         end
        %         [altEstTuned(ii), qEstTuned(ii)] = pose(fuseTuned);
        %     end
        %
        %     % Compute error and plot
        %     orientationErrorTuned = rad2deg(dist(qEstTuned, Orientation));
        %     rmsOrientationErrorTuned = sqrt(mean(orientationErrorTuned.^2))
        %     positionErrorTuned = altEstTuned - Altitude;
        %     rmsPositionErrorTuned = sqrt(mean( positionErrorTuned.^2))
        %
        %     figure;
        %     t = (0:N-1)./ fuseTuned.IMUSampleRate;
        %     subplot(2,1,1)
        %     plot(t, positionErrorTuned, 'b');
        %     title("Tuned ahrs10filter" + newline + ...
        %         "Altitude Error")
        %     xlabel('Time (s)');
        %     ylabel('Position Error (meters)')
        %     subplot(2,1,2)
        %     plot(t, orientationErrorTuned, 'b');
        %     title("Orientation Error")
        %     xlabel('Time (s)');
        %     ylabel('Orientation Error (degrees)');
        %
        %   See also TUNERCONFIG, TUNERNOISE

            [varargout{1:nargout}] = tune@fusion.internal.tuner.FilterTuner(obj, varargin{:}); 
        end
    end
    methods (Static, Hidden)
        function [tunerparams, staticparams]  = getParamsForAutotune
            [tunerparams, staticparams]  = fusion.internal.tuner.ahrs10filter.getParamsForAutotune;
        end
        function [cost, stateEst] = tunerfuse(params, sensorData, groundTruth, cfg)
            [cost, stateEst] = fusion.internal.tuner.ahrs10filter.tunerfuse(params, sensorData, groundTruth, cfg);
        end
        function measNoise = getMeasNoiseExemplar
            measNoise = fusion.internal.tuner.ahrs10filter.getMeasNoiseExemplar;
        end
        function tf = hasMeasNoise
            tf = fusion.internal.tuner.ahrs10filter.hasMeasNoise;
        end
    end
    methods (Access = protected)
        function sensorData = processSensorData(~, sensorData)
            sensorData = fusion.internal.tuner.ahrs10filter.processSensorData(sensorData);
        end
        function groundTruth = processGroundTruth(~, groundTruth)
            groundTruth = fusion.internal.tuner.ahrs10filter.processGroundTruth(groundTruth);
        end
        function varargout = makeTunerOutput(obj, info, measNoise)
            [varargout{1:nargout}] = fusion.internal.tuner.ahrs10filter.makeTunerOutput(obj, info, measNoise);
        end
        function crossValidateInputs(~, sensorData, groundTruth) 
            fusion.internal.tuner.ahrs10filter.crossValidateInputs(sensorData, groundTruth) 
        end
    end
end % classdef

