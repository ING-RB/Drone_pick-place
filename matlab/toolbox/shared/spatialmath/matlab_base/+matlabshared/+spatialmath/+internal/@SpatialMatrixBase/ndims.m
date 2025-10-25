function n = ndims(obj)
%NDIMS Number of dimensions
%   N = ndims(X) returns the number of dimensions in the array X.
%   The number of dimensions in an array is always greater than
%   or equal to 2.  Trailing singleton dimensions are ignored.
%   Put simply, it is LENGTH(SIZE(X)).

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    n = ndims(obj.MInd);

end
