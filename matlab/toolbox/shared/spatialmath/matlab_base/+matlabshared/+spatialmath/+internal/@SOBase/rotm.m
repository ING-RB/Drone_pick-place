function RM = rotm(obj)
%ROTM Extract rotation matrix
%
%   RM = ROTM(R) extracts the rotation matrix from the so2 or so3 rotation,
%   R. RM is either a 2-by-2 or 3-by-3 rotation matrix.
%
%   If R is an array of N rotations, then RM is an 2-by-2-by-N or
%   3-by-3-by-N array containing N rotation matrices.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    RM = obj.M;

end
