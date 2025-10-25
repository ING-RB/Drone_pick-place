function Z = null(A, tol)
%NULL   Null space.
%   Z = NULL(A) is an orthonormal basis for the null space of A obtained
%   from the singular value decomposition.  That is,  A*Z has negligible
%   elements, size(Z,2) is the nullity of A, and Z'*Z = I.
%
%   Z = NULL(A,TOL) treats singular values of A less than or equal to TOL
%   as zero. By default, TOL = max(size(A)) * eps(norm(A)).
%
%   Z = NULL(A,'rational') is a "rational" basis for the null space
%   obtained from the reduced row echelon form.  A*Z is zero, size(Z,2) is
%   an estimate for the nullity of A, and, if A is a small matrix with
%   integer elements, the elements of R are ratios of small integers.
%
%   The orthonormal basis is preferable numerically, while the rational
%   basis may be preferable pedagogically.
%
%   Example:
%
%       A =
%
%           1     2     3
%           1     2     3
%           1     2     3
%
%       Z = null(A);
%
%       Computing the 1-norm of the matrix A*Z will be
%       within a small tolerance
%
%       norm(A*Z,1)< 1e-12
%       ans =
%
%          1
%
%       null(A,'r') =
%
%          -2    -3
%           1     0
%           0     1
%
%   Class support for input A:
%      float: double, single
%
%   See also SVD, ORTH, RANK, RREF.

%   Copyright 1984-2024 The MathWorks, Inc.

n = size(A,2);
useRational = false;
if nargin > 1
    if ( (ischar(tol) && isrow(tol)) || (isstring(tol) && isscalar(tol)) ) ...
            && strncmpi(tol, 'rational', max(strlength(tol), 1))
        useRational = true;
    elseif ~(isscalar(tol) && isnumeric(tol) && isreal(tol))
        error(message('MATLAB:null:invalidSecondArgument'))
    end
end

if useRational
    % Rational basis
    [R,pivcol] = rref(A);
    r = numel(pivcol);
    nopiv = 1:n;
    nopiv(pivcol) = [];
    Z = zeros(n,n-r,class(A));
    if n > r
        Z(nopiv,:) = eye(n-r,n-r,class(A));
        if r > 0
            Z(pivcol,:) = -R(1:r,nopiv);
        end
    end
else
    % Orthonormal basis
    [V, s] = svd(A','vector');
    if isempty(A)
        Z = V;
    else
        if isnan(s(1))
            error(message('MATLAB:null:matrixWithNaNInf'))
        end
        if nargin == 1
            tol = matlab.internal.math.getTolToCompareSVs(s, max(size(A,1), n));
        end
        r = nnz(s > tol);
        Z = V(:,r+1:n);
    end
end
end