function d = EKFDistanceAdditive(EKF, z_matrix, measurementParams)
% EKFDistanceAdditive Computes distances between measurements and an
% extended Kalman filter object, for models with additive measurement
% noise.
%   d = distance(EKF, z_matrix) computes a distance between one or more
%   measurements supplied by the z_matrix and the measurement predicted by
%   the extended Kalman filter object. This computation takes into account
%   the covariance of the predicted state and the process noise. Each row
%   of the input z_matrix must contain a measurement vector of length N.
%
%   d = distance(EKF, z_matrix, measurementParams) allows to defined
%   additional parameters that will be used by the EKF.MeasurementFcn. It
%   should be specified as a cell array, e.g., {1, [2;3]}. If unspecified,
%   it will be assumed to be an empty cell array. 
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
%       2. This function uses the regular EKF correct, i.e., when the
%          process noise is additive.

%   Copyright 2016-2020 The MathWorks, Inc.

%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>
%#ok<*MCSUP>

if nargin == 2
    measurementParams = cell(0,0);
end

% Calculate the extended Kalman filter expected measurement and covariance
if isempty(EKF.MeasurementJacobianFcn)
    dHdx = matlabshared.tracking.internal.numericJacobianAdditive(EKF.MeasurementFcn, EKF.State, measurementParams); 
else
    dHdx = EKF.MeasurementJacobianFcn(EKF.State, measurementParams{:});
end

classToUse = class(EKF.State);
if ~isa(dHdx, classToUse)
    dHdx = cast(dHdx, classToUse);
end

if EKF.HasMeasurementWrapping
    [zEstimated, wrapping] = EKF.MeasurementFcn(EKF.State, measurementParams{:});
    zEstimated = cast(zEstimated(:), classToUse);
    residualCovariance = dHdx * EKF.StateCovariance * dHdx' + EKF.MeasurementNoise;
    % Wrap measurements around
    if size(z_matrix,2)==numel(zEstimated)
        z_matrix(:) = (matlabshared.tracking.internal.wrapResidual(z_matrix' - zEstimated(:), ...
            wrapping, 'distance') + zEstimated(:))';
    else
        z_matrix(:) = matlabshared.tracking.internal.wrapResidual(z_matrix - zEstimated(:), ...
            wrapping, 'distance') + zEstimated(:);
    end
else
    zEstimated = EKF.MeasurementFcn(EKF.State, measurementParams{:});
    zEstimated = cast(zEstimated(:), classToUse);
    residualCovariance = dHdx * EKF.StateCovariance * dHdx' + EKF.MeasurementNoise;
end

% Calculate the distance
d = cast(matlabshared.tracking.internal.KFDistance(zEstimated,z_matrix,residualCovariance),...
    classToUse);
end
