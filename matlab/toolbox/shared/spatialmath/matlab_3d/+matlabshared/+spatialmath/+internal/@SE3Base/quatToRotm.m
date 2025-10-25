function R = quatToRotm(~,q)
%This method is for internal use only. It may be removed in the future.

%quatToRotm Convert quaternion to se3 rotation matrix
%   R = quatToRotm(OBJ, Q) converts quaternion array Q to a set of se3
%   rotation matrices.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Convert to 3x3 rotation matrices
    R = rotmat(q, "point");

end
