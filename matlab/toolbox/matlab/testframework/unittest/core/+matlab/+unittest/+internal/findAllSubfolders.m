function allFolders = findAllSubfolders(folders, folderSpec)
% Given a list of folders, the function returns the same list of folders
% plus all of their subfolders that satisfy the provided folder
% specification function.

%   Copyright 2022 The MathWorks, Inc.

arguments
    folders
    folderSpec function_handle = @(aFolderList)matlab.unittest.internal.allFolderSpec(aFolderList)
end
import matlab.unittest.internal.findAllSubcontent
allFolders = findAllSubcontent(folders, @(folder)getSubfolders(folder, folderSpec));
end

function subfolders = getSubfolders(folder, folderSpec)
folderInfo = dir(folder);
subfolders = {folderInfo([folderInfo.isdir]).name};

% Always remove relative directories
subfolders(subfolders == "." | subfolders == "..") = [];

% Apply any folder specifications to filter further
folderMatchesSpec = folderSpec(subfolders);
subfolders = subfolders(folderMatchesSpec);
subfolders = fullfile(folder, subfolders);
end
