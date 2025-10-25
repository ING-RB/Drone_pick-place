function [x, P, h, H, z, R] = parseFuseInputs(filt, sensor, meas, mNoise)
%   This function is for internal use only. It may be removed in the future. 

%   Copyright 2021-2022 The MathWorks, Inc.

%#codegen 

coder.internal.assert(isa(sensor, 'positioning.INSSensorModel') && isscalar(sensor), ...
    'insframework:insEKF:ExpectedInputToBeSensor');
% Verify that the sensor was used to design the filter.
filt.getSensorIndex(sensor);

x = filt.State;
P = filt.StateCovariance;
h = sensor.measurement(filt);
H = sensor.measurementJacobian(filt);


% Validate measurement. 
validateattributes(meas, {'double','single'}, {'vector', 'real'});

% Make sure sizes are compatible and appropriate
numMeas = numel(meas);
[h, H] = validateAndTrimMeasurements(sensor, numMeas, numel(x), h, H);

% Convert measurement based on sensor
zConverted = convertMeasurement(sensor, filt, meas);
z = zConverted(:);

% Validate and expand input noise. 
R = positioning.internal.EKF.validateAndExpandNoise( ...
    mNoise, numMeas, 'measurement');

end
