function tf = isfinite(q)
%ISFINITE True for finite arrays
%   ISFINITE(X) returns an array  that contains 1's where the elements of
%   the quaternion array X have finite parts, and 0's where they are not.

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

tf = all(isfinite(compact(q)),2);
tf = reshape(tf,size(q.a));
end
