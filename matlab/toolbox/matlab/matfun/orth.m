function Q = orth(A, tol)
%ORTH   Orthogonalization.
%   Q = ORTH(A) is an orthonormal basis for the range of A.
%   That is, Q'*Q = I, the columns of Q span the same space as 
%   the columns of A, and the number of columns of Q is the 
%   rank of A.
%
%   Q = ORTH(A,TOL) treats singular values of A less than or equal to TOL
%   as zero. By default, TOL = max(size(A)) * eps(norm(A)).
%
%   Class support for input A:
%      float: double, single
%
%   See also SVD, RANK, NULL.

%   Copyright 1984-2023 The MathWorks, Inc.


[Q,s] = svd(A,'econ','vector');

if ~isempty(s) && isnan(s(1))
    error(message('MATLAB:orth:matrixWithNaNInf'))
end

if nargin == 1
    tol = matlab.internal.math.getTolToCompareSVs(s, max(size(A)));
else
    if ~(isscalar(tol) && isnumeric(tol) && isreal(tol))
        error(message('MATLAB:orth:invalidSecondArgument'))
    end
end

r = nnz(s > tol);
Q(:, r+1:end) = [];
end
