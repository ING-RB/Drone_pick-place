function s = stateinfo(filt, varargin)
%STATEINFO indices of state variables
%   STATEINFO(FILT) returns a struct with fields indicating the
%   indices of each state variable.
%
%   STATEINFO(FILT, S) returns a vector of indices for the state
%   S in the state vector.
%
%   STATEINFO(FILT, SEN, S) returns a vector of indices for the
%   state S of sensor S
%
%   Example:
%   filt = insEKF;
%   stateinfo(filt)
%   stateinfo(filt, "Orientation");
%   stateinfo(filt, filt.Sensors{1}, "Bias")
%   stateinfo(filt, "Accelerometer_Bias")
%
%   See also: insEKF/stateparts

%   Copyright 2021 The MathWorks, Inc.

%#codegen   

s = getStateInfo(filt, 'stateinfo', varargin{:});
end
