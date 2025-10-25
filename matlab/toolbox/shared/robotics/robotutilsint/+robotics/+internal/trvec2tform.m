function H = trvec2tform(t)
%This method is for internal use only. It may be removed in the future.

%TRVEC2TFORM Convert translation vector to homogeneous transformation
%   H = TRVEC2TFORM(T) converts the Cartesian representation of a 3D translation
%   vector, T, into the corresponding homogeneous transformation, H.
%   The input, T, is an N-by-3 matrix containing N translation vectors. Each
%   vector is of the form t = [x y z]. The output, H, is an 4-by-4-by-N matrix
%   of N homogeneous transformations.
%
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.
%
%   See also trvec2tform.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

    numTransl = size(t, 1);
    d = size(t,2) + 1;

    H = repmat(eye(d,'like',t),[1,1,numTransl]);
    H(1:end-1,end,:) = t.';

end
