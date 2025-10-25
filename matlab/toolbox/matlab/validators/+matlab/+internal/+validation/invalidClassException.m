function E = invalidClassException(functionName, argumentPosition, argumentName, ...
        className, ~, ~, inputOrOutput)
%

%   Copyright 2019-2024 The MathWorks, Inc.

if nargin ~=7
    inputOrOutput = "input";
end

if exist(className, 'class') == 8
    E = matlab.internal.validation.IncorrectClassException(functionName, 'MATLAB:functionValidation:UnsupportedClassForValidation', className, inputOrOutput);
else
    E = matlab.internal.validation.IncorrectClassException(functionName, 'MATLAB:functionValidation:NotAClass', className, inputOrOutput);
end

end
