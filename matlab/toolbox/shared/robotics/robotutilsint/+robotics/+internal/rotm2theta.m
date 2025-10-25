function ang = rotm2theta(R)
%This method is for internal use only. It may be removed in the future.

%ROTM2THETA Convert rotation matrix to rotation around Z axis
%   ANG = ROTM2THETA(R) converts a 2D rotation matrix to a rotation around
%   the z axis, ANG. R is a 2-by-2-by-N array of N rotations. The output
%   ANG is an N-by-1 matrix of N angles around the z-axis (in radians).
%   Each element in ANG corresponds to a rotation matrix in R.
%
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

% Preallocate output angles
    ang = zeros(size(R,3),1,"like",R);

    % Each rotation matrix is of the form
    % R = [cos(ang) -sin(ang);
    %      sin(ang)  cos(ang)]
    % Assume that the matrix is normalized, so we can simply extract the
    % angle as the atan2(R(2,1),R(2,2)). This should be equivalent to
    % atan2(-R(1,2),R(1,1)), but there is no validation for that.
    ang(:) = atan2(R(2,1,:), R(2,2,:));
end
