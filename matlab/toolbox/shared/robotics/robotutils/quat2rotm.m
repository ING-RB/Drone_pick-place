function R = quat2rotm( q )
%QUAT2ROTM Convert quaternion to rotation matrix
%   R = QUAT2ROTM(QOBJ) converts a quaternion object, QOBJ, into an
%   orthonormal rotation matrix, R. Each quaternion represents a 3D
%   rotation. QOBJ is an N-element vector of quaternion objects.
%   The output, R, is an 3-by-3-by-N matrix containing N rotation matrices.
%
%   R = QUAT2ROTM(Q) normalizes the input quaternion to a unit quaternion,
%   and converts it into an orthonormal rotation matrix, R. The input, Q,
%   is an N-by-4 matrix containing N quaternions, where each quaternion
%   represents a 3D rotation and is of the form [w x y z], where w is a
%   numeric scalar, and each element of Q must be a real numeric scalar.
%
%   Example:
%      % Convert a quaternion to rotation matrix
%      q = [0.7071 0.7071 0 0];
%      R = quat2rotm(q);
%
%      % Convert a non-unit quaternion to rotation matrix
%      q = [0.5 0.5 0 0];
%      R = quat2rotm(q);
%
%      % Convert a quaternion object
%      qobj = quaternion([sqrt(2)/2 0 sqrt(2)/2 0]);
%      R = quat2rotm(qobj);
%
%   See also rotm2quat, quaternion

%   Copyright 2014-2022 The MathWorks, Inc.

%#codegen

% Validate the quaternions
    q = robotics.internal.validation.validateQuaternion(q, 'quat2rotm', 'q');

    % Convert numeric quaternion to rotation matrix
    R = robotics.internal.quat2rotm(q);

end
