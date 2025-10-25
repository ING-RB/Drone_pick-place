function tf = isinf(obj)
%ISINF True for infinite arrays
%   ISINF(X) returns an array that contains 1's where the elements of
%   the array X have any infinite matrix values, and 0's where they do
%   not.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    tf = any(isinf(obj.M), [1 2]);
    tf = reshape(tf,size(obj.MInd));

end
