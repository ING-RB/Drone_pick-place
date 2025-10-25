function H = ang2tform(ang,axis)
%This method is for internal use only. It may be removed in the future.

%ANG2TFORM Convert angle around primary axis to homogeneous transformation
%   H = ANG2TFORM(ANG,AXIS) converts a 3D rotation around the x, y, or z axis
%   to a homogeneous transformation matrix, H. ANG is an N-by-M
%   matrix of N*M angles (in radians). AXIS sets the axis of rotation.
%   AXIS can be one of "x", "y", or "z" and the axes form a
%   right-handed Cartesian coordinate system.
%
%   The output H is an 4-by-4-by-(N*M) matrix of (N*M) homogeneous
%   transformations with zero translations. Each
%   transformation matrix rotates a point around the chosen AXIS and angle,
%   ANG.
%
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

% This is a two-step process.
% 1. Convert the angle input into a rotation matrix
    R = robotics.internal.ang2rotm(ang,axis);

    % 2. Convert the rotation matrix into a homogeneous transform
    H = robotics.internal.rotm2tform(R);


end
