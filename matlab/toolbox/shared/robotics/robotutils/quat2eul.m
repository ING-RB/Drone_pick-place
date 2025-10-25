function [eul, eulAlt] = quat2eul( q, seq )
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
%   Example:
%      % Calculates Euler angles for a quaternion
%      % By default, the ZYX axis order will be used.
%      q = [sqrt(2)/2 0 sqrt(2)/2 0];
%      eul = quat2eul(q)
%
%      % Calculate the Euler angles for a ZYZ rotation
%      qobj = quaternion([0.7071 0.7071 0 0]);
%      eulZYZ = quat2eul(qobj, 'ZYZ')
%
%   See also eul2quat, quaternion

%   Copyright 2014-2024 The MathWorks, Inc.

%#codegen

% Validate the quaternions
    q = robotics.internal.validation.validateQuaternion(q, 'quat2eul', 'q');

    if nargin == 2
        validSeq = robotics.internal.validation.validateEulerSequence(seq);
    else
        % Get default sequence
        validSeq = robotics.internal.validation.validateEulerSequence;
    end

    if nargout == 1
        eul = robotics.internal.quat2eul(q,validSeq);
    else
        % Calculate alternative Euler angles as well, but only if user requests
        % these as a second output.
        [eul,eulAlt] = robotics.internal.quat2eul(q,validSeq);
    end
end
