function R = tform2rotm( H )
%TFORM2ROTM Extract rotation matrix from homogeneous transformation
%   R = TFORM2ROTM(H) extracts the rotational component from a homogeneous
%   transformation, H, and returns it as an orthonormal rotation matrix, R.
%   The translational components of H will be ignored. The input, H, is a
%   3-by-3-by-N or 4-by-4-by-N matrix of N homogeneous transformations. The
%   output, R, is a 2-by-2-by-N or 3-by-3-by-N matrix containing N rotation
%   matrices.
%
%   Example:
%      % Convert a 3D homogeneous transformation in a rotation matrix
%      H = [1 0 0 0; 0 -1 0 0; 0 0 -1 0; 0 0 0 1];
%      R = TFORM2ROTM(H)
%
%      % Convert a 2D homogeneous transformation in a rotation matrix
%      H = [1 0 0; 0 -1 0; 0 0 1];
%      R = TFORM2ROTM(H)
%
%   See also rotm2tform

%   Copyright 2014-2022 The MathWorks, Inc.

%#codegen

    if size(H,1) == 4
        robotics.internal.validation.validateHomogeneousTransform(H, 'tform2rotm', 'H');
    else
        robotics.internal.validation.validateHomogeneousTransform2D(H, 'tform2rotm', 'H');
    end

    R = robotics.internal.tform2rotm(H);

end
