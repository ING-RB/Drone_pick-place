function filt = insfilter(varargin)
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

%#codegen

navFrame = fusion.internal.frames.ReferenceFrame.getDefault;
if (nargin == 1 || nargin == 3)
    inStr = validatestring(varargin{1}, ...
        {'marg','nonholonomic','asyncimu','errorstate'}, 'insfilter');
    if (nargin == 3)
        validatestring(varargin{2}, {'ReferenceFrame'}, 'insfilter');
        navFrame = validatestring(varargin{3}, ...
            fusion.internal.frames.ReferenceFrame.getOptions, ...
            '', 'ReferenceFrame');
    end
    switch inStr
        case 'marg'
            filt = insfilterMARG('ReferenceFrame', navFrame);
        case 'nonholonomic'
            filt = insfilterNonholonomic('ReferenceFrame', navFrame);
        case 'asyncimu'
            filt = insfilterAsync('ReferenceFrame', navFrame);
        case 'errorstate'
            filt = insfilterErrorState('ReferenceFrame', navFrame);
    end
else
    
    defaults = struct('Magnetometer', true, 'NonholonomicHeading', false, ...
        'AsyncIMU', false, 'ErrorState', false, ...
        'ReferenceFrame', fusion.internal.frames.ReferenceFrame.getDefault);

    params = matlabshared.fusionutils.internal.setProperties(defaults, nargin, varargin{:});
    validateattributes(params.Magnetometer, {'logical'}, {'scalar'}, ...
        '', 'Magnetometer');
    validateattributes(params.NonholonomicHeading, {'logical'}, {'scalar'}, ...
        '', 'NonholonomicHeading');
    validateattributes(params.AsyncIMU, {'logical'}, {'scalar'}, ...
        '', 'AsyncIMU');
    validateattributes(params.ErrorState, {'logical'}, {'scalar'}, ...
        '', 'ErrorState');
    navFrame = validatestring(params.ReferenceFrame, ...
        fusion.internal.frames.ReferenceFrame.getOptions, ...
        '', 'ReferenceFrame');

    NUM_FILTER_CONFIG_OPTS = 4;
    n = (NUM_FILTER_CONFIG_OPTS - 1):-1:0; 
    p = [params.AsyncIMU, params.NonholonomicHeading, ...
        params.Magnetometer, params.ErrorState];
    addr = sum(2.^n(p));

    switch addr
        case 1    % A=0, NH=0, M=0, E=1
            filt = insfilterErrorState('ReferenceFrame', navFrame);
        case 2    % A=0, NH=0, M=1, E=0
            filt = insfilterMARG('ReferenceFrame', navFrame);
        case 4    % A=0, NH=1, M=0, E=0
            filt = insfilterNonholonomic('ReferenceFrame', navFrame);
        case 10   % A=1, NH=0, M=1, E=0
            filt = insfilterAsync('ReferenceFrame', navFrame);
        otherwise % A=1, NH=1, M=1, E=1
            throwErr(params);
    end  
end

isDeprecated = ~( (nargin == 0) || ((nargin == 2) && strcmpi(varargin{1}, 'ReferenceFrame')) );

if isDeprecated
    coder.internal.warning( ...
        'shared_positioning:insfilter:CallObjectDirectly', class(filt));
end

end

function throwErr(params)
    coder.internal.error('shared_positioning:insfilter:invalidFilterConfig', ...
        string(params.Magnetometer), string(params.NonholonomicHeading), ...
        string(params.AsyncIMU), string(params.ErrorState));
end
