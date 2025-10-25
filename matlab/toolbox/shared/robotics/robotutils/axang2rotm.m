function R = axang2rotm( axang )
%AXANG2ROTM Convert axis-angle rotation representation to rotation matrix
%   R = AXANG2ROTM(AXANG) converts a 3D rotation given in axis-angle form,
%   AXANG, to an orthonormal rotation matrix, R. AXANG is an N-by-4
%   matrix of N axis-angle rotations. The first three elements of every
%   row specify the rotation axis and the last element defines the rotation
%   angle (in radians).
%   The output, R, is an 3-by-3-by-N matrix containing N rotation matrices.
%   Each rotation matrix has a size of 3-by-3 and is orthonormal.
%
%   Example:
%      % Convert a rotation from axis-angle to rotation matrix
%      axang = [0 1 0 pi/2];
%      R = axang2rotm(axang)
%
%   See also rotm2axang

%   Copyright 2014-2022 The MathWorks, Inc.

%#codegen

    robotics.internal.validation.validateNumericMatrix(axang, 'axang2rotm', 'axang', ...
                                                       'ncols', 4);

    R = robotics.internal.axang2rotm(axang);

end
