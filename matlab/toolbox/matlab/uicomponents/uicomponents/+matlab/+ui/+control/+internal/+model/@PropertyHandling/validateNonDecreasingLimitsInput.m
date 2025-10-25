function rowVectorLimits = validateNonDecreasingLimitsInput(component, limits)
% VALIDATENONDECREASINGLIMITSINPUT
%
%  component - handle to component model throwing the error
%
%  limits - A non-decreasing 1X2 array, excluding -Inf and Inf
%

try
    % Ensure the input is at least a double vector
    validateattributes(limits, ...
        {'numeric'}, ...
        {'vector', 'real', 'nonnan'});

    % reshape to row
    rowVectorLimits = matlab.ui.control.internal.model.PropertyHandling.getOrientedVectorArray(limits, 'horizontal');

    % Verify it is 1x2 row vector
    validateattributes(rowVectorLimits, ...
        {'double'}, ...
        {'size', [1 2]});
catch ME %#ok<NASGU>
    messageObj = message('MATLAB:ui:components:invalidScaleLimits', ...
        'Limits');

    % MnemonicField is last section of error id
    mnemonicField = 'invalidLimits';

    % Use string from object
    messageText = getString(messageObj);

    % Create and throw exception
    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(component, mnemonicField, messageText);
    throwAsCaller(exceptionObject);
end

% Check that it is not decreasing
if(limits(1) > limits(2))
    messageObj = message('MATLAB:ui:components:invalidNonDecreasingScaleLimits', ...
        'Limits');


    % MnemonicField is last section of error id
    mnemonicField = 'notIncreasingLimits';

    % Use string from object
    messageText = getString(messageObj);

    % Create and throw exception
    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(component, mnemonicField, messageText);
    throw(exceptionObject);

end
end