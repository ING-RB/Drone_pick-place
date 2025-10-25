function newTicks = validateTickArray(component, ticks, propertyName)
% Verify that the ticks are numeric, vector, real, finite.

% Check for [], which is allowed but needs to be handled
% special
isEmptyArray = isempty(ticks) && isa(ticks,'double');
if(isEmptyArray)
    newTicks = ticks;
    return
end

% Validates that TICKS is a valid numeric, 1D, finite, real array
messageId = '';
if ~(isnumeric(ticks) && isvector(ticks))
    % If ticks are not numeric or 1xN/Nx1, throw generic error
    messageId = 'MATLAB:ui:components:invalidTicksNotNumericVector';
elseif any(isinf(ticks)) || any(isnan(ticks))
    % Ticks should not contain NaN or Inf
    messageId = 'MATLAB:ui:components:invalidTicksNotFinite';
elseif ~isreal(ticks(:))
    % Ticks should not contain complex values
    messageId = 'MATLAB:ui:components:invalidTicksNotReal';
end

% Throw error if messageId was populated
if ~isempty(messageId)
    messageObj = message(messageId, propertyName);

    % MnemonicField is last section of error id
    mnemonicField = ['invalid', propertyName];

    % Use string from object
    messageText = getString(messageObj);

    % Create and throw exception
    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(component, mnemonicField, messageText);

    % Let error seem like it's coming from the setter
    throwAsCaller(exceptionObject);
end

% Perform updates on ticks to fix minor inconsistencies to
% the expectations for ticks.
ticks = matlab.ui.control.internal.model.PropertyHandling.getSortedUniqueVectorArray(ticks, 'horizontal');
newTicks = double(ticks);
end