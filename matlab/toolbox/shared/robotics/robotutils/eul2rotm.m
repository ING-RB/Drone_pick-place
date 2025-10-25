function R = eul2rotm( eul, seq )
%EUL2ROTM Convert Euler angles to rotation matrix
%   R = EUL2ROTM(EUL) converts a set of 3D Euler angles, EUL, into the
%   corresponding rotation matrix, R. EUL is an N-by-3 matrix of Euler
%   rotation angles. The output, R, is an 3-by-3-by-N matrix containing N
%   rotation matrices. Rotation angles are input in radians.
%
%   R = EUL2ROTM(EUL, "SEQ") converts 3D Euler angles into a rotation
%   matrix. The Euler angles are specified by the body-fixed (intrinsic)
%   axis rotation sequence, SEQ.
%
%   The default rotation sequence is "ZYX", so EUL contains in order the
%   Z Axis Rotation, Y Axis Rotation, and X Axis Rotation. The resulting
%   rotation matrix R = Rz * Ry * Rx is a product of the individual axis
%   rotation matrices.
%
%   The following rotation sequences, SEQ, are supported: "ZYX", "ZYZ",
%   "XYZ", "ZXY", "ZXZ", "YXZ", "YXY", "YZX", "YZY", "XYX", "XZY", and
%   "XZX".
%
%   Example:
%      % Calculate the rotation matrix for a set of Euler angles
%      % By default, the ZYX axis order will be used.
%      angles = [0 pi/2 0];
%      R = eul2rotm(angles)
%
%      % Calculate the rotation matrix based on a ZYZ rotation
%      Rzyz = eul2rotm(angles, "ZYZ")
%
%   See also rotm2eul

%   Copyright 2014-2022 The MathWorks, Inc.

%#codegen

    robotics.internal.validation.validateNumericMatrix(eul, 'eul2rotm', 'eul', ...
                                                       'ncols', 3);

    if nargin == 2
        validSeq = robotics.internal.validation.validateEulerSequence(seq);
    else
        % Get default sequence
        validSeq = robotics.internal.validation.validateEulerSequence;
    end

    R = robotics.internal.eul2rotm(eul,validSeq);

end
