function q = quat(obj)
%QUAT Convert to quaternion rotation (numeric)
%   Q = QUAT(R) converts the N rotations from the so3 array R and converts
%   them to an N-by-4 matrix of equivalent quaternion vectors Q.
%   Each row of Q represents a quaternion rotation and is of the form
%   [QW QX QY QZ], with QW as the scalar number.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    q = robotics.internal.rotm2quat(obj.M);
end
