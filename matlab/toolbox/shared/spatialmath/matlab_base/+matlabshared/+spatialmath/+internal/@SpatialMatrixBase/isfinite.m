function tf = isfinite(obj)
%ISFINITE True for finite arrays
%   ISFINITE(X) returns an array that contains 1's where the elements of
%   the array X have finite matrix values, and 0's where they are not.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    tf = all(isfinite(obj.M), [1 2]);
    tf = reshape(tf,size(obj.MInd));

end
