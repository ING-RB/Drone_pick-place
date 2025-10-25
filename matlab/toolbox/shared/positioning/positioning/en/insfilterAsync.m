classdef insfilterAsync< fusion.internal.AsyncMARGGPSFuserBase & fusion.internal.UnitDisplayer & fusion.internal.tuner.FilterTuner
%INSFILTERASYNC Pose from MARG and GPS using asynchronous sensors 
%
%   FILT = INSFILTERASYNC implements sensor fusion of MARG and GPS data
%   to estimate pose in the navigation reference frame. MARG (magnetic,
%   angular rate, gravity) data is typically derived from magnetometer,
%   gyroscope and accelerometer data, respectively. The filter uses a
%   28-element state vector to track the orientation quaternion,
%   velocity, position, MARG sensor biases, and geomagnetic vector. The
%   INSFILTERASYNC class uses a continuous-discrete extended Kalman
%   filter to estimate these quantities.
% 
%   FILT = INSFILTERASYNC('ReferenceFrame', RF) returns an inertial
%   navigation filter that estimates pose relative to the reference
%   frame RF. Specify the reference frame as 'NED' (North-East-Down) or
%   'ENU' (East-North-Up). The default value is 'NED'.
%
%   INSFILTERASYNC Methods: 
%
%       predict          - Propagate states forward in time
%       residualaccel    - Residuals and residual covariance from
%                          accelerometer data
%       fuseaccel        - Correct states using accelerometer data
%       residualgyro     - Residuals and residual covariance from
%                          gyroscope data
%       fusegyro         - Correct states using gyroscope data
%       residualmag      - Residuals and residual covariance from
%                          magnetometer data
%       fusemag          - Correct states using magnetometer data
%       residualgps      - Residuals and residual covariance from GPS
%                          data
%       fusegps          - Correct states using GPS data
%       residual         - Residuals and residual covariance from 
%                          direct state measurements
%       correct          - Correct states with direct state 
%                          measurements
%       pose             - Current position, orientation, and velocity 
%                          estimate
%       reset            - Reinitialize internal states
%       stateinfo        - Definition of each element of State property
%                          vector
%       tune             - Tune filter parameters to reduce error
%       copy           - Create a deep copy of the filter
%   
%   INSFILTERASYNC Properties:
%
%       ReferenceLocation      - Reference location (deg, deg, meters)
%       QuaternionNoise        - Orientation quaternion process noise 
%                                variance
%       AngularVelocityNoise   - Angular velocity process noise
%                                 variance (rad/s)^2
%       PositionNoise          - Position process noise variance m^2
%       VelocityNoise          - Velocity process noise variance 
%                                (m/s)^2
%       AccelerationNoise      - Acceleration process noise variance
%                                (m/s^2)^2
%       GyroscopeBiasNoise     - Gyroscope bias process noise variance
%                                (rad/s)^2
%       AccelerometerBiasNoise - Accelerometer bias process noise 
%                                variance (m/s^2)^2
%       GeomagneticVectorNoise - Geomagnetic vector process noise 
%                                variance (uT^2)
%       MagnetometerBiasNoise  - Magnetometer bias process noise 
%                                variance (uT^2)
%       State                  - State vector of extended Kalman filter
%       StateCovariance        - State error covariance for 
%                                extended Kalman filter
%   
%   Example : Estimate the pose of a UAV
%   
%   % Load logged sensor data and ground truth pose
%   load('uavshort.mat', 'refloc', 'initstate', 'imuFs', ...
%       'accel', 'gyro', 'mag', 'lla', 'gpsvel', ...
%       'trueOrient', 'truePos')
%
%   % Set up the fusion filter
%   is = [initstate(1:4);0;0;0;initstate(5:10);0;0;0; ...
%       initstate(11:end)];
%   f = insfilterAsync('ReferenceLocation', refloc, 'State', is);
%   
%   gpsidx = 1;
%   N = size(accel,1);
%   p = zeros(N,3);
%   q = zeros(N,1, 'quaternion');
%  
%   % Sensor measurement noises from datasheets and experimentation
%   Rmag = 80;
%   Rvel = 0.0464;
%   Racc = 800;
%   Rgyro = 1e-4;
%   Rpos = 34;
%   
%   % Fuse accelerometer, gyroscope, magnetometer, and GPS
%   for ii=1:size(accel,1)
%       % Fuse IMU
%       f.predict(1./imuFs);
%   
%       f.fuseaccel(accel(ii,:), Racc);
%       f.fusegyro(gyro(ii,:), Rgyro);
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
%   See also INSFILTERMARG, INSFILTERERRORSTATE, INSFILTERNONHOLONOMIC

     
    %   Copyright 2018-2020 The MathWorks, Inc.

    methods
        function out=insfilterAsync
        end

        function out=copy(~) %#ok<STOUT>
            %COPY Creates a copy of the filter
            %   NEWFILT = COPY(FILT) creates a deep copy of the insfilterAsync
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
            %TUNE Tune filter parameters to reduce orientation error
            %   TN = TUNE(FILT, MEASNOISE, SENSORDATA, GROUNDTRUTH) adjusts the
            %   properties of the insfilterAsync, FILT, to reduce the
            %   root-mean-squared (RMS) state estimation error between the
            %   fused sensor data and ground truth.  The function fuses the
            %   sensor readings in SENSORDATA to form a state estimate 
            %   which is compared to variables in GROUNDTRUTH. The
            %   function uses the property values in FILT and the values in the
            %   MEASNOISE struct as the starting guess for the optimization
            %   algorithm. The returned TN is a struct, with the same fields
            %   as MEASNOISE, containing optimized measurement noise values.
            %
            %   The sensorData input is a timetable with variables, 'Time',
            %   'Accelerometer','Gyroscope','Magnetometer', 'GPSPosition', and
            %   'GPSVelocity'.  Each variable is an array of 1-by-3 matrices of
            %   the corresponding sensor readings. Gaps in sensor data is
            %   denoted with missing.  The groundTruth input is a timetable
            %   which may contain any of the
            %   variables:
            %     Variable			Row Elements
            %     Orientation		     1-by-1 quaternions or 3-by-3 rotation
            %                               matrices
            %     AngularVelocity		 1-by-3 angular velocities, body frame
            %     Position		         1-by-3 positions, navigation frame
            %     Velocity		         1-by-3 velocities, navigation frame
            %     Acceleration		     1-by-3 accelerations, navigation frame
            %     AccelerometerBias	     1-by-3 delta angle biases, body frame
            %     GyroscopeBias		     1-by-3 delta angle biases, body frame
            %     GeomagneticFieldVector 1-by-3 geomagnetic field vectors, 
            %                               navigation frame
            %     MagnetometerBias	     1-by-3 magnetometer biases, body frame
            %   
            %   The tune function processes each row of both tables
            %   sequentially to calculate the state estimate and RMS error from
            %   ground truth. State variables not present in groundTruth are
            %   ignored for the comparison. The tables must have the same
            %   number of rows.
            %
            %   TN = TUNE(..., CFG) adjusts the properties of the
            %   insfilterAsync, FILT, according to CFG which is produced by the
            %   tunerconfig() function.  If CFG.Cost is set to Custom then any
            %   types are allowed for SENSORDATA and GROUNDTRUTH.
            %   
            %   Example : Tune filter to optimize pose estimate
            %   
            %   % Load recorded sensor data and ground truth
            %   load('insfilterAsyncTuneData.mat');
            %   % Create timetables for the tune function
            %   sensorData = timetable(Accelerometer, Gyroscope, ...
            %       Magnetometer, GPSPosition, GPSVelocity, 'SampleRate', 100);
            %   groundTruth = timetable(Orientation, Position, ...
            %       'SampleRate', 100);
            %
            %   % Automatically tune the insfilterAsync to improve the pose 
            %   % estimate. Skip tuning some properties.
            %   fuseTuned = insfilterAsync('State', initialState, ...
            %       'StateCovariance', initialStateCovariance, ...
            %       'AccelerometerBiasNoise', 1e-7, ...
            %       'GyroscopeBiasNoise', 1e-7, ...
            %       'MagnetometerBiasNoise', 1e-7, ...
            %       'GeomagneticVectorNoise', 1e-7);
            %   cfg = tunerconfig('insfilterAsync', 'MaxIterations', 8);
            %   cfg.TunableParameters = setdiff(cfg.TunableParameters, ...
            %       {'GeomagneticFieldVector', 'AccelerometerBiasNoise', ...
            %       'GyroscopeBiasNoise', 'MagnetometerBiasNoise'});
            %   
            %   % An exemplar measurement noise structure. 
            %   measNoise = tunernoise('insfilterAsync');
            %   
            %   % Automatically tune the filter.
            %   tunedmn = tune(fuseTuned, measNoise, sensorData, ...
            %       groundTruth, cfg);
            %   % Fuse the sensor data with the tuned filter
            %   dt = seconds(diff(groundTruth.Time));
            %   N = size(sensorData,1);
            %   qEstTuned = quaternion.zeros(N,1);
            %   posEstTuned = zeros(N,3);
            %   for ii=1:N
            %       if ii ~= 1
            %           predict(fuseTuned, dt(ii-1));
            %       end
            %       if all(~isnan(Accelerometer(ii,:)))
            %           fuseaccel(fuseTuned,Accelerometer(ii,:), ...
            %               tunedmn.AccelerometerNoise);
            %       end
            %       if all(~isnan(Gyroscope(ii,:)))
            %           fusegyro(fuseTuned, Gyroscope(ii,:), ...
            %               tunedmn.GyroscopeNoise);
            %       end
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
            %   t = (0:N-1)./ groundTruth.Properties.SampleRate;
            %   subplot(2,1,1)
            %   plot(t, positionErrorTuned, 'b');
            %   title("Tuned insfilterAsync" + newline + ...
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
