function [X1, X2] = calcSigmaPoints(covariance, X1, c)
% Calculates the Unscented Transformation sigma points around the state X1,
% distributed according to covariance.
%
% The set of outputs [X1 X2] are the set of sigma points.

% Notes:
% 1. Since this is an internal function, no validation is done at this
%    level. Any additional input validation should be done in a function or
%    object that use this function.
% 2. The output from the function will have the same type as the covariance
%    matrix.

%   Copyright 2016 The MathWorks, Inc.

%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>
%#ok<*MCSUP>

if isempty(coder.target)
    [sqrtP, p] = chol(covariance, 'lower');
else
    [sqrtP, p] = localLowerCholesky(covariance);
end
% Error if chol failed
coder.internal.errorIf(p>0,...
    'shared_tracking:UnscentedKalmanFilter:StateCovarianceNotPSD');

% Scale the covariance
sqrtP = sqrt(c) * sqrtP;
% Create sigma points
X2 = [sqrtP -sqrtP];
for kkC=1:size(X2,2)
    X2(:,kkC) =  X2(:,kkC) + X1;
end
end

function [A,info] = localLowerCholesky(A)
% localLowerCholesky Lower-triangular Cholesky factorization via LAPACK xpotrf
%
% [A,info] = localLowerCholesky(A)
%
% This is a substitute for [L,p]=chol(A,'lower'), but uses no variable-size
% matrices. It allows codegen with fixed matrix dimensions.
%
% A must be:
% 1) real, square
% 2) Dimensions are not 0x0
%
% Based on matlab/toolbox/eml/lib/matlab/matfun/chol.m. The differences:
% * 'lower' Cholesky assumption
% * No matrix trimming: function outputs fixed size matrices
n = cast(size(A,2),coder.internal.indexIntClass);
ZERO = zeros(coder.internal.indexIntClass);
ONE = ones(coder.internal.indexIntClass);
RZERO = zeros('like',A);
info = zeros('like',coder.internal.lapack.info_t); %#ok<PREALL>
% Factorization
[A,info] = coder.internal.lapack.xpotrf('L',n,A,ONE,n);
if info == ZERO
    jmax = n;
else
    jmax = coder.internal.indexInt(info)-1;
end
% Zero entries above the main diagonal.
for kkC = 2:jmax
    for kkR = ONE:coder.internal.indexMinus(kkC,1)
        A(kkR,kkC) = RZERO;
    end
end
end