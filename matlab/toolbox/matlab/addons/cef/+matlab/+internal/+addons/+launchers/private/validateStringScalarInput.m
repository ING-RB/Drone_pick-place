% Copyright 2019 The MathWorks Inc.
function validateStringScalarInput(functionName, paramName, paramValue)
    try
    narginchk(3, 3);
    validateattributes(paramValue, {'char','string'}, {'nonempty', 'scalartext'}, functionName, paramName)
    catch ME
        throwAsCaller(ME);
    end
end