function H = xyzquat2tform(pose)
%This method is for internal use only. It may be removed in the future.

%XYZQUAT2TFORM Convert compact pose vector to homogeneous transformation
%   H = XYZQUAT2TFORM(POSE) creates a 4-by-4-by-N transformation array, H, from
%   the poses in the N-by-7 matrix, POSE. Each row of POSE represents
%   a 3-D pose of the form [X Y Z QW QX QY QZ]. [X Y Z] is the translation
%   and [QW QX QY QZ] is the quaternion rotation.
%
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

    transl = pose(:,1:3);
    quat = pose(:,4:7);

    % Convert quaternion to transformation matrix
    H = robotics.internal.quat2tform(quat);

    % Assign translations
    H(1:end-1,end,:) = transl.';

end
