function r = rank(A,tol)
%RANK   Matrix rank.
%   RANK(A) provides an estimate of the number of linearly
%   independent rows or columns of a matrix A.
%
%   RANK(A,TOL) is the number of singular values of A that are larger than
%   TOL. By default, TOL = max(size(A)) * eps(norm(A)).
%
%   Class support for input A:
%      float: double, single

%   Copyright 1984-2023 The MathWorks, Inc.

s = svd(A);

if ~isempty(s) && isnan(s(1))
    error(message('MATLAB:rank:matrixWithNaNInf'))
end

if nargin==1
    tol = matlab.internal.math.getTolToCompareSVs(s, max(size(A)));
elseif ~isnumeric(tol) || ~isreal(tol)
    error(message('MATLAB:rank:invalidSecondArgument'))
end
r = sum(s > tol);
end
