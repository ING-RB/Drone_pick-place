function q = eul2quat(eul, seq)
%This method is for internal use only. It may be removed in the future.

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
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.
%
%   See also eul2quat.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    seq = convertStringsToChars(seq);

    % Call shared Euler -> quaternion conversion code
    [qa,qb,qc,qd] = matlabshared.rotations.internal.feul2qparts(eul,seq);

    % Concatenate quaternion parts
    q = [qa qb qc qd];

end
