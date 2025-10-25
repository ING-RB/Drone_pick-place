function [eul, eulAlt] = quat2eul( q, seq )
%This method is for internal use only. It may be removed in the future.

%QUAT2EUL Convert quaternion to Euler angles
%   EUL = QUAT2EUL(QOBJ) converts a quaternion object, QOBJ, into the
%   corresponding Euler angles, EUL. Each quaternion represents
%   a 3D rotation. QOBJ is an N-element vector of quaternion objects.
%   The output, EUL, is an N-by-3 array of Euler rotation angles with each
%   row representing one Euler angle set. Rotation angles are in radians.
%
%   EUL = QUAT2EUL(Q) converts a unit quaternion rotation into the
%   corresponding Euler angles. The input, Q, is an N-by-4 matrix
%   containing N quaternions. Each quaternion represents a 3D rotation and
%   is of the form q = [w x y z], with w as the scalar number. Each element
%   of Q must be a real number.
%
%   EUL = QUAT2EUL(___, SEQ) converts unit quaternion into Euler angles.
%   The Euler angles are specified by the body-fixed (intrinsic) axis
%   rotation sequence, SEQ.
%
%   [EUL, EULALT] = QUAT2EUL(___) also returns a second output, EULALT,
%   which is a different euler representation of the same 3D rotation.
%
%   The default rotation sequence is "ZYX", so EUL contains in order the Z
%   Axis Rotation, Y Axis Rotation, and X Axis Rotation.
%
%   The following rotation sequences, SEQ, are supported: "ZYX", "ZYZ",
%   "XYZ", "ZXY", "ZXZ", "YXZ", "YXY", "YZX", "YZY", "XYX", "XZY", and
%   "XZX".
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.
%
%
%   See also quat2eul.

%   Copyright 2024 The MathWorks, Inc.

%#codegen

% Normalize the quaternions
    q = robotics.internal.normalizeRows(q);

    qw = q(:,1);
    qx = q(:,2);
    qy = q(:,3);
    qz = q(:,4);

    % Call shared quaternion -> Euler conversion code
    eul = matlabshared.rotations.internal.qparts2feul(qw,qx,qy,qz,seq);

    % Check for complex numbers
    if ~isreal(eul)
        eul = real(eul);
    end

    if nargout > 1
        eulAlt = robotics.core.internal.generateAlternateEulerAngles(eul, seq);
    end

end
