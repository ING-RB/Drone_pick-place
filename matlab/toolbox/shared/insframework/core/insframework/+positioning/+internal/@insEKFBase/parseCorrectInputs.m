function [x, P, h, H, z, R] = parseCorrectInputs(filt, idx, meas, mNoise)
%   This function is for internal use only. It may be removed in the future. 

%   Copyright 2021 The MathWorks, Inc.    

%#codegen 

% Validate measurement. Validate and expand input noise.
validateattributes(meas, {'double','single'}, {'vector', 'real'});
z = meas(:);
numMeas = numel(z);
R = positioning.internal.EKF.validateAndExpandNoise( ...
    mNoise, numMeas, 'measurement');

x = filt.State;
P = filt.StateCovariance;

% Validate indices.
numStates = numel(x);
validateattributes(idx, {'numeric'}, ...
    {'vector', 'positive', 'integer', ...
    '<=', numStates, 'numel', numMeas});

% Get corresponding measurement and measurement Jacobian.
h = x(idx);
I = eye(numStates, 'like', h);
H = I(idx,:);
end