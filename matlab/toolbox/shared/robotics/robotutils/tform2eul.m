function [eul,eulAlt] = tform2eul( H, seq )
%TFORM2EUL Extract Euler angles from homogeneous transformation
%   EUL = TFORM2EUL(H) extracts the rotational component from a 3D
%   homogeneous transformation, H, and returns it as Euler angles, EUL. The
%   translational components of H will be ignored. H is an 4-by-4-by-N
%   array containing N homogeneous transformation matrices. The output EUL
%   is an N-by-3 array of Euler rotation angles. Rotation angles are in
%   radians.
%
%   EUL = TFORM2EUL(H, SEQ) calculates the Euler angles EUL for homogeneous
%   transformation H, and a specified body-fixed (intrinsic) axis rotation
%   sequence, SEQ.
%
%   [EUL, EULALT] = TFORM2EUL(___) also returns a second output, EULALT,
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
%      % Calculate the Euler angles from a transformation matrix
%      % By default, the ZYX axis order will be used.
%      H = [1 0 0 0.5; 0 -1 0 5; 0 0 -1 -1.2; 0 0 0 1];
%      eul = tform2eul(H)
%
%      % Calculate H based on a ZYZ rotation
%      eulzyz = tform2eul(H,"ZYZ")
%
%   See also eul2tform

%   Copyright 2014-2022 The MathWorks, Inc.

%#codegen

    robotics.internal.validation.validateHomogeneousTransform(H, 'tform2eul', 'H');
    if nargin == 2
        validSeq = robotics.internal.validation.validateEulerSequence(seq);
    else
        % Get default sequence
        validSeq = robotics.internal.validation.validateEulerSequence;
    end

    if nargout == 1
        eul = robotics.internal.tform2eul(H,validSeq);
    else
        % Calculate alternative Euler angles as well, but only if user requests
        % these as a second output.
        [eul,eulAlt] = robotics.internal.tform2eul(H,validSeq);
    end

end
