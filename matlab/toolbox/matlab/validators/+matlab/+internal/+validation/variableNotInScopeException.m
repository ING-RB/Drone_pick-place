function E = variableNotInScopeException(functionName, argumentName)
%

%   Copyright 2019-2020 The MathWorks, Inc.

        E = matlab.internal.validation.DefinitionException(...
        functionName,...
        'MATLAB:functionValidation:ArgumentNotInScope',...
        argumentName);
end
