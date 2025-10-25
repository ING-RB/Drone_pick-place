function out = logDet(S)
% This is an internal function and may be removed or modifiede in a future
% release.
%
% A function to calculate log(det(S)), when S is a positive definite
% covariance matrix without overflow. 

% Copyright 2022 The MathWorks, Inc.

%#codegen
out = log(det(S));
if ~isfinite(out)
    out = 2*sum(log(diag(matlabshared.tracking.internal.cholPSD(S))));
end

end