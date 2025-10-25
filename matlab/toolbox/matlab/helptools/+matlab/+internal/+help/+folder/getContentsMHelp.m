function dirHelpStr = getContentsMHelp(folderInfo, justH1)
    dirHelpStr = matlab.lang.internal.introspective.callHelpFunction(@help.mFile, fullfile(folderInfo.path, 'Contents.m'), justH1);
end

%   Copyright 2024 The MathWorks, Inc.