function E = requiredAfterOptionalException(functionName)
%

%   Copyright 2019-2020 The MathWorks, Inc.

    E = matlab.internal.validation.DefinitionException(...
        functionName,...
        'MATLAB:functionValidation:RequiredAfterOptional');
end
