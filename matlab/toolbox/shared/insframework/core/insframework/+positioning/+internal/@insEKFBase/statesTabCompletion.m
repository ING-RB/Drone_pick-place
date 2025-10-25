function choices = statesTabCompletion(filt,sensor)
%This function is for internal use only. It may be removed in the future.
%STATESTABCOMPLETION Tab completion options for insEKF
%   Returns an array of strings CHOICES which are the possible tab
%   completion choices for stateinfo, stateparts, and statecovparts. 

%   Copyright 2021 The MathWorks, Inc.    

try
    if nargin > 1
        idx = getSensorIndex(filt, sensor);
        choices = string(fieldnames(filt.SensorStateInfo{idx}));
    else
        choices = string(fieldnames(stateinfo(filt)));
    end
catch % If failure, don't error. Just return an empty list
    choices = string.empty;
end
end
