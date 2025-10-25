function normObj = normalize(obj, varargin)
%NORMALIZE Normalize the rotation submatrix
%
%   TN = NORMALIZE(T) returns a transformation equivalent to T, but with
%   the rotational submatrix normalized. The rotational submatrix
%   in TN is guaranteed to be orthonormal (orthogonal and norm
%   of each column is 1). The translational part is unchanged. The last row
%   of the transformation matrix is also enforced to be [zeros(1,N-1) 1)]
%   where N is the number of columns.
%
%   TN = NORMALIZE(T, Name=Value) specifies additional
%   options using one or more name-value pair arguments.
%   Specify the options after all other input arguments.
%
%      Method - Specify which normalization method should be used.
%         The following method choices are supported:
%
%         "quaternion" - Converts the rotation submatrix into a
%         quaternion, normalizes the quaternion, and then
%         converts back to rotation matrix.
%
%         "cross" - Normalizes the third (z) column of the
%         rotation submatrix and then determine the other two
%         columns through cross products.
%
%         "svd" - Uses singular value decomposition to find the
%         closest orthonormal matrix by setting singular values
%         to 1. This solves the orthogonal Procrustes problem.
%
%         Default: "quaternion"

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Call static function for parsing
    method = obj.parseNormalizeInput(varargin{:});

    % Extract rotations and normalize
    Rn = obj.normalizeRotm(method);

    d = obj.Dim-1;

    % Replace rotation matrix with normalized version
    M = obj.M;
    M(1:d,1:d,:) = Rn;

    % Always fix the last row as [0 .. 0 1] to ensure that we have a proper
    % transformation matrix.
    M(d+1,:,:) = repmat([zeros(1,d,"like",obj.M) 1],1,1,size(M,3));

    normObj = obj.fromMatrix(M, size(obj));

end
