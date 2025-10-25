function normObj = normalize(obj, varargin)
%normalize Normalize the rotation matrix
%
%   RN = normalize(R) returns a rotation equivalent to R, but normalized.
%   The rotation matrix in RN is guaranteed to be orthonormal (orthogonal and norm
%   of each column is 1).
%
%   RN = normalize(T, Name=Value) specifies additional
%   options using one or more name-value pair arguments.
%   Specify the options after all other input arguments.
%
%      Method - Specify which normalization method should be used.
%         The following method choices are supported:
%
%         "quaternion" - Converts the rotation matrix into a
%         quaternion, normalizes the quaternion, and then
%         converts back to rotation matrix.
%
%         "cross" - Normalizes the third (z) column of the
%         rotation matrix and then determine the other two
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

    normObj = obj.fromMatrix(Rn, size(obj));

end
