function tr = tform2trvec( H )
%TFORM2TRVEC Extract translation vector from homogeneous transformation
%   T = TFORM2TRVEC(H) extracts the translation vector, T, from a
%   homogeneous transformation, H, and returns it. The rotational
%   components of H will be ignored. The input, H, is a 3-by-3-by-N or
%   4-by-4-by-N array of N homogeneous transformations. The output, T, is
%   an N-by-2 or N-by-3 matrix containing N translation vectors. Each
%   vector is of the form t = [x y] or t = [x y z].
%
%   Example:
%      % Extract translation vector from 3D homogeneous transformation
%      H = [1 0 0 0.5; 0 -1 0 5; 0 0 -1 -1.2; 0 0 0 1];
%      t = TFORM2TRVEC(H)
%
%      % Extract translation vector from 2D homogeneous transformation
%      H = [1 0 5; 0 1 -2; 0 0 1]
%      t = TFORM2TRVEC(H)
%
%   See also trvec2tform

%   Copyright 2014-2022 The MathWorks, Inc.

%#codegen

    if size(H,1) == 4
        % 3D matrix
        robotics.internal.validation.validateHomogeneousTransform(H, 'tform2trvec', 'H');
    else
        % 2D matrix
        robotics.internal.validation.validateHomogeneousTransform2D(H, 'tform2trvec', 'H');
    end

    tr = robotics.internal.tform2trvec(H);

end
