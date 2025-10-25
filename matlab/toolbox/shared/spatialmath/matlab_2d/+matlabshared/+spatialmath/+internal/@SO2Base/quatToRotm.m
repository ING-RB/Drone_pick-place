function R = quatToRotm(~,q)
%This method is for internal use only. It may be removed in the future.

%quatToRotm Convert quaternion to so2 rotation matrix
%   R = quatToRotm(OBJ, Q) converts quaternion array Q to a set of so2
%   rotation matrices. The z rotation in Q will be ignored and the rotation
%   matrix is created from the x and y rotations.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Convert to 3x3 rotation matrices
    R3d = rotmat(q, "point");

    % Extract 2x2 x-y rotation matrix
    R = R3d(1:2,1:2,:);

end
