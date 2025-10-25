function output = processCellArrayOfStrings(component, propertyName, input, sizeConstraints)
% Validates that the input is a cell array of strings and
% optionally, is of a certain size.
%
% The array is returned, where it is guaranteed to be a row
% vector, if the original array was passed in as a column
% vector.
%
% Inputs:
%
%  COMPONENT - handle to component model throwing the error
%
%  INPUT -  input to validate as a cell array of strings
%
%  SIZECONSTRAINTS - 1x2 vector representing the minimum and
%                    maximum number of elements
%
% Ouputs:
%
%  OUTPUT - the INPUT array, but as a row vector if a column
%           vector was passed in
narginchk(4, 4);


% Convert categoricals to strings to maintain
% consistency of behavior between both.
if (iscategorical(input))
    input = string(input);
end

% Convert string to cell array of characters.
if(isstring(input) && isvector(input))
    input = cellstr(input);
end

% special check for cell because {} does not pass the test of
% being a vector
if(isequal(input, {}) && sizeConstraints(1) == 0)
    output = input;
    return;
end

% validate cell of all strings
if(~iscellstr(input))
    messageObj = message('MATLAB:ui:components:InvalidInputNotACellOfStrings', propertyName);

    % MnemonicField is last section of error id
    mnemonicField = 'InvalidInputNotACellOfStrings';

    % Use string from object
    messageText = getString(messageObj);

    % Create and throw exception
    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(component, mnemonicField, messageText);
    throw(exceptionObject);

end

if iscell(input)

    % check sizes
    elements = numel(input);
    if sizeConstraints(1) == sizeConstraints(2) && elements ~=sizeConstraints(1)

        messageObj = message('MATLAB:ui:components:InputSizeWrong', propertyName, num2str(sizeConstraints(1)));

        % MnemonicField is last section of error id
        mnemonicField = 'InputSizeWrong';

        % Use string from object
        messageText = getString(messageObj);

        % Create and throw exception
        exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(component, mnemonicField, messageText);
        throw(exceptionObject);
    elseif (elements < sizeConstraints(1))

        messageObj = message('MATLAB:ui:components:InputSizeTooSmall', propertyName, num2str(sizeConstraints(1)));

        % MnemonicField is last section of error id
        mnemonicField = 'InputSizeTooSmall';

        % Use string from object
        messageText = getString(messageObj);

        % Create and throw exception
        exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(component, mnemonicField, messageText);
        throw(exceptionObject);

    elseif (elements > sizeConstraints(2))

        messageObj = message('MATLAB:ui:components:InputSizeTooLarge', propertyName, num2str(sizeConstraints(2)));

        % MnemonicField is last section of error id
        mnemonicField = 'InputSizeTooLarge';

        % Use string from object
        messageText = getString(messageObj);

        % Create and throw exception
        exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(component, mnemonicField, messageText);
        throw(exceptionObject);

    end
end

% Verify that it is a vector and reshape
validateattributes(input, ...
    {'cell'}, {'vector'});

% reshape to row
output = matlab.ui.control.internal.model.PropertyHandling.getOrientedVectorArray(input, 'horizontal');
end