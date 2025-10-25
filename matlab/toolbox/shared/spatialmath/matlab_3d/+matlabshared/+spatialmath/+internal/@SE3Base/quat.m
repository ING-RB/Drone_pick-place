function q = quat(obj)
%QUAT Extract quaternion rotation (numeric)
%   Q = QUAT(T) extracts the N rotations from the se3 array T and converts
%   them to an N-by-4 matrix of equivalent quaternion vectors Q.
%   Each row of Q represents a quaternion rotation and is of the form
%   [QW QX QY QZ], with QW as the scalar number.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    q = robotics.internal.tform2quat(obj.M);
end
