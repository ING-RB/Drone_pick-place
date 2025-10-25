function checkCovariance(name, value, dims)
%

% Copyright 2016 The MathWorks, Inc.

%#codegen
matlabshared.tracking.internal.validateDataAttributes(name, value);
matlabshared.tracking.internal.validateDataDims(name, value, dims);
matlabshared.tracking.internal.isSymmetricPositiveSemiDefinite(name, value);
end
