function bool = isHardwareManagerFeatureOn()
% Internal function to indicate whether the standalone hardware manager
% feature is available

% Copyright 2018 Mathworks Inc.

bool = ~isempty(getenv('HARDWARE_MANAGER_FEATURE'));
end