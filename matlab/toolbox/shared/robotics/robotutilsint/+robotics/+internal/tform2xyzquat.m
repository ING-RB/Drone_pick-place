function pose = tform2xyzquat(T)
%This method is for internal use only. It may be removed in the future.

%TFORM2XYZQUAT Convert homogeneous transformation to compact pose representation
%   P = TFORM2XYZQUAT(T) converts the 4-by-4-by-N transformation array, T,
%   to an N-by-7 matrix, P. Each row of P represents a 3-D pose of the form
%   [X Y Z QW QX QY QZ]. [X Y Z] is the translation and [QW QX QY QZ] is
%   the quaternion rotation.
%
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

% Extract translations and rotations
    transl = robotics.internal.tform2trvec(T);
    quat = robotics.internal.tform2quat(T);

    pose = [transl quat];

end
