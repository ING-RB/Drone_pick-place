function helpFunction = getHelpFunctionForExtension(extension)
%

%   Copyright 2013-2024 The MathWorks, Inc.

    helpFunction = which(append('help', extension, 'File'));
    if helpFunction ~= ""
        [~, helpFunction] = fileparts(helpFunction);
        helpFunction = append('help.', helpFunction);
    end
end
