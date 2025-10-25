function output = processItemsDataInput(component, propertyName, input, sizeConstraints)
% Validates that the input is a vector array or vector cell array
% An error is thrown if the input is not valid
%
% If the input is an Nx1 vector, it will be converted into
% a 1xN vector
%
% Inputs:
%
%  COMPONENT - handle to component model throwing the error
%
%  INPUT  - the input from a user to validate
%
%  SIZECONSTRAINTS - 1x2 vector representing the minimum and
%                    maximum number of elements
%
% Ouputs:
%
%  OUTPUT - the property value a component should store.
%
%           An example would be if the user entered a Nx1 cell,
%           and the component wants to store it as a 1xN cell


narginchk(4, 4);

% special check for empty because ItemsData is always allowed
% to be empty, regardless of the size constraints
if (isempty(input))
    output = input;
    return;
end

% Verify that it is a vector
if isvector(input)
    % reshape to row
    output = matlab.ui.control.internal.model.PropertyHandling.getOrientedVectorArray(input, 'horizontal');
else
    messageObj = message('MATLAB:ui:components:InputNotAVector', propertyName);

    % MnemonicField is last section of error id
    mnemonicField = 'InputNotAVector';

    % Use string from object
    messageText = getString(messageObj);

    % Create and throw exception
    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(component, mnemonicField, messageText);
    throw(exceptionObject);
end

% check sizes
[~, columns] = size(output);
if (columns < sizeConstraints(1))
    messageObj = message('MATLAB:ui:components:InputSizeTooSmall', ...
        propertyName, num2str(sizeConstraints(1)));


    % MnemonicField is last section of error id
    mnemonicField = 'InputSizeTooSmall';

    % Use string from object
    messageText = getString(messageObj);

    % Create and throw exception
    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(component, mnemonicField, messageText);
    throw(exceptionObject);

elseif (columns > sizeConstraints(2))
    messageObj = message('MATLAB:ui:components:InputSizeTooLarge',...
        propertyName, num2str(sizeConstraints(2)));

    % MnemonicField is last section of error id
    mnemonicField = 'InputSizeTooLarge';

    % Use string from object
    messageText = getString(messageObj);

    % Create and throw exception
    exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(component, mnemonicField, messageText);
    throw(exceptionObject);
end

end