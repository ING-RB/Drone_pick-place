%INSFILTER Create inertial navigation filter
%
%   FILT = INSFILTER returns an inertial navigation filter that estimates 
%   pose based on accelerometer, gyroscope, GPS, and magnetometer 
%   measurements.
%
%   FILT = INSFILTER('ReferenceFrame', RF) returns an inertial
%   navigation filter that estimates pose relative to the reference frame
%   RF. Specify the reference frame as 'NED' (North-East-Down) or 'ENU'
%   (East-North-Up). The default value is 'NED'. 
%
%   Example : Estimate the pose of a UAV
%       
%       % Load logged sensor data and ground truth pose
%       load uavshort.mat
%     
%       % Setup the fusion filter
%       f = insfilter;
%       f.IMUSampleRate = imuFs;
%       f.ReferenceLocation = refloc;
%       f.AccelerometerBiasNoise = 2e-4;
%       f.AccelerometerNoise = 2;
%       f.GyroscopeBiasNoise = 1e-16;
%       f.GyroscopeNoise = 1e-5;
%       f.MagnetometerBiasNoise = 1e-10;
%       f.GeomagneticVectorNoise = 1e-12;
%       f.StateCovariance = 1e-9*ones(22);
%       f.State = initstate;
%     
%       gpsidx = 1;
%       N = size(accel,1);
%       p = zeros(N,3);
%       q = zeros(N,1, 'quaternion');
%     
%       % Fuse accelerometer, gyroscope, magnetometer and GPS
%       for ii=1:size(accel,1)
%           % Fuse IMU
%           f.predict(accel(ii,:), gyro(ii,:));
%     
%           % Fuse magnetometer at 1/2 the IMU rate
%           if ~mod(ii, fix(imuFs/2))
%               f.fusemag(mag(ii,:), Rmag);
%           end
%     
%           % Fuse GPS once per second
%           if ~mod(ii, imuFs)
%               f.fusegps(lla(gpsidx,:), Rpos, gpsvel(gpsidx,:), Rvel);
%               gpsidx = gpsidx  + 1;
%           end
%     
%           [p(ii,:),q(ii)] = pose(f);
%       end
%     
%       % RMS errors
%       posErr = truePos - p;
%       qErr = rad2deg(dist(trueOrient,q));
%       pRMS = sqrt(mean(posErr.^2));
%       qRMS = sqrt(mean(qErr.^2));
%       fprintf('Position RMS Error\n');
%       fprintf('\tX: %.2f , Y: %.2f, Z: %.2f (meters)\n\n', pRMS(1), ...
%           pRMS(2), pRMS(3));
%       
%       fprintf('Quaternion Distance RMS Error\n');
%       fprintf('\t%.2f (degrees)\n\n', qRMS);
%
%   See also insfilterMARG, insfilterAsync, insfilterErrorState,
%   insfilterNonholonomic

 
%   Copyright 2018-2019 The MathWorks, Inc.

