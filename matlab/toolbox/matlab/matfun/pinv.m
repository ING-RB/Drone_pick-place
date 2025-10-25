function X = pinv(A,tol)
%PINV   Pseudoinverse.
%   X = PINV(A) produces a matrix X of the same dimensions
%   as A' so that A*X*A = A, X*A*X = X and A*X and X*A
%   are Hermitian. The computation is based on SVD(A) and any
%   singular values less than or equal to a tolerance are treated as zero.
%
%   PINV(A,TOL) treats all singular values of A that are less than or equal
%   to TOL as zero. By default, TOL = max(size(A)) * eps(norm(A)).
%
%   Class support for input A:
%      float: double, single
%
%   See also SVD, RANK, PAGEPINV.

%   Copyright 1984-2024 The MathWorks, Inc.

if ~ismatrix(A)
    error(message('MATLAB:pinv:inputMustBe2D'))
end

[U, s, V] = svd(A, 'econ', 'vector');

if ~isempty(s) && isnan(s(1))
    X = nan(size(A, 2), size(A, 1), "like", A);
    return
end

if nargin < 2
    tol = matlab.internal.math.getTolToCompareSVs(s, max(size(A)));
elseif ~isnumeric(tol) || ~isreal(tol) || ~isscalar(tol)
    error(message('MATLAB:pinv:invalidSecondArgument'))
end

r = nnz(s > tol);
V = matlab.internal.math.viewColumns(V, r);
U = matlab.internal.math.viewColumns(U, r);
s = matlab.internal.math.viewColumns(s.', r);

X = (V./s)*U';
end
