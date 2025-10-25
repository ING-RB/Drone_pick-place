function l = KalmanLikelihood(zres, S)
%KalmanLikelihood  Likelihood of a measurment relative to a Kalman-like filter
%
% This is an internal function and may be removed or changed
%
% l = matlabshared.tracking.internal.KalmanLikelihood(zres, S) calculates
% the likelihood of a Kalman-like filter given the measurement residual,
% zres, and the measurement noise residual, S.
% zres is an N-element vector (row or column) and S is an N-by-N matrix.
% The output is a scalar of the same class as zres.

% Copyright 2018 The MathWorks, Inc.

%#codegen

% Internal function, no validation
classToUse = class(zres);
l = zeros(1,1,classToUse);
d2 = zres(:)'/S*zres(:);
M = numel(zres);
l(1) = exp(-d2/2)/((2*pi)^(M/2))/sqrt(det(S));
l(1) = max(l(1), realmin(classToUse)); % Avoid underflow
end