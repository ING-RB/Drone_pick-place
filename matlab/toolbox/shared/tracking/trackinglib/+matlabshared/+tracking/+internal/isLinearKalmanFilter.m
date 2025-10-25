function tf = isLinearKalmanFilter(filter)
%isLinearKalmanFilter  Returns true if the filter is linear
%
% This is an internal function and may be removed or modified.
%
%   tf = isLinearKalmanFilter(filter) returns true if filter is linear.
%   Linear tracking filters are based on Kalman filter or a filter derived
%   from the Alpha-Beta filter
%
% Example: Check that trackingKF is linear but trackingEKF is not
%   filter1 = trackingKF; 
%   filter2 = trackingEKF;
%   matlabshared.tracking.internal.isLinearKalmanFilter(filter1)
%   matlabshared.tracking.internal.isLinearKalmanFilter(filter2)
%
% See Also: trackingKF, trackingEKF, trackingUKF

% Copyright 2018 The MathWorks, Inc.
%#codegen

tf = isa(filter, 'matlabshared.tracking.internal.KalmanFilter') || ...
    isa(filter, 'matlabshared.tracking.internal.AbstractAlphaBetaFilter');