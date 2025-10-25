function s = stateparts(filt, varargin)
%STATEPARTS Set and get parts of the state vector.
%
%   STATEPARTS(FILT, STATENAME) returns the portion of the state
%   vector associated with the state STATENAME.
%
%   STATEPARTS(FILT, SENSOR, STATENAME) returns the portion of
%   the state vector associated with state STATENAME of sensor
%   SENSOR, where SENSOR is a handle to a sensor object.
%
%   STATEPARTS(FILT, STATENAME, VAL) sets the portion of the
%   state vector associated with state STATENAME to VAL.
%
%   STATEPARTS(FILT, SENSOR, STATENAME, VAL) sets the portion of
%   the state vector associated with state STATENAME of sensor
%   SENSOR to VAL, where SENSOR is a handle to a sensor object.
%
%   Example : Set and get the accelerometer bias
%   acc = insAccelerometer;
%   gyro = insGyroscope;
%   filt = insEKF(acc, gyro);
%
%   stateparts(filt, acc, "Bias", [10 0 1]); % set
%   stateparts(filt, acc, "Bias");           % get   
%   stateparts(filt, "Accelerometer_Bias");
%
%  See also: insEKF/stateinfo, insEKF/statecovparts

%   Copyright 2021 The MathWorks, Inc.      

%#codegen   

% Determine if this is a set or get. 
% Rule: if nargin == 4 and/or the last argument is numeric, it's a set.
%       Otherwise it's a get.

narginchk(2,4);

if nargin == 4 || (nargin > 1 && isnumeric(varargin{end}))
    % set. Error if nargout > 0
    coder.internal.assert(nargout == 0, 'insframework:insEKF:StatePartsOutOnGet');
    idx = getStateInfo(filt, 'stateparts', varargin{1:end-1});
    n = numel(idx);
    na = numel(varargin{end});
    % Make sure the argument is the right size but allow for scalar
    % expansion.
    coder.internal.assert(isequal(na, n) || na == 1, ...
        'insframework:insEKF:SetSameStateNumel', n);
    filt.State(idx) = varargin{end};
else
    % get
    idx = getStateInfo(filt, 'stateparts', varargin{:}); 
    s = reshape(filt.State(idx),1,[]);
end
