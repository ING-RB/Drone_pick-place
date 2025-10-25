function H = rotm2tform(R)
%This method is for internal use only. It may be removed in the future.

%ROTM2TFORM Convert rotation matrix to homogeneous transform
%   H = ROTM2TFORM(R) converts the 3D rotation matrix, R, into a homogeneous
%   transformation, H. H will have no translational components.
%   R is an 3-by-3-by-N matrix containing N rotation matrices.
%   Each rotation matrix has a size of 3-by-3 and is orthonormal.
%   The output, H, is an 4-by-4-by-N matrix of N homogeneous transformations.
%
%
%   This is an internal function that does no input validation and is used
%   by user-facing functionality.
%
%   See also rotm2tform.

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

    numMats = size(R,3);
    d = size(R,1);

    % The rotational components of the homogeneous transformation matrix
    % are located in elements H(1:d,1:d).
    H = zeros(d+1,d+1,numMats,"like",R);
    H(1:d,1:d,:) = R;
    H(d+1,d+1,:) = ones(1,1,numMats,"like",R);

end
