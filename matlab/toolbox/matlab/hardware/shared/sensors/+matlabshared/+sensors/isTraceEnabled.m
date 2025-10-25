function result = isTraceEnabled(hwObject)

% This function checks if the hardware object is currently configured for
% trace messages. If so, sensor streaming should not be performed.

%   Copyright 2020-2021 The MathWorks, Inc.

result = false;
if isa(hwObject, 'matlabshared.hwsdk.controller')
    result = hwObject.TraceOn;
end
end