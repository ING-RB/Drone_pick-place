function T = tform(obj)
%TFORM Convert to homogeneous transformation matrix
%   TF = TFORM(R) returns the 3-by-3 or 4-by-4 matrix, TF, corresponding to
%   the so2 or so3 rotation, R. The translational parts of TF are zero.
%
%   If R is an array of N rotations, then TF is an 3-by-3-by-N or
%   4-by-4-by-N array containing N transformation matrices.
%
%   See also trvec, rotm.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    T = robotics.internal.rotm2tform(obj.M);

end
