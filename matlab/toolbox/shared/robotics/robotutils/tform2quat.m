function q = tform2quat( H )
%TFORM2QUAT Extract quaternion from homogeneous transformation
%   Q = TFORM2QUAT(H) extracts the rotational component from a 3D
%   homogeneous transformation, H, and returns it as a quaternion, Q. The
%   translational components of H will be ignored. The input, H, is an
%   4-by-4-by-N matrix of N homogeneous transformations. The output, Q, is
%   an N-by-4 matrix containing N quaternions. Each quaternion is of the
%   form q = [w x y z], with w as the scalar number.
%
%   Example:
%      % Convert a homogeneous transformation in a quaternion
%      H = [1 0 0 0; 0 -1 0 0; 0 0 -1 0; 0 0 0 1];
%      q = tform2quat(H)
%
%   See also quat2tform

%   Copyright 2014-2022 The MathWorks, Inc.

%#codegen

    robotics.internal.validation.validateHomogeneousTransform(H, 'tform2quat', 'H');
    q = robotics.internal.tform2quat(H);

end
