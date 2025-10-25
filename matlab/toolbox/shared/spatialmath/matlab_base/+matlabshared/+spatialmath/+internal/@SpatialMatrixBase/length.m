function l = length(obj)
%LENGTH Length of a vector
%   LENGTH(X) returns the length of vector X.  It is equivalent
%   to MAX(SIZE(X)) for non-empty arrays and 0 for empty ones.

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    l = length(obj.MInd);

end
