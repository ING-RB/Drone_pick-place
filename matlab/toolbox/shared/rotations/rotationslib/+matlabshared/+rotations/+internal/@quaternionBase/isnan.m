function tf = isnan(q)
%ISNAN  True for Not-a-Number in a quaternion part
%   isnan(X) returns an array that contains 1's where
%   the elements of quaternion X have NaN's in any part
%   and 0's where they do not.

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

tf = isnan(q.a) | isnan(q.b) | isnan(q.c) | isnan(q.d);
end
