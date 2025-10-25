function q = rotm2quat(R)
%This function is for internal use only and can be removed in the future.

%ROTM2QUAT Convert orthonormal rotation matrices to a unit-quaternion.
%
%   Q = rotm2quat(R) returns a unit-quaternion of the form q = [w, x, y, z] that
%   corresponds to an orthonormal rotation matrix R. The function is internal
%   and intentionally skips validation for performance. Note that this function
%   is different from the user-facing rotm2quat in that it assumes the input
%   matrix R is orthonormal.
%
%   Examples:
%      quat = robotics.core.internal.rotm2quat(eul2rotm([0 pi, 0]));
%
%   References:
%       See
%       https://en.wikipedia.org/wiki/Rotation_formalisms_in_three_dimensions#Rotation_matrix_%E2%86%94_quaternion
%

% Copyright 2021-2024 The MathWorks, Inc.

%#codegen
    [a,b,c,d]=matlabshared.rotations.internal.frotmat2qparts(R');
    q=[a,b,c,d];
end
