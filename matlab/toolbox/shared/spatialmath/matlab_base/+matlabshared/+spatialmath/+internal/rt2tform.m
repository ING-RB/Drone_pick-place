function T = rt2tform(R,t,d)
%This method is for internal use only. It may be removed in the future.

%rt2tform Method to create a transformation matrix from a numeric rotation and a translation
%   R is expected to be a 3x3xN or 2x2xN single or double array
%     - If d is 3, R can be 2x2xN or 3x3xN. In the latter case, R is
%     treated as a transformation and the 2x2xN submatrix is extracted
%     - If d is 4, R can be 3x3xN or 4x4xN. In the latter case, R is
%     treated as a transformation and the 3x3xN submatrix is extracted
%   T is a 3xN matrix / 3x1xN array or 2xN / 2x1xN
%   t is expected to by Nx2 or Nx3
%   d is the length of the underlying matrix of the T output
%     - If d is 3, the output will be a 3x3 transformation matrix (se2)
%     - If d is 4, the output will be a 4x4 transformation matrix (se3)

%   Copyright 2024 The MathWorks, Inc.

%#codegen

    numMats = size(R,3);

    % Assign rotation
    T = zeros(d,d,numMats,"like",R);
    if size(R,1) == d
        T(1:d-1,1:d-1,:) = R(1:d-1,1:d-1,:);
    else
        T(1:d-1,1:d-1,:) = R;
    end
    T(d,d,:) = ones(1,1,numMats,"like",R);
    % Assign translation
    T(1:d-1,d,:) = t;

end
