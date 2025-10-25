function H = eul2tform( eul, seq )
%EUL2TFORM Convert Euler angles to homogeneous transformation
%   H = EUL2TFORM(EUL) converts a set of 3D Euler angles, EUL, into a
%   homogeneous transformation matrix, H. EUL is an N-by-3 matrix of Euler
%   rotation angles. The output H is an 4-by-4-by-N matrix of N homogeneous
%   transformations.
%
%   H = EUL2TFORM(EUL, SEQ) converts 3D Euler angles to a homogeneous
%   transformation. The Euler angles are specified by the body-fixed
%   (intrinsic) axis rotation sequence, SEQ.
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
%      % Calculate the transformation matrix for a set of Euler angles
%      % By default, the ZYX axis order will be used.
%      angles = [0 pi/2 0];
%      H = eul2tform(angles)
%
%      % Calculate H based on a ZYZ rotation
%      Hzyz = eul2tform(angles, 'ZYZ')
%
%   See also tform2eul

%   Copyright 2014-2023 The MathWorks, Inc.

%#codegen

    robotics.internal.validation.validateNumericMatrix(eul, 'eul2tform', 'eul', ...
                                                       'ncols', 3);
    if nargin == 2
        validSeq = robotics.internal.validation.validateEulerSequence(seq);
    else
        % Get default sequence
        validSeq = robotics.internal.validation.validateEulerSequence;
    end

    H = robotics.internal.eul2tform(eul,validSeq);

end
