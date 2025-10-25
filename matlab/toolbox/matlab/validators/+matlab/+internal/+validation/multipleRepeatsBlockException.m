function E = multipleRepeatsBlockException(functionName)
%

%   Copyright 2019-2020 The MathWorks, Inc.

    E = matlab.internal.validation.DefinitionException(...
        functionName,...
        'MATLAB:functionValidation:MultipleRepeatingBlocks');
end

