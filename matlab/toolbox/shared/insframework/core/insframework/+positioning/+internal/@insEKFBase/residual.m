function [res, rescov] = residual(filt, sensor, meas, mNoise)
%RESIDUAL Residuals and residual covariance from sensor measurement 
%   [RES,RESCOV] = RESIDUAL(FILT,S,MEAS,MNOISE) computes the residuals,
%   RES, and residual covariance, RESCOV, based on the measurement MEAS and
%   measurement noise MNOISE associated with S. The input S is a handle to
%   one of the sensors used to create the insEKF. The MEAS input is an
%   N-element vector and the MNOISE input is either a scalar, an N-element
%   vector or an N-by-N matrix. A scalar or N-element vector MNOISE will be
%   expanded to a diagonal N-by-N matrix.
%  
%   Refer to the sensor list below for specific sizes and syntax
%
%   <a href="matlab:help positioning.internal.insAccelerometer.funhelp">insAccelerometer</a>
%   <a href="matlab:help positioning.internal.insGyroscope.funhelp">insGyroscope</a>
%   <a href="matlab:help positioning.internal.insMagnetometer.funhelp">insMagnetometer</a>
%   <a href="matlab:help positioning.internal.insGPS.funhelp">insGPS</a>
%
%   Example: 
%       % Get residuals from gyroscope measurements. 
%       gyro = insGyroscope; 
%       acc = insAccelerometer; 
%       filt = insEKF(acc,gyro); 
%       [r, rcov] = residual(filt, gyro, [0 0 5], 2);
%
%   See also insEKF, insEKF/fuse, insEKF/correct

%   Copyright 2021 The MathWorks, Inc.    

%#codegen 

% Use the same input parser as the "fuse" method since it is the same
% set of input arguments.
[~, P, h, H, z, R] = parseFuseInputs(filt, sensor, meas, mNoise);

[res, rescov] = positioning.internal.EKF.equationInnovation( ...
    P, h, H, z, R);
end
