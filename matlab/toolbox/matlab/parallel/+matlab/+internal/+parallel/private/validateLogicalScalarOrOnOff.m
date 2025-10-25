function value = validateLogicalScalarOrOnOff(value, errorID)
% validateLogicalScalarOrOnOff Check that value is a logical scalar or "on"/"off" scalar strings.

%   Copyright 2024 The MathWorks, Inc.

% Validate and resolve the user input to one of the text values.
if matlab.internal.datatypes.isScalarText(value)
    validOptions = ["on", "off"];
    partialMatch = startsWith(validOptions, value, "IgnoreCase", true);
    if sum(partialMatch) == 1
        value = validOptions(partialMatch);
    else
        error(message(errorID));
    end
elseif isscalar(value) && (islogical(value) || (isnumeric(value) && (value == 0 || value == 1)))
    % Convert to string version. For apps, we only allow "on" & "off".
    if value
        value = "on";
    else
        value = "off";
    end
else
    error(message(errorID));
end