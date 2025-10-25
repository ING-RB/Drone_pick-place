function R = tform2rotm(H)
%This method is for internal use only. It may be removed in the future.

%TFORM2ROTM Extract rotation matrix from homogeneous transformation
%   R = TFORM2ROTM(H) extracts the rotational component from a 3D homogeneous
%   transformation, H, and returns it as an orthonormal rotation matrix, R.
%   The translational components of H will be ignored.
%   The input, H, is an 4-by-4-by-N matrix of N homogeneous transformations.
%   The output, R, is an 3-by-3-by-N matrix containing N rotation matrices.
%
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.
%
%   See also tform2rotm.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

    R = H(1:end-1,1:end-1,:);
end
