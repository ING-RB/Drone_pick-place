function H = eul2tform(eul, seq)
%This method is for internal use only. It may be removed in the future.

%EUL2TFORM Convert Euler angles to homogeneous transformation
%   H = EUL2TFORM(EUL, SEQ) converts 3D Euler angles to a homogeneous transformation.
%   The Euler angles are specified by the body-fixed (intrinsic) axis rotation
%   sequence, SEQ.
%
%   The following rotation sequences, SEQ, are supported: 'ZYX', 'ZYZ', and
%   'XYZ'.
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.
%
%   See also eul2tform.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

% This is a two-step process.
% 1. Convert the Euler angles into a rotation matrix
    R = robotics.internal.eul2rotm(eul,seq);

    % 2. Convert the rotation matrix into a homogeneous transform
    H = robotics.internal.rotm2tform(R);

end
