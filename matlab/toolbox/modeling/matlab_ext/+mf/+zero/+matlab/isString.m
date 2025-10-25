% Copyright 2024 The MathWorks, Inc.
% The FQN of the function is mf.zero.matlab.isString
% THIS FILE WILL NOT BE REGENERATED
function result = isString(value)
    arguments(Output)
        result logical
    end
    try
        % Attempt to convert the input variable to a string
        str = string(value);
        result = true;
    catch
        % If an error occurs during conversion, it is not convertible
        result = false;
    end
end
