function E = duplicateNameStructException(functionName, structName)
%

%   Copyright 2019-2020 The MathWorks, Inc.

E = matlab.internal.validation.DefinitionException(functionName, 'MATLAB:functionValidation:DuplicateNameStruct', structName);
end
