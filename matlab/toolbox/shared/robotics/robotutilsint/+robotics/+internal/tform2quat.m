function q = tform2quat(H)
%This method is for internal use only. It may be removed in the future.

%TFORM2QUAT Extract quaternion from homogeneous transformation
%   Q = TFORM2QUAT(H) extracts the rotational component from a 3D homogeneous
%   transformation, H, and returns it as a quaternion, Q. The translational
%   components of H will be ignored.
%   The input, H, is an 4-by-4-by-N matrix of N homogeneous transformations.
%   The output, Q, is an N-by-4 matrix containing N quaternions. Each
%   quaternion is of the form q = [w x y z], with w as the scalar number.
%
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.
%
%   See also tform2quat.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

% This is a two-step process.
% 1. Extract the rotational component from the homogeneous transform
    R = robotics.internal.tform2rotm(H);

    % 2. Convert the rotation matrix to a quaternion
    q = robotics.internal.rotm2quat(R);

end
