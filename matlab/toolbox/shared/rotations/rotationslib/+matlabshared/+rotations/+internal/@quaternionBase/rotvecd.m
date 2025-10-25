function rvd = rotvecd(q)
%ROTVECD Convert quaternion to a rotation vector in degrees
%   R = ROTVECD(Q) converts the quaternion array Q to an N-by-3 matrix
%   of equivalent rotation vectors. The rows of R are the [X Y Z]
%   angles of the rotation vectors in degrees. The ith row of R
%   corresponds to the element Q(i). The array Q can be of
%   arbitrary dimensions. The elements of Q are normalized prior to conversion.

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

rvd = rad2deg(rotvec(q));
end
