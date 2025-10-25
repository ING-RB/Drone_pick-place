function H = rotm2tform( R )
%ROTM2TFORM Convert rotation matrix to homogeneous transform
%   H = ROTM2TFORM(R) converts the rotation matrix, R, into a homogeneous
%   transformation, H. H will have no translational components. R is a
%   2-by-2-by-N or 3-by-3-by-N array containing N rotation matrices. Each
%   rotation matrix has a size of 2-by-2 (for 2D) or 3-by-3 (for 3D) and is
%   orthonormal. The output, H, is a 3-by-3-by-N or 4-by-4-by-N array of N
%   homogeneous transformations.
%
%   Example:
%      % Convert a 3D rotation matrix to a homogeneous transformation
%      R = [1 0 0; 0 -1 0; 0 0 -1]
%      H = ROTM2TFORM(R)
%
%      % Convert a 2D rotation matrix to a transformation
%      R = [0.7071 -0.7071; 0.7071 0.7071]
%      H = ROTM2TFORM(R)
%
%   See also tform2rotm

%   Copyright 2014-2022 The MathWorks, Inc.

%#codegen

% Ortho-normality is not tested, since this validation is expensive
    if size(R,1) == 3
        % 3D rotation matrix
        robotics.internal.validation.validateRotationMatrix(R, 'rotm2tform', 'R');
    else
        % 2D rotation matrix
        robotics.internal.validation.validateRotationMatrix2D(R, 'rotm2tform', 'R');
    end

    H = robotics.internal.rotm2tform(R);

end
