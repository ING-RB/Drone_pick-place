% Copyright 2024 The MathWorks, Inc.
% The FQN of the function is mf.zero.matlab.isStringScalar
% THIS FILE WILL NOT BE REGENERATED
function result = isStringScalar(value)
    arguments(Output)
        result logical
    end
    try
        % Attempt to convert the input variable to a string and check if its scalar
        result = isscalar(string(value));
    catch
        % If an error occurs during conversion, it is not convertible
        result = false;
    end
end
