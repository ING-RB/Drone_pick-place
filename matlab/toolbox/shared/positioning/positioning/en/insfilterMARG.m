classdef insfilterMARG< fusion.internal.MARGGPSFuserBase & fusion.internal.UnitDisplayer & fusion.internal.tuner.FilterTuner
%INSFILTERMARG Estimate pose from MARG and GPS data 
%
%   FILT = INSFILTERMARG implements sensor fusion of MARG and GPS data
%   to estimate pose in the navigation reference frame. MARG
%   (magnetic-angular rate-gravity) data is typically derived from
%   magnetometer, gyroscope and accelerometer data, respectively. The
%   filter uses a 22-element state vector to track the orientation
%   quaternion, velocity, position, MARG sensor biases, and geomagnetic
%   vector. The insfilterMARG class uses an extended Kalman filter to
%   estimate these quantities.
%
%   FILT = INSFILTERMARG('ReferenceFrame', RF) returns an inertial
%   navigation filter that estimates pose relative to the reference
%   frame RF. Specify the reference frame as 'NED' (North-East-Down) or
%   'ENU' (East-North-Up). The default value is 'NED'.
% 
%   INSFILTERMARG Methods: 
%
%       predict        - Update states using accelerometer and 
%                        gyroscope data
%       residualmag    - Residuals and residual covariance from 
%                        magnetometer data
%       fusemag        - Correct states using magnetometer data
%       residualgps    - Residuals and residual covariance from GPS 
%                        data
%       fusegps        - Correct states using GPS data
%       residual       - Residuals and residual covariance from direct 
%                        state measurements
%       correct        - Correct states with direct state measurements
%       pose           - Current position, orientation, and velocity 
%                        estimate
%       reset          - Reinitialize internal states
%       stateinfo      - Definition of each element of State property 
%                        vector
%       tune           - Tune filter parameters to reduce error
%       copy           - Create a deep copy of the filter
%   
%   INSFILTERMARG Properties:
%
%       IMUSampleRate          - Sample rate of the IMU (Hz)
%       ReferenceLocation      - Reference location (deg, deg, meters)
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
%   Example : Estimate the pose of a UAV
%   
%   % Load logged sensor data and ground truth pose
%   load uavshort.mat
%
%   % Setup the fusion filter
%   f = insfilterMARG('IMUSampleRate', imuFs, 'ReferenceLocation', ...
%       refloc, 'AccelerometerBiasNoise', 2e-4, ...
%       'AccelerometerNoise', 2, 'GyroscopeBiasNoise', 1e-16, ...
%       'GyroscopeNoise', 1e-5, 'MagnetometerBiasNoise', 1e-10, ...
%       'GeomagneticVectorNoise', 1e-12, 'StateCovariance', ...
%       1e-9*ones(22), 'State', initstate);
%
%   gpsidx = 1;
%   N = size(accel,1);
%   p = zeros(N,3);
%   q = zeros(N,1, 'quaternion');
%
%   % Fuse accelerometer, gyroscope, magnetometer and GPS
%   for ii=1:size(accel,1)
%       % Fuse IMU
%       f.predict(accel(ii,:), gyro(ii,:));
%
%       % Fuse magnetometer at 1/2 the IMU rate
%       if ~mod(ii, fix(imuFs/2))
%           f.fusemag(mag(ii,:), Rmag);
%       end
%
%       % Fuse GPS once per second
%       if ~mod(ii, imuFs)
%           f.fusegps(lla(gpsidx,:), Rpos, gpsvel(gpsidx,:), Rvel);
%           gpsidx = gpsidx  + 1;
%       end
%
%       [p(ii,:),q(ii)] = pose(f);
%   end
%
%   % RMS errors
%   posErr = truePos - p;
%   qErr = rad2deg(dist(trueOrient,q));
%   pRMS = sqrt(mean(posErr.^2));
%   qRMS = sqrt(mean(qErr.^2));
%   fprintf('Position RMS Error\n');
%   fprintf('\tX: %.2f , Y: %.2f, Z: %.2f (meters)\n\n', pRMS(1), ...
%       pRMS(2), pRMS(3));
%   
%   fprintf('Quaternion Distance RMS Error\n');
%   fprintf('\t%.2f (degrees)\n\n', qRMS);
%
%
%   See also INSFILTERERRORSTATE, INSFILTERASYNC, INSFILTERNONHOLONOMIC

     
    %   Copyright 2018-2020 The MathWorks, Inc.

    methods
        function out=insfilterMARG
        end

        function out=copy(~) %#ok<STOUT>
            %COPY Creates a copy of the filter
            %   NEWFILT = COPY(FILT) creates a deep copy of the insfilterMARG
            %   object with the same properties.
        end

        function out=crossValidateInputs(~) %#ok<STOUT>
        end

        function out=displayScalarObject(~) %#ok<STOUT>
        end

        function out=getPropertyGroups(~) %#ok<STOUT>
            % Add section titles to property display
        end

        function out=makeTunerOutput(~) %#ok<STOUT>
        end

        function out=processGroundTruth(~) %#ok<STOUT>
        end

        function out=processSensorData(~) %#ok<STOUT>
        end

        function out=tune(~) %#ok<STOUT>
            %TUNE Tune filter parameters to reduce estimation error
            %   TN = TUNE(FILT, MEASNOISE, SENSORDATA, GROUNDTRUTH) adjusts the
            %   properties of the insfilterMARG, FILT, to reduce the
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
            %   'Accelerometer','Gyroscope','Magnetometer', 'GPSPosition', and
            %   'GPSVelocity'.  Each variable is an array of 1-by-3 matrices of the
            %   corresponding sensor readings. Gaps in sensor data is denoted with
            %   missing.  The groundTruth input is a table which may contain
            %   any of the variables:
            %     Variable                  Row Elements
            %     Orientation               1-by-1 quaternions or 3-by-3
            %                                    rotation matrices
            %     Position                  1-by-3 positions, navigation frame
            %     Velocity                  1-by-3 velocities, navigation frame
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
            %   insfilterMARG, FILT, according to CFG which is produced by the
            %   tunerconfig() function.  If CFG.Cost is set to Custom then any
            %   types are allowed for SENSORDATA and GROUNDTRUTH.
            %   
            %   Example : Tune filter to optimize pose estimate
            %   
            %   % Load recorded sensor data and ground truth
            %   load('insfilterMARGTuneData.mat');
            %   % Create tables for the tune function
            %   sensorData = table(Accelerometer, Gyroscope, ...
            %       Magnetometer, GPSPosition, GPSVelocity);
            %   groundTruth = table(Orientation, Position);
            %
            %   % Automatically tune the insfilterMARG to improve the pose 
            %   % estimate. Skip tuning some properties.
            %   fuseTuned = insfilterMARG('State', initialState, ...
            %       'StateCovariance', initialStateCovariance, ...
            %       'AccelerometerBiasNoise', 1e-7, ...
            %       'GyroscopeBiasNoise', 1e-7, ...
            %       'MagnetometerBiasNoise', 1e-7, ...
            %       'GeomagneticVectorNoise', 1e-7);
            %   cfg = tunerconfig('insfilterMARG', 'MaxIterations', 8);
            %   cfg.TunableParameters = setdiff(cfg.TunableParameters, ...
            %       {'GeomagneticFieldVector', 'AccelerometerBiasNoise', ...
            %       'GyroscopeBiasNoise', 'MagnetometerBiasNoise'});
            %   
            %   % An exemplar measurement noise structure. 
            %   measNoise = tunernoise('insfilterMARG');
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
            %       if all(~isnan(Magnetometer(ii,1)))
            %           fusemag(fuseTuned, Magnetometer(ii,:), ...
            %               tunedmn.MagnetometerNoise);
            %       end
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
            %   title("Tuned insfilterMARG" + newline + ...
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
        end

    end
end
