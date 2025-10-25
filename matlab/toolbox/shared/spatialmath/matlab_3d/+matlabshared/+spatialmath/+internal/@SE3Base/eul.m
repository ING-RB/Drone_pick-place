function e = eul(obj,seq)
%EUL Extract Euler or Tait-Bryan angle rotation
%   E = EUL(T) extracts the N rotations from the se3 array T and converts
%   them to an N-by-3 matrix E. Each row of E represents a set of Euler
%   angles (in radians). The angles in E are rotations about the "ZYX"
%   axes, so E contains in order the Z Axis Rotation, Y Axis Rotation, and
%   X Axis Rotation.
%
%   E = EUL(T, "SEQ") creates an N-by-3 matrix E of Euler angles. The
%   angles in E are rotations about the axes in convention SEQ. The
%   following rotation sequences, SEQ, are supported: "ZYX", "ZYZ", "XYZ",
%   "ZXY", "ZXZ", "YXZ", "YXY", "YZX", "YZY", "XYX", "XZY", and "XZX".
%
%   See also axang, quat.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    if nargin == 2
        validSeq = robotics.internal.validation.validateEulerSequence(seq);
    else
        % Get default sequence
        validSeq = robotics.internal.validation.validateEulerSequence;
    end

    e = robotics.internal.tform2eul(obj.M, validSeq);

end
