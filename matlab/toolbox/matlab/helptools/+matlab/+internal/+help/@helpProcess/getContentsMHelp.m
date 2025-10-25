function dirHelpStr = getContentsMHelp(hp, folderInfo, justH1)
    dirHelpStr = matlab.internal.help.folder.getContentsMHelp(folderInfo, justH1);
    if dirHelpStr ~= "" && hp.wantHyperlinks
        qualifyingPath = matlab.lang.internal.introspective.minimizePath(folderInfo.path, true);
        dirHelpStr = hp.linkContents(dirHelpStr, QualifyingPath=qualifyingPath);
    end
end

%   Copyright 2024 The MathWorks, Inc.