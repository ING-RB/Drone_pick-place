function helpStr = callHelpFunction(helpFunction, fullPath, justH1)
%

%   Copyright 2013-2024 The MathWorks, Inc.

    [filePath, fileName, localFunction] = matlab.lang.internal.introspective.splitFilePath(fullPath);
    
    helpStr = getHelpTextFromFile(helpFunction, fullfile(filePath, 'en', fileName), localFunction, justH1);
    
    if helpStr == ""
        helpStr = getHelpTextFromFile(helpFunction, fullfile(filePath, fileName), localFunction, justH1);
    end
end

function helpStr = getHelpTextFromFile(helpFunction, helpFile, localFunction, justH1)

    helpStr = '';

    try %#ok<TRYNC>
        if isfile(helpFile)
            if nargin(helpFunction) == 1
                helpStr = feval(helpFunction, append(helpFile, localFunction));
                if justH1
                    helpStr = matlab.lang.internal.introspective.containers.extractH1Line(helpStr);
                end
            else
                helpStr = feval(helpFunction, append(helpFile, localFunction), justH1);
            end
            if ~ischar(helpStr)
                helpStr = '';
            end
        end
    end
end
    
