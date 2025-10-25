function s = statecovparts(filt, varargin)
% STATECOVPARTS Set and get parts of the state covariance matrix.
%
% STATECOVPARTS(FILT, STATENAME) returns the portion of the state
% covariance matrix associated with the state STATENAME. The returned
% matrix is a square submatrix extracted from along the main diagonal of
% the full state covariance matrix.
%
% STATECOVPARTS(FILT, SENSOR, STATENAME) returns the portion of the state
% covariance matrix associated with state STATENAME of sensor SENSOR, where
% SENSOR is a handle to a sensor object.
%
% STATECOVPARTS(FILT, STATENAME, VAL) sets the portion of the
% state covariance matrix associated with state STATENAME to VAL. The
% argument VAL can be either an appropriately sized square matrix, a
% scalar, or a vector (interpreted as the main diagonal elements 
% of the covariance matrix associated with STATENAME).
%
% STATECOVPARTS(FILT, SENSOR, STATENAME, VAL) sets the portion of
% the state covariance matrix associated with state STATENAME of sensor
% SENSOR to VAL, where SENSOR is a handle to a sensor object. The
% argument VAL can be either an appropriately sized square matrix, a
% scalar, or a vector (interpreted as the main diagonal elements 
% of the covariance matrix associated with STATENAME).
%
%   Example : Set and get the accelerometer bias covariance
%   acc = insAccelerometer;
%   gyro = insGyroscope;
%   filt = insEKF(acc, gyro);
%
%   statecovparts(filt, acc, "Bias", magic(3)); % set the 3-by-3 submatrix 
%   statecovparts(filt, acc, "Bias", [1 2 3]);  % set the main diagonal
%   statecovparts(filt, acc, "Bias", 3);        % set the main diagonal
%   statecovparts(filt, acc, "Bias");           % get   
%   statecovparts(filt, "Accelerometer_Bias");  % get
%
%   See also: insEKF/stateparts

%   Copyright 2021 The MathWorks, Inc.      

%#codegen   

% Determine if this is a set or get. 
% Rule: if nargin == 4 and/or the last argument is numeric, it's a set.
%       Otherwise it's a get.

if nargin == 4 || (nargin > 1 && isnumeric(varargin{end}))
    % set. Error if nargout > 0
    coder.internal.assert(nargout == 0, 'insframework:insEKF:StateCovPartsOutOnGet');
    idx = getStateInfo(filt, 'statecovparts', varargin{1:end-1});
    % Make sure the argument is the right size but allow for
    % expansion.
    v = varargin{end};
    if isscalar(v) || isvector(v)
        % Just set the diagonal
        midx = filt.StateCovDiagIndices(idx);
        nsc = numel(midx);
        nv = numel(v);
        coder.internal.assert(nsc == nv || nv == 1, 'insframework:insEKF:SetStateCovNumel', nsc);
        filt.StateCovariance(midx) = v;
    else % Better be a square matrix
        nsc = numel(idx);
        coder.internal.assert(isequal(size(v), [nsc,nsc]), 'insframework:insEKF:SetStateCovNumel', nsc);
        filt.StateCovariance(idx,idx) = v;
    end    

else
    % get
    idx = getStateInfo(filt, 'stateparts', varargin{:}); 
    s = filt.StateCovariance(idx,idx);
end
