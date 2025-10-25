function resetImpl(obj)
%RESETIMPL Reset states of nav.internal.gnss.GNSSSensorSimulator object

%   Copyright 2022 The MathWorks, Inc.

%#codegen

% Set the current time to the initial time of week in seconds.
obj.pCurrTime = obj.pTimeOfWeek;

% Reset random stream if needed.
if strcmp(obj.RandomStream, 'mt19937ar with seed')
    obj.pStream.reset;
end
end
