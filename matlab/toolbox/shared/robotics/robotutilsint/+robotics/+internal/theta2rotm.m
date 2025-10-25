function R = theta2rotm(ang)
%This method is for internal use only. It may be removed in the future.

%THETA2ROTM Convert angle around Z axis to rotation matrix
%   R = THETA2ROTM(ANG) converts a 2D rotation around the z axis
%   to a rotation matrix, R. ANG is an N-by-M
%   matrix of N*M angles (in radians).
%
%   The output R is a 2-by-2-by-(N*M) array of (N*M) rotations. Each
%   rotation matrix rotates a point around the z axis and angle, ANG.
%
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

% Preallocate output rotation matrices
    numAngles = numel(ang);
    R = repmat(eye(2,"like",ang), 1, 1, numAngles);

    cosang = cos(ang);
    sinang = sin(ang);

    R(1,1,:) = cosang(:);
    R(2,2,:) = cosang(:);
    R(2,1,:) = sinang(:);
    R(1,2,:) = -sinang(:);
end
