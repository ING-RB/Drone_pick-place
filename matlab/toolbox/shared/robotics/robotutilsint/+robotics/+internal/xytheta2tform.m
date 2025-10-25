function T = xytheta2tform(pose)
%This method is for internal use only. It may be removed in the future.

%XYZTHETA2TFORM Convert compact pose vector to homogeneous transformation
%   T = XYZTHETA2TFORM(POSE) creates a 3-by-3-by-N transformation array, T,
%   from the poses in the N-by-3 matrix, POSE. Each row of POSE represents
%   a 2-D pose of the form [X Y THETA]. [X Y] is the translation and
%   [THETA] is the rotation angle around the Z-axis.
%
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

    transl = pose(:,1:2);
    theta = pose(:,3);

    % Convert rotation angle to transformation matrix
    rotm = robotics.internal.theta2rotm(theta);
    T = robotics.internal.rotm2tform(rotm);

    % Assign translations
    T(1:end-1,end,:) = transl.';
end
