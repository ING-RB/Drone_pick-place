function H = quat2tform(q)
%This method is for internal use only. It may be removed in the future.

%QUAT2TFORM Convert quaternion to homogeneous transformation
%   H = QUAT2TFORM(Q) converts a unit quaternion, Q, into a homogeneous
%   transformation matrix, H. The input, Q, is an N-by-4 matrix containing N
%   quaternions. Each quaternion represents a 3D rotation and is of the form
%   q = [w x y z], with w as the scalar number. Each element
%   of Q must be a real number.
%
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.
%
%   See also quat2tform.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

% This is a two-step process.
% 1. Convert the quaternion input into a rotation matrix
    R = robotics.internal.quat2rotm(q);

    % 2. Convert the rotation matrix into a homogeneous transform
    H = robotics.internal.rotm2tform(R);

end
