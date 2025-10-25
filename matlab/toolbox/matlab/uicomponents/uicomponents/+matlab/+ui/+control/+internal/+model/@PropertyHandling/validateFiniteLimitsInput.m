function rowVectorLimits = validateFiniteLimitsInput(component, limits)
% Validates that the LIMITS is a valide 1X2 numeric array
%
%  component - handle to component model throwing the error
%
%  limits - An increasing 1X2 array, excluding -Inf and Inf

try

    %  Ensure it's a valid limits
    rowVectorLimits = matlab.ui.control.internal.model.PropertyHandling.validateLimitsInput(component, limits);

    % Ensure no -Inf or Inf in limits
    matlab.ui.control.internal.model.PropertyHandling.validateNonInfElements(component, rowVectorLimits)
catch ME %#ok<NASGU>
    messageObj = message('MATLAB:ui:components:invalidFiniteScaleLimits', ...
        'Limits');

    % MnemonicField is last section of error id
    mnemonicField = 'invalidFiniteScaleLimits';

    % Use string from object
    messageText = getString(messageObj);

    % Create and throw exception
    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(component, mnemonicField, messageText);
    throwAsCaller(exceptionObject);

end
end