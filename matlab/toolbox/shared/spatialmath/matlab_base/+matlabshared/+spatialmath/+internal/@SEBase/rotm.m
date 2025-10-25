function R = rotm(obj)
%ROTM Extract rotation matrix
%
%   R = ROTM(T) extracts the rotational part of the SE3
%   transformation, T, and returns it as a 3-by-3 rotation matrix,
%   R. The translational part of T is ignored.
%
%   If T is an array of N transformations, then R is an
%   3-by-3-by-N matrix containing N rotation matrices.
%
%   See also trvec, tform.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    d = obj.Dim-1;
    R = obj.M(1:d, 1:d, :);

end
