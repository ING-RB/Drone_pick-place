function [helpFunction, targetExtension] = getHelpFunction(fullPath)
%

%   Copyright 2015-2023 The MathWorks, Inc.

    [~, ~, targetExtension] = fileparts(fullPath);
    if targetExtension == ""
        helpFunction = '';
    else
        lowerExt = lower(extractAfter(targetExtension, 1));
        if lowerExt == "m" || lowerExt == "p"
            helpFunction = 'help.mFile';
        elseif strcmp(lowerExt, mexext)
            helpFunction = 'help.mexFile';
        else
            helpFunction = matlab.lang.internal.introspective.getHelpFunctionForExtension(targetExtension);
        end
    end
end

