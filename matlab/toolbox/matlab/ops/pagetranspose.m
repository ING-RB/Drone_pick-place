function x = pagetranspose(x)
%PAGETRANSPOSE Page-wise transpose.
%   Y = PAGETRANSPOSE(X) applies the non-conjugate transpose to each page
%   of N-D array X:
%                      Y(:,:,i) = X(:,:,i).'.
%
%   This is equivalent to calling permute(X,[2 1 3:ndims(X)]).
%
%   See also TRANSPOSE, PERMUTE, PAGECTRANSPOSE.

%   Copyright 2020 The MathWorks, Inc.

if ~isobject(x) && (isnumeric(x) || islogical(x))
    x = matlab.internal.math.pagetranspose(x);
else
    x = permute(x, [2 1 3:ndims(x)]);
end