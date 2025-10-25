function H = quat2tform( q )
%QUAT2TFORM Convert quaternion to homogeneous transformation
%   H = QUAT2TFORM(QOBJ) converts a quaternion object, QOBJ, into a
%   homogeneous transformation matrix, H. Each quaternion represents a 3D
%   rotation. QOBJ is an N-element vector of quaternion objects. The
%   output, H, is an 4-by-4-by-N matrix of N homogeneous transformations.
%
%   H = QUAT2TFORM(Q) converts a unit quaternion, Q, into a homogeneous
%   transformation matrix, H. The input, Q, is an N-by-4 matrix containing
%   N quaternions. Each quaternion represents a 3D rotation and is of the
%   form q = [w x y z], with w as the scalar number. Each element of Q must
%   be a real number.
%
%   Example:
%      % Convert a quaternion to homogeneous transform
%      q = [0.7071 0.7071 0 0];
%      H = quat2tform(q)
%
%      % Convert a quaternion object
%      qobj = quaternion([0 1 0 0]);
%      H = quat2tform(qobj);
%
%   See also tform2quat, quaternion

%   Copyright 2014-2022 The MathWorks, Inc.

%#codegen

    q = robotics.internal.validation.validateQuaternion(q, 'quat2tform', 'q');
    H = robotics.internal.quat2tform(q);

end
