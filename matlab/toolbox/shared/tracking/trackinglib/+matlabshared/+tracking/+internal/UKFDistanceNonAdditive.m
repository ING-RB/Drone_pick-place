function d = UKFDistanceNonAdditive(UKF, z_matrix, measurementParams)
% UKFDistance Computes distances between measurements and an unscented
% Kalman filter object.
%   d = distance(UKF, z_matrix) computes a distance between one or more
%   measurements supplied by the z_matrix and the measurement predicted by
%   the unscented Kalman filter object. This computation takes into account
%   the covariance of the predicted state and the process noise. Each row
%   of the input z_matrix must contain a measurement vector of length N.
%
%   d = distance(UKF, z_matrix, measurementParams) allows to defined
%   additional parameters that will be used by the UKF.MeasurementFcn. It
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

%   Copyright 2016 The MathWorks, Inc.

%#codegen
%#ok<*EMCLS>
%#ok<*EMCA>
%#ok<*MCSUP>

if nargin == 2    
    measurementParams = cell(0,0);
end

X1 = UKF.State;
Ns = numel(X1); % Number of states
Nv = size(UKF.MeasurementNoise,1); % Number of measurement noise terms
vZeros = zeros(Nv, 1, 'like', X1);
if UKF.HasMeasurementWrapping
    [Y1,wrapping] = UKF.MeasurementFcn(X1, vZeros, measurementParams{:}); % Measurement at the first sigma point
else
    Y1 = UKF.MeasurementFcn(X1, vZeros, measurementParams{:}); % Measurement at the first sigma point
    wrapping = matlabshared.tracking.internal.defaultWrapping(coder.internal.indexInt(numel(Y1)), class(Y1));
end
Ny = numel(Y1); % Number of measurements

% Calculate UT parameters
[c, Wmean, Wcov, OOM] = matlabshared.tracking.internal.calcUTParameters(...
    UKF.Alpha, UKF.Beta, UKF.Kappa, cast(Ns+Nv,'like',UKF.Alpha));
% Generate the sigma points
[~,X2state] = matlabshared.tracking.internal.calcSigmaPoints(UKF.StateCovariance, X1, c);
[~,X2noise] = matlabshared.tracking.internal.calcSigmaPoints(UKF.MeasurementNoise, vZeros, c);
% first sigma point is just X1

% Measurements at the sigma points
Y2 = zeros(Ny, 2*(Ns+Nv), 'like', X1); %memory allocation
for kk = 1:2*Ns
    Y2(:,kk) = UKF.MeasurementFcn(X2state(:,kk), vZeros, measurementParams{:});
end
for kk=1:2*Nv
    idx = 2*Ns + kk;
    Y2(:,idx) = UKF.MeasurementFcn(X1, X2noise(:,kk), measurementParams{:});
end

% Calculate the unscented transformation mean and covariance
[zEstimated, residualCovariance] = matlabshared.tracking.internal.UTMeanCov(Wmean, Wcov, OOM, Y1, Y2, X1, X2state);

% Wrap measurements around
if size(z_matrix,2)==numel(zEstimated)
    z_matrix(:) = (matlabshared.tracking.internal.wrapResidual(z_matrix' - zEstimated(:), ...
        wrapping,'distance') + zEstimated(:))';
else
    z_matrix(:) = matlabshared.tracking.internal.wrapResidual(z_matrix - zEstimated(:), ...
        wrapping,'distance') + zEstimated(:);
end

% Calculate the distance
d = cast(matlabshared.tracking.internal.KFDistance(zEstimated,z_matrix,residualCovariance),...
    'like', X1);
end