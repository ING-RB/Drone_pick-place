function linkText = getFoldersLink(hp)
    linkText = '';

    if hp.suppressedFolderName ~= ""
        folderName = hp.suppressedFolderName;
        linkID = 'MATLAB:helpUtils:displayHelp:FoldersNamed';
        linkFcn = 'matlab.internal.help.folder.displayList';
        linkText = hp.getOtherNamesLink(folderName, folderName, linkID, linkFcn);
    end
end

%   Copyright 2020-2024 The MathWorks, Inc.
