function E = nameSourceHasDefaultValueException(functionName)
%

%   Copyright 2019-2020 The MathWorks, Inc.

    E = matlab.internal.validation.DefinitionException(...
        functionName,...
        'MATLAB:functionValidation:ClassArgumentHasDefaultValue');
end
