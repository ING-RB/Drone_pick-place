function H = axang2tform(axang)
%This method is for internal use only. It may be removed in the future.

%AXANG2TFORM Convert axis-angle rotation representation to homogeneous transform
%   H = AXANG2TFORM(AXANG) converts a 3D rotation given in axis-angle form,
%   AXANG, to a homogeneous transformation matrix, H. AXANG is an N-by-4
%   matrix of N axis-angle rotations. The first three elements of every
%   row specify the rotation axis and the last element defines the rotation
%   angle (in radians).
%   The output H is an 4-by-4-by-N matrix of N homogeneous transformations.
%
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.
%
%   See also axang2tform.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

% This is a two-step process.
% 1. Convert the axis-angle input into a rotation matrix
    R = robotics.internal.axang2rotm(axang);

    % 2. Convert the rotation matrix into a homogeneous transform
    H = robotics.internal.rotm2tform(R);

end
