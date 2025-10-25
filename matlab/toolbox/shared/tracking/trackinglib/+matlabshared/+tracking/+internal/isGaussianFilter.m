function tf = isGaussianFilter(filter)
%isGaussianFilter  Returns true if the filter is Gaussian
%
% This is an internal function and may be removed or modified.
%
%   tf = isGaussianFilter(filter) returns true if filter is Gaussian.
%   Gaussian tracking filters are filters that represent the state
%   uncertainty as a multivariate Gaussian.
%
% Example: Check that trackingKF is linear but trackingIMM is not
%   filter1 = trackingKF; 
%   filter2 = trackingIMM;
%   matlabshared.tracking.internal.isGaussianFilter(filter1)
%   matlabshared.tracking.internal.isGaussianFilter(filter2)
%
% See Also: trackingKF, trackingEKF, trackingUKF

% Copyright 2019 The MathWorks, Inc.
%#codegen

tf = isa(filter, 'matlabshared.tracking.internal.KalmanFilter') || ...
    isa(filter, 'matlabshared.tracking.internal.AbstractAlphaBetaFilter') || ...
    isa(filter, 'matlabshared.tracking.internal.ExtendedKalmanFilter') || ...
    isa(filter, 'matlabshared.tracking.internal.UnscentedKalmanFilter') || ...
    isa(filter, 'matlabshared.tracking.internal.CubatureKalmanFilter');