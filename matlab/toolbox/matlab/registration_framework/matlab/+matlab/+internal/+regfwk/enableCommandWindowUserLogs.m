function enableCommandWindowUserLogs(enabled)
% enableCommandWindowUserLogs Enables elevation of Extension Points Framework user logging to Command Window
%
%   matlab.internal.regfwk.enableCommandWindowUserLogs(enabled)
%   Toggles displaying log messages to the MATLAB Command Window for Extension Points Framework metadata user errors
%
%
%   enabled indicates whether the elevation of these user errors should be enabled,
%   specified as a scalar logical

% Copyright 2023 The MathWorks, Inc.

persistent evtListener;

if (islogical(enabled) && isscalar(enabled))
    if (enabled)
        if (isempty(evtListener))
            evtListener = matlab.internal.mvm.eventmgr.MVMEvent.subscribe( ...
                'epfwk_events::Log', ...
                @matlab.internal.regfwk.utils.displayLogInCommandWindow);
        end
    else
        if (~isempty(evtListener))
            delete(evtListener);
            evtListener = [];
        end
    end
else
    ME = MException(message('registration_framework:reg_fw_resources:invalidInputParameterExpectedScalarLogical', 'enabled'));
    throw(ME);
end
end
