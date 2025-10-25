function n = numel(obj)
%NUMEL Number of elements in an array
%   N = numel(A) returns the number of elements, N, in array A, equivalent
%   to PROD(SIZE(A)).

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    n = numel(obj.MInd);

end
