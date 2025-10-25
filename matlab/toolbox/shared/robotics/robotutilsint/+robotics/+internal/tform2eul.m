function [eul,eulAlt] = tform2eul(H,seq)
%This method is for internal use only. It may be removed in the future.

%TFORM2EUL Extract Euler angles from homogeneous transformation
%   EUL = TFORM2EUL(H) extracts the rotational component from a 3D homogeneous
%   transformation, H, and returns it as Euler angles, EUL. The translational
%   components of H will be ignored.
%   H is an 4-by-4-by-N array containing N homogeneous transformation
%   matrices. The output EUL is an N-by-3 array of Euler rotation angles.
%   Rotation angles are in radians.
%
%   EUL = TFORM2EUL(H, SEQ) calculates the Euler angles EUL for homogeneous
%   transformation H, and a specified body-fixed (intrinsic) axis rotation
%   sequence, SEQ.
%
%   [EUL, EULALT] = TFORM2EUL(___) also returns a second output, EULALT, that
%   is a different set of euler angles that represents the same rotation.
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
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.
%
%   See also tform2eul.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen


% This is a two-step process.
% 1. Extract the rotation matrix from the homogeneous transform
    R = robotics.internal.tform2rotm(H);

    % 2. Convert the rotation matrix to a set of euler angles
    eul = robotics.internal.rotm2eul(R, seq);

    if nargout > 1
        eulAlt = robotics.core.internal.generateAlternateEulerAngles(eul, seq);
    end

end
