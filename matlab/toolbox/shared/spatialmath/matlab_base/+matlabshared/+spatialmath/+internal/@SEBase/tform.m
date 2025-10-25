function T = tform(obj)
%TFORM Homogeneous transformation matrix
%   TF = TFORM(T) returns the 4-by-4 matrix, TF, corresponding to the
%   se3 transformation, T.
%
%   If T is an array of N transformations, then TF is an
%   4-by-4-by-N array containing N transformation matrices.
%
%   See also trvec, rotm.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    T = obj.M;

end
