function H = trvec2tform( t )
%TRVEC2TFORM Convert translation vector to homogeneous transformation
%   H = TRVEC2TFORM(T) converts the Cartesian representation of a
%   translation vector, T, into the corresponding homogeneous
%   transformation, H. The input, T, is an N-by-2 or N-by-3 matrix
%   containing N translation vectors. Each vector is of the form t = [x y]
%   or t = [x y z]. The output, H, is a 3-by-3-by-N or 4-by-4-by-N array of
%   N homogeneous transformations.
%
%   Example:
%      % Create homogeneous transformation from 3D translation vector
%      t = [0.5 6 100];
%      H = TRVEC2TFORM(t)
%
%      % Create homogeneous transformation from 2D translation vectors
%      t = [0.5 6; -1 3];
%      H = TRVEC2TFORM(t)
%
%   See also tform2trvec

%   Copyright 2014-2022 The MathWorks, Inc.

%#codegen

    if size(t,2) == 3
        robotics.internal.validation.validateNumericMatrix(t, 'trvec2tform', 't');
    else
        robotics.internal.validation.validateNumericMatrix(t, 'trvec2tform', 't', ...
                                                           'ncols', 2);
    end

    H = robotics.internal.trvec2tform(t);

end
