function axang = rotm2axang(R)
%ROTM2AXANG Convert rotation matrix to axis-angle representation
%   AXANG = ROTM2AXANG(R) converts a 3D rotation given as an orthonormal
%   rotation matrix, R, into the corresponding axis-angle representation,
%   AXANG. R is an 3-by-3-by-N matrix containing N rotation matrices. Each
%   rotation matrix has a size of 3-by-3 and is orthonormal. The output
%   AXANG is an N-by-4 matrix of N axis-angle rotations. The first three
%   elements of every row specify the rotation axis and the last element
%   defines the rotation angle (in radians).
%
%   Example:
%      % Convert a rotation matrix into the axis-angle representation 
%      R = [1 0 0 ; 0 -1 0; 0 0 -1] 
%      axang = rotm2axang(R)
%
%    See also axang2rotm

%   Copyright 2014-2022 The MathWorks, Inc.

%#codegen

% Ortho-normality is not tested, since this validation is expensive
robotics.internal.validation.validateRotationMatrix(R, 'rotm2axang', 'R');

axang = robotics.internal.rotm2axang(R);

end

