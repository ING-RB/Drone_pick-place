function newColor = validateColorSpec(component, color)
% Validates that COLOR is a valid Colorspec
%
%  component - handle to component model throwing the error
%
% - RGB Triple
% - One of 16 magic color strings (the short or long versions)

%convert string to char
color = convertStringsToChars(color);

if(ischar(color))
    % Magic String Case

    try

        newColor = hgcastvalue('matlab.graphics.datatype.RGBColor', color);

    catch  ME %#ok<NASGU>
        messageObj = message('MATLAB:ui:components:InvalidColorString');

        % MnemonicField is last section of error id
        mnemonicField = 'InvalidColorString';

        % Use string from object
        messageText = getString(messageObj);

        % Create and throw exception
        exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(component, mnemonicField, messageText);
        throw(exceptionObject);

    end
else
    % RGB Matrix Case

    % Verify that its 1x3 each element between [0 ... 1]
    validateattributes(color, ...
        {'numeric'}, ...
        {'size', [1,3], '>=', 0, '<=', 1});

    newColor = color;
end

end