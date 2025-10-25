function q = quaternion(obj)
%QUATERNION Convert rotation to quaternion array
%   Q = QUATERNION(R) converts the N rotations from the so3 array R to a
%   quaternion array Q. Q will have the same array size as R.
%
%   See also quaternion.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Extract rotation matrix and convert to quaternion
    qr = quaternion(obj.M, "rotmat", "point");

    % Ensure that the quaternion array has the same size as the so3 array
    q = reshape(qr, size(obj));
end
