function [state, statecov] = correct(filt, idx, meas, mNoise)
% CORRECT Correct state estimates based on sensor data
%   [STATES,STATECOV] = CORRECT(FILT,IDX,MEAS,MNOISE)
%   corrects the filter estimates based on the measurement MEAS
%   and measurement noise MNOISE associated with IDX. The input
%   argument IDX is a vector of indices to the state vector corresponding
%   to the measurement MEAS.
%
%   Example:
%       % Update angular velocity state.
%       acc = insAccelerometer;
%       gyro = insGyroscope;
%       filt = insEKF(acc, gyro);
%       s = correct(filt, stateinfo(filt, "AngularVelocity"), ...
%           [0 0 0], 0.1);
%   
%   See also insEKF/stateinfo, insEKF/fuse, insEKF/residual

%   Copyright 2021-2022 The MathWorks, Inc.

%#codegen 

[x, P, h, H, z, R] = parseCorrectInputs(filt, idx, meas, mNoise);

[stateUnnormalized, statecov] = positioning.internal.EKF.equationCorrect( ...
    x, P, h, H, z, R);
state = repairQuaternion(filt, stateUnnormalized);
filt.State = state;
filt.StateCovariance = statecov;
end
