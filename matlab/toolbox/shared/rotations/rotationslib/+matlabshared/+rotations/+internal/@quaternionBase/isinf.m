function tf = isinf(q)
%ISINF True for infinite arrays
%   ISINF(X) returns an array that contains 1's where the elements of
%   the quaternion array X have any infinite parts, and 0's where they do
%   not.

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

tf = any(isinf(compact(q)),2);
tf = reshape(tf,size(q.a));
end
