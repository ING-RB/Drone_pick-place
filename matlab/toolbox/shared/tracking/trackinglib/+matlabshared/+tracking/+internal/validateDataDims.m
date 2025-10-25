%#codegen

% Copyright 2016-2020 The MathWorks, Inc.

function validateDataDims(name, value, dims)
  isInvalidCovariance = ~isscalar(value) && any(size(value) ~= dims);
  coder.internal.errorIf(isInvalidCovariance, ...
    'shared_tracking:KalmanFilter:invalidCovarianceDims', name, dims(1), dims(2));
end
