function axang = tform2axang( H )
%This method is for internal use only. It may be removed in the future.

%TFORM2AXANG Extract axis-angle rotation from homogeneous transformation
%   AXANG = TFORM2AXANG(H) retrieves the rotational component of the
%   3D homogeneous transformation, H, and returns it in an axis-angle
%   representation, AXANG. The translational components of H
%   will be ignored.
%   The input, H, is an 4-by-4-by-N matrix of N homogeneous transformations.
%   The output, AXANG, is an N-by-4 matrix of N axis-angle rotations.
%   The first three element of every row specify the rotation axis and
%   the last element defines the rotation angle (in radians).
%
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.
%
%   See also tform2axang.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

% This is a two-step process.
% 1. Extract the rotation matrix from the homogeneous transform
    R = robotics.internal.tform2rotm(H);

    % 2. Convert the rotation matrix into the axis-angle representation
    axang = robotics.internal.rotm2axang(R);

end
