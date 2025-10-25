function q = quaternion(obj)
%QUATERNION Extract rotation as quaternion array
%   Q = QUATERNION(T) extracts the N rotations from the se3 array T and converts
%   them to a quaternion array Q. Q will have the same array size as T.
%
%   See also quaternion.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Extract rotation matrix and convert to quaternion
    R = rotm(obj);
    qr = quaternion(R, "rotmat", "point");

    % Ensure that the quaternion array has the same size as the se3 array
    q = reshape(qr, size(obj));
end
