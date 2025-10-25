function q = eul2quat( eul, seq )
%EUL2QUAT Convert Euler angles to quaternion
%   Q = EUL2QUAT(EUL) converts a given set of 3D Euler angles, EUL, into
%   the corresponding unit quaternion, Q. EUL is an N-by-3 matrix of Euler 
%   rotation angles.
%   The output, Q, is an N-by-4 matrix containing N quaternions. Each
%   quaternion is of the form q = [w x y z], with w as the scalar number.
%
%   Q = EUL2QUAT(EUL, SEQ) converts a set of 3D Euler angles into a unit
%   quaternion. The Euler angles are specified by the body-fixed
%   (intrinsic) axis rotation sequence, SEQ.
%
%   The default rotation sequence is "ZYX", so EUL contains in order the Z
%   Axis Rotation, Y Axis Rotation, and X Axis Rotation. The resulting
%   rotation matrix R = Rz * Ry * Rx is a product of the individual axis
%   rotation matrices.
%
%   The following rotation sequences, SEQ, are supported: "ZYX", "ZYZ",
%   "XYZ", "ZXY", "ZXZ", "YXZ", "YXY", "YZX", "YZY", "XYX", "XZY", and
%   "XZX".
%
%   Example:
%      % Calculate the quaternion for a set of Euler angles
%      % By default, the ZYX axis order will be used.
%      angles = [0 pi/2 0];
%      q = eul2quat(angles)
%
%      % Calculate the quaternion based on a ZYZ rotation
%      qzyz = eul2quat(angles, "ZYZ")
%
%   See also quat2eul.

%   Copyright 2014-2022 The MathWorks, Inc.

%#codegen

robotics.internal.validation.validateNumericMatrix(eul, 'eul2quat', 'eul', ...
    'ncols', 3);

if nargin == 2
    validSeq = robotics.internal.validation.validateEulerSequence(seq);
else
    % Get default sequence
    validSeq = robotics.internal.validation.validateEulerSequence;
end

q = robotics.internal.eul2quat(eul,validSeq);

end

