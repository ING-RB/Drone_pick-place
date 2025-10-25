function output = processEnumeratedString(component, input, availableStrings)
% Validates that the given INPUT is a valid enumerated string
% in the AVAILABLESTRINGS set.
%
% A string is valid if it is a full match, i.e. not a partial
% match.  The case of INPUT is ignored.
%
% A string OUTPUT is returned, where it is guaranteed to be the
% proper casing, if INPUT was not a direct case match.
%
% Inputs:
%
%  COMPONENT - handle to component model throwing the error
%
%  INPUT  - the input from a user to validate
%
%           An error is thrown if INPUT is not in AVAILABLESTRINGS.
%
%  AVAILABLESTRINGS - The set of strings to match INPUT
%                     against
%
% Ouputs:
%
%  OUTPUT - the property value a component should store.
%
%           An example would be if the user typed 'Auto', and
%           the component wants to store the proper value
%           'auto'.

% validate string:
% - ensures INPUT is a string
% - finds the best match
% - however, works with partial matching
output = validatestring(input,...
    availableStrings);

% ensures that a partial match did not happen and case is
% ignored
if(~strcmpi(output, input))

    messageObj = message('MATLAB:ui:components:InvalidInputOnlyPartialMatch');

    % MnemonicField is last section of error id
    mnemonicField = 'InvalidInputOnlyPartialMatch';

    % Use string from object
    messageText = getString(messageObj);

    % Create and throw exception
    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(component, mnemonicField, messageText);
    throw(exceptionObject);

end
end