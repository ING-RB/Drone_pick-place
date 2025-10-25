function pose = tform2xytheta(T)
%This method is for internal use only. It may be removed in the future.

%TFORM2XYTHETA Convert homogeneous transformation to compact pose representation
%   P = TFORM2XYTHETA(T) converts the 3-by-3-by-N transformation array, T,
%   to an N-by-3 matrix, P. Each row of P represents a 2-D pose of the form
%   [X Y THETA]. [X Y] is the translation and [THETA] is the rotation angle
%   around the Z-axis.
%
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

% Extract translations
    transl = robotics.internal.tform2trvec(T);

    % Extract rotations
    rotm = robotics.internal.tform2rotm(T);
    theta = robotics.internal.rotm2theta(rotm);

    pose = [transl theta];
end
