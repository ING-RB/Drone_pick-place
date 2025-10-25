function isSymmetricPositiveSemiDefinite(name,value)
%

%   Copyright 2016 The MathWorks, Inc.

%#codegen
    
% Use the technique similar to that in cholcov() to test symmetricity and
% positive semi-definiteness.

% Use no implicit expansion because:
% 1. This argument 'value' should always be a square matrix and should not
% require expansion.
% 2. Having no implicit expansion is more performant and the function is
% called frequently.
coder.noImplicitExpansionInFunction;
tol = 100 * eps(max(abs(diag(value))));
notSymmetric = ~all(all(abs(value - value') < sqrt(tol)));

d = eig((value + value')/2);
notPositiveSemidefinite = any(d < -tol);

coder.internal.errorIf(notPositiveSemidefinite || notSymmetric, ...
    'shared_tracking:KalmanFilter:invalidCovarianceValues', name);
end