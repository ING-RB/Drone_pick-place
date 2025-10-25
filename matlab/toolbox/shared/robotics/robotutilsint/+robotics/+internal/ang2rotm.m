function R = ang2rotm(ang, axis)
%This method is for internal use only. It may be removed in the future.

%ANG2ROTM Convert angle around primary axis to rotation matrix
%   R = ANG2ROTM(ANG,AXIS) converts a 3D rotation around the x, y, or z axis
%   to a rotation matrix, R. ANG is an N-by-M
%   matrix of N*M angles (in radians). AXIS sets the axis of rotation.
%   AXIS can be one of "x", "y", or "z" and the axes form a
%   right-handed Cartesian coordinate system.
%
%   The output R is a 3-by-3-by-(N*M) array of (N*M) rotations. Each
%   rotation matrix rotates a point around the chosen AXIS and angle, ANG.
%
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

% Preallocate output rotation matrices
    numAngles = numel(ang);
    R = repmat(eye(3,"like",ang), 1, 1, numAngles);

    cosang = cos(ang);
    sinang = sin(ang);

    switch lower(axis)
      case "x"
        found = true;
        % Rotate in the direction of y->z, counter-clockwise
        % Structure of each matrix is
        % [ 1         0          0
        %   0  cos(ang)  -sin(ang)
        %   0  sin(ang)   cos(ang)]
        R(2,2,:) = cosang(:);
        R(3,3,:) = cosang(:);
        R(3,2,:) = sinang(:);
        R(2,3,:) = -sinang(:);

      case "y"
        found = true;
        % Rotate in the direction of z->x, counter-clockwise
        % Structure of each matrix is
        % [ cos(ang)   0    sin(ang)
        %   0          1           0
        %  -sin(ang)   0    cos(ang)]
        R(1,1,:) = cosang(:);
        R(3,3,:) = cosang(:);
        R(1,3,:) = sinang(:);
        R(3,1,:) = -sinang(:);

      case "z"
        found = true;
        % Rotate in the direction of x->y, counter-clockwise
        % Structure of each matrix is
        % [ cos(ang)   -sin(ang)   0
        %   sin(ang)    cos(ang)   0
        %          0           0   1]
        R(1,1,:) = cosang(:);
        R(2,2,:) = cosang(:);
        R(2,1,:) = sinang(:);
        R(1,2,:) = -sinang(:);

      otherwise
        found = false;
        % Nothing to do here; just return identity rotation.
    end

    coder.internal.assert(found, "shared_robotics:robotutils:ang2rotm:AxisInvalid", axis);

end
