function x = pagectranspose(x)
%PAGECTRANSPOSE Page-wise complex conjugate transpose.
%   Y = PAGECTRANSPOSE(X) applies the complex conjugate transpose to each
%   page of N-D array X:
%                      Y(:,:,i) = X(:,:,i)'.
%
%   This is equivalent to calling permute(conj(X),[2 1 3:ndims(X)]).
%
%   See also CTRANSPOSE, PERMUTE, PAGETRANSPOSE.

%   Copyright 2020 The MathWorks, Inc.

if ~isobject(x) && (isnumeric(x) || islogical(x))
    x = matlab.internal.math.pagectranspose(x);
else
    x = permute(x, [2 1 3:ndims(x)]);
    if isnumeric(x)
        x = conj(x);
    end
end
