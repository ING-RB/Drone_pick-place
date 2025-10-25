function foldersObj = folderParser(folders, includeSubFolder)
% This function is undocumented and may change in a future release.

%  Copyright 2022 The MathWorks, Inc.

import matlab.unittest.internal.coverage.Folder;
import matlab.unittest.internal.folderResolver;
import matlab.unittest.internal.coverage.addClassAndPrivateSubFolders;

folders = cellfun(@folderResolver, folders, 'UniformOutput',false);

if includeSubFolder
    folders = findAllSubfolders(folders);
end

folders = addClassAndPrivateSubFolders(folders);
foldersObj = Folder(folders);
end

function allFolders = findAllSubfolders(folders)
import matlab.unittest.internal.classFolderSpec
import matlab.unittest.internal.privateFolderSpec
exceptClassAndPrivate = @(aFolderList)~(classFolderSpec(aFolderList) | privateFolderSpec(aFolderList));
allFolders = matlab.unittest.internal.findAllSubfolders(folders, exceptClassAndPrivate);
end