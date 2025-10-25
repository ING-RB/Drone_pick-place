function d = KFDistance(zEstimated,z_matrix,residualCovariance)
% KFDistance Computes distances between measurements and a
% (linear,unscented,extended) Kalman filter object.
%   d = KFDistance(zEstimated, z_matrix, residualCovariance) computes a
%   distance between one or more measurements supplied by the z_matrix and
%   the predicted measurement by a linear, unscented or extended Kalman
%   filter object. This computation takes into account the covariance of
%   the predicted state and the process noise. Each row of the input
%   z_matrix must contain a measurement vector of length N.
%
%   The distance method returns a row vector where each element is a
%   distance associated with the corresponding measurement input. The
%   distance method can only be called after the predict method.

% The procedure for computing the distance is described in Page 93 of
% "Multiple-Target Tracking with Radar Applications" by Samuel
% Blackman.

%   Notes:
%       1. Since this is an internal function, no validation is done at
%          this level. Any additional input validation should be done in a
%          function or object that use this function.

%   Copyright 2016 The MathWorks, Inc.

%#codegen

Ny = numel(zEstimated);
z_in = zeros(Ny, 1, 'like', zEstimated);
isNColumnMatrix = (size(z_matrix, 2) == Ny);
if isNColumnMatrix
    len = size(z_matrix, 1);
    d = zeros(1, len, 'like', zEstimated);
    for idx = 1:len
        z_in(:) = z_matrix(idx,:)';
        d(idx) = matlabshared.tracking.internal.normalizedDistance(z_in, zEstimated, residualCovariance);
    end
elseif(numel(z_matrix) > 0) % N-by-1 matrix
    z_in(:) = z_matrix;
    d = matlabshared.tracking.internal.normalizedDistance(z_in, zEstimated, residualCovariance);
else
    d = [];
end

end