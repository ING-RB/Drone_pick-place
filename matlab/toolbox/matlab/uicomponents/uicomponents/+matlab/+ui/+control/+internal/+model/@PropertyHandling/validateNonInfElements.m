function validateNonInfElements(component, array)
% Validates that each element in the ARRAY is not -Inf or Inf
%
%
%  component - handle to component model throwing the error
%
% a valid number
%

% Check that it is increasing
if(any(array(:) == Inf) || any(array(:) == -Inf))

    messageObj = message('MATLAB:ui:components:InvalidInputContainingInf');

    % MnemonicField is last section of error id
    mnemonicField = 'InvalidInputContainingInf';

    % Use string from object
    messageText = getString(messageObj);

    % Create and throw exception
    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(component, mnemonicField, messageText);
    throw(exceptionObject);

end
end