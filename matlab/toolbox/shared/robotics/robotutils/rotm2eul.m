function [eul, eulAlt] = rotm2eul( R, seq )
%ROTM2EUL Convert rotation matrix to Euler angles
%   EUL = ROTM2EUL(R) converts a 3D rotation matrix, R, into the
%   corresponding Euler angles, EUL. R is an 3-by-3-by-N matrix containing
%   N rotation matrices. The output, EUL, is an N-by-3 matrix of Euler
%   rotation angles. Rotation angles are in radians.
%
%   EUL = ROTM2EUL(R, SEQ) converts a rotation matrix into Euler angles.
%   The Euler angles are specified by the body-fixed (intrinsic) axis
%   rotation sequence, SEQ.
%
%   [EUL, EULALT] = ROTM2EUL(___) also returns a second output, EULALT,
%   that is a different set of euler angles that represents the same
%   rotation.
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
%      % Calculates Euler angles for a rotation matrix
%      % By default, the ZYX axis order will be used.
%      R = [0 0 1; 0 1 0; -1 0 0];
%      eul = rotm2eul(R)
%
%      % Calculate the Euler angles for a ZYZ rotation
%      eulZYZ = rotm2eul(R,"ZYZ")
%
%   See also eul2rotm

%   Copyright 2014-2022 The MathWorks, Inc.

%#codegen

    robotics.internal.validation.validateRotationMatrix(R, 'rotm2eul', 'R');
    if nargin == 2
        validSeq = robotics.internal.validation.validateEulerSequence(seq);
    else
        % Get default sequence
        validSeq = robotics.internal.validation.validateEulerSequence;
    end

    if nargout == 1
        eul = robotics.internal.rotm2eul(R,validSeq);
    else
        % Calculate alternative Euler angles as well, but only if user requests
        % these as a second output.
        [eul,eulAlt] = robotics.internal.rotm2eul(R,validSeq);
    end

end
