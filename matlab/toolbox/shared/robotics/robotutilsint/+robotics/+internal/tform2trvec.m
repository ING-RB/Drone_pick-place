function tr = tform2trvec(H)
%This method is for internal use only. It may be removed in the future.

%TFORM2TRVEC Extract translation vector from homogeneous transformation
%   T = TFORM2TRVEC(H) extracts the translation vector, T, from a 2D or 3D
%   homogeneous transformation, H, and returns it. The rotational
%   components of H will be ignored. The input, H, is a 3-by-3-by-N or
%   4-by-4-by-N array of N homogeneous transformations. The output, T, is
%   an N-by-2 or N-by-3 matrix containing N translation vectors. Each
%   vector is of the form t = [x y] or t = [x y z].
%
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.
%
%   See also tform2trvec.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

% Also normalize by last element in matrix
    t = H(1:end-1,end,:) ./ repmat(H(end,end,:), [size(H,1)-1 1 1]);
    tr = permute(t,[3 1 2]);

end
