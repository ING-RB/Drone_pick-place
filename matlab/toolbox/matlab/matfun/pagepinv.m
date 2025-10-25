function X = pagepinv(A, tol)
%PAGEPINV   Page-wise Pseudoinverse.
%   X = PAGEPINV(A) computes the pseudoinverse of each page of the N-D
%   array A:
%           X(:,:,i) = pinv(A(:,:,i))
%
%   The computation is based on PAGESVD(A) and any singular values less
%   than or equal to a tolerance are treated as zero.
%
%   If A has more than 3 dimensions, then PAGEPINV returns an N-D array
%   that contains the same dimensions as A:
%             X(:,:,i,j,k) = pinv(A(:,:,i,j,k))
%
%   X = PAGEPINV(A,TOL) treats all singular values of the pages of A that
%   are less than or equal to TOL as zero. TOL can either be a scalar or an
%   array with size [1 1 size(A, 3:ndims(A))]. By default,
%           TOL = max(size(A, [1 2])) * eps(pagenorm(A)).
%
%   See also PINV, PAGESVD, RANK.

%   Copyright 2023-2024 The MathWorks, Inc.

[U, s, V] = pagesvd(A, 'econ', 'vector');

if nargin < 2
    tol = matlab.internal.math.getTolToCompareSVs(s, max(size(A, [1 2])));
else
    if ~isnumeric(tol) || ~isreal(tol)
        error(message('MATLAB:pagepinv:invalidSecondArgumentClass'))
    elseif ~isscalar(tol)
        tolSize = [1 1 size(A, 3:ndims(A))];
        if ~isequal(size(tol), tolSize)
            str = "[1 1";
            for i=3:numel(tolSize)
                str = str + " " + string(tolSize(i));
            end
            str = str + "]";
            error(message("MATLAB:pagepinv:invalidSecondArgumentSize", str))
        end
    end
end

% Get index for singular values that will be treated as zero
idx = ~(s > tol);
t = pagetranspose(1./s);
if any(idx, 'all')
    t(idx) = 0;
end
X = pagemtimes(V.*t, 'none', U, 'ctranspose');
end
