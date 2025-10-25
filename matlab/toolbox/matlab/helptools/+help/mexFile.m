function helpStr = mexFile(fullPath)
%help.mexFile Provides the help text for MEX files.

%   Copyright 2018-2023 The MathWorks, Inc.

    [~, fileName, ~] = matlab.lang.internal.introspective.splitFilePath(fullPath);
    [~, mexName] = fileparts(fileName);
    
    helpStr =  getString(message('MATLAB:help:DefaultMexHelp', mexName));
end
