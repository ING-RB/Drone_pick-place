function val = ExtModeTargetPollingTimeVisibleCallback(hObj)
% ExtModeTargetPollingTimeVisibleCallback - control visibility
% of the target polling time configset options

%   Copyright 2024 The MathWorks, Inc.
val = contains(hObj.CoderTargetData.ExtMode.Configuration,'XCP');
end