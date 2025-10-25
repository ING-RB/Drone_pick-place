function schedulerMessage(levelNum, messageStringOrException, varargin)
%SCHEDULERMESSAGE sends a message to the scheduler
%
%  SCHEDULERMESSAGE(LEVEL, EXCEPTION)
%  SCHEDULERMESSAGE(LEVEL, MESSAGE_STRING, EXCEPTION)
%  SCHEDULERMESSAGE(LEVEL, FORMAT_MESSAGE_STRING, A, ...)
%
% This function is for internal use only, and may be removed in a future
% release.

%  Copyright 2021 The MathWorks, Inc.

% This function simply acts as a wrapper so that dctSchedulerMessage is only
% called from MATLAB code if PCT is installed and licensed.
if matlab.internal.parallel.isPCTInstalled && matlab.internal.parallel.isPCTLicensed
    dctSchedulerMessage(levelNum, messageStringOrException, varargin{:});
end

