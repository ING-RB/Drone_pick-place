function [state, statecov] = fuse(filt, sensor, meas, mNoise)
%fuse Fuse state estimates based on sensor data
%   [STATES,STATECOV] = fuse(FILT,S,MEAS,MNOISE) fuses the filter estimates
%   based on measurement MEAS and measurement noise MNOISE for a sensor S.
%   The input S is a handle to one of the sensors used to create the
%   insEKF. The MEAS input is an N-element vector and the MNOISE input is
%   either a scalar, an N-element vector or an N-by-N matrix. A scalar or
%   N-element vector MNOISE will be expanded to a diagonal N-by-N matrix.
%
%   Refer to the sensor list below for specific sizes and syntax
%
%   <a href="matlab:help positioning.internal.insAccelerometer.funhelp">insAccelerometer</a>
%   <a href="matlab:help positioning.internal.insGyroscope.funhelp">insGyroscope</a>
%   <a href="matlab:help positioning.internal.insMagnetometer.funhelp">insMagnetometer</a>
%   <a href="matlab:help positioning.internal.insGPS.funhelp">insGPS</a>
%
%   Example: 
%       % Fuse gyroscope data.
%       acc = insAccelerometer;
%       gyro = insGyroscope;
%       filt = insEKF(acc, gyro);
%       s = fuse(filt, gyro, [0.1 0.2 -0.04], 0.1);
%
%   See also insEKF, insEKF/residual, insEKF/correct

%   Copyright 2021-2022 The MathWorks, Inc.

%#codegen 

[x, P, h, H, z, R] = parseFuseInputs(filt, sensor, meas, mNoise);

[stateUnnormalized, statecov] = positioning.internal.EKF.equationCorrect( ...
    x, P, h, H, z, R);

state = repairQuaternion(filt, stateUnnormalized);
filt.State = state;
filt.StateCovariance = statecov;
end
