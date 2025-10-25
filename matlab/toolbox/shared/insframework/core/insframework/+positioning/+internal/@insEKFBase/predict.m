function [state, statecov] = predict(filt, dt, varargin)
% PREDICT Advance state estimates forward in time
%   [S,SC] = PREDICT(FILT, DT) predicts the state estimates forward in time
%   by DT seconds based on the motion model of the filter FILT. The
%   function returns the new states S and the new state covariance SC.
%
%   [S, SC] = PREDICT(..., VARARGIN) predicts the state estimates forward
%   DT seconds using the motion model. VARARGIN is passed to the motion
%   model's and sensors' stateTransition and stateTransitionJacobian
%   functions. The VARARGIN input can be used to simulate control or drive
%   inputs such as a throttle.
%
%   Example:
%   f = insEKF;
%   s = predict(f, 0.1); % step forward 100 ms and return state
%
%   See also: insEKF, insEKF/fuse

%   Copyright 2021-2022 The MathWorks, Inc.

%#codegen 

validateattributes(dt, {'double', 'single'}, ...
    {'scalar', 'real', 'nonnan', 'finite'}, ...
    'predict', 'dt', 2);

xk = filt.State;

% Compute the state derivative and Jacobian.
[xdot, dfdx] = filt.computeStateDerivative(dt, varargin{:});

addProcNoise = filt.AdditiveProcessNoise;
P = filt.StateCovariance;

% Continuous-Discrete EKF predict phase
Pdot = filt.predictCovarianceDerivative(P, dfdx, addProcNoise);

% Euler integration
stateUnnormalized = filt.eulerIntegrate(xk, xdot, dt);
statecov = filt.eulerIntegrate(P, Pdot, dt);

filt.StateCovariance = statecov;
state = repairQuaternion(filt, stateUnnormalized);
filt.State = state;

end

