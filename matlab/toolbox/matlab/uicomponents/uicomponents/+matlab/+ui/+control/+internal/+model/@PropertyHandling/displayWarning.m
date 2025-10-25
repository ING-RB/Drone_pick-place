function displayWarning(component, mnemonicField, messageText, varargin)
% DISPLAYWARNING- This display a warning.
% The warning as a msgID is of the form
% MATLAB:ui:ComponentName:WarningDescription
% For example:
% MATLAB:ui:Slider:fixedHeight

% Suppress stack trace after the warning
oldWarnState = warning('backtrace', 'off');

componentName = matlab.ui.control.internal.model.PropertyHandling.getComponentClassName(component);
msgId = ['MATLAB:ui:', componentName, ':', mnemonicField];
warning(msgId, messageText, varargin{:});

% Restore initial warning state
warning(oldWarnState);

end