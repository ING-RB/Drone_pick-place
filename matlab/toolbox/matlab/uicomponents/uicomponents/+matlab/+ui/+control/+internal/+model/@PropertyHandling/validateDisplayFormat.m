function convertedFormatString = validateDisplayFormat(component, newFormatString, propertyName, currentValue)
% Validates that NEWFORMATSTRING is a valid sprintf string for
% formatting a value
%
% Inputs:
%
%  component - handle to component model throwing the error
%
%  newFormatString     - The user entered string to validate
%
%  propertyName        - The property name being validated
%                        (Used for error messages)
%
%  currentValue        - current value to format, used to
%                        double check that it can be formatted
%
% Output:
%
% convertedFormatString - User entered string validated and converted to char
%
% Callers of this function should wrap the call in a try/catch,
% and re-throw the error message with their own error ID.

% check it is a char or a string
if(~ischar(newFormatString) && ~isstring(newFormatString))

    messageObj = message('MATLAB:ui:components:invalidDisplayFormat', propertyName);

    % Use string from object
    messageText = getString(messageObj);

    docLinkId = 'MATLAB:ui:components:sprintfDocLink';
    messageText = matlab.ui.control.internal.model.PropertyHandling.createMessageWithDocLink(messageText, docLinkId, 'sprintf');

    % MnemonicField is last section of error id
    mnemonicField = 'invalidDisplayFormat';

    % Create and throw exception
    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(component, mnemonicField, '%s', messageText);
    throw(exceptionObject);

end

% validate and convert newFormatString to char
convertedFormatString = matlab.ui.control.internal.model.PropertyHandling.validateText(newFormatString);

% Verify that the format string is correct by making sure it
% can properly format the current Value
[~,  errorMessage] = sprintf(convertedFormatString, currentValue);

if(~isempty(errorMessage))
    sprintfLink = '<a href="matlab: help(''sprintf'')">help sprintf</a>';

    messageObj = message('MATLAB:ui:components:misformattedDisplayFormat', propertyName, sprintfLink);

    % MnemonicField is last section of error id
    mnemonicField = 'misformattedDisplayFormat';

    % Use string from object
    messageText = getString(messageObj);

    % Create and throw exception
    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(component, mnemonicField, '%s', messageText);
    throw(exceptionObject);

end

end