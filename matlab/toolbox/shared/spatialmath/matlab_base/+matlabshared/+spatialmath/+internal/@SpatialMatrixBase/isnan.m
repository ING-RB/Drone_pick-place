function tf = isnan(obj)
%ISNAN  True for Not-a-Number in a matrix value
%   isnan(X) returns an array that contains 1's where
%   the matrices in X have NaN's in any part
%   and 0's where they do not.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    tf = any(isnan(obj.M), [1 2]);
    tf = reshape(tf,size(obj.MInd));

end
