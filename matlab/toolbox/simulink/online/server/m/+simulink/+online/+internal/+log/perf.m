function perf(varargin)
% The function can get the perf log from front-end and write the struct into a
% xml file. By default, it will log the activity for 30 seconds.
% Inputs:
%     duration: a integer representing the duration in seconds

% Copyright 2021 The MathWorks, Inc.

simulink.online.internal.log.log('perf', varargin{:});
end