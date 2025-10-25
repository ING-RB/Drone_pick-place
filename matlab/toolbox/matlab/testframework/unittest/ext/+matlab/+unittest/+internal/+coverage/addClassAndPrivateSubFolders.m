function allFolders = addClassAndPrivateSubFolders(folders)
% This function is undocumented and may change in a future release.

%  Copyright 2022 The MathWorks, Inc.

import matlab.unittest.internal.classFolderSpec
import matlab.unittest.internal.privateFolderSpec

onlyClassAndPrivate = @(aFolderList)classFolderSpec(aFolderList) | privateFolderSpec(aFolderList);
allFolders = matlab.unittest.internal.findAllSubfolders(folders, onlyClassAndPrivate);
end

