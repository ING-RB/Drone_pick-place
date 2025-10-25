function addAndExcludeFromSavePath(foldersArray)
% addAndExcludeFromSavePath Add folders to path and excluded list for savepath

% Copyright 2023 The MathWorks, Inc.
if ispc
    pathFolders = strsplit(foldersArray, ';');
else
    pathFolders = strsplit(foldersArray, ':');
end
    for folder = pathFolders 
        if ~strcmp(folder,'')
            matlab.internal.path.ExcludedPathStore.addToCurrentExcludeList(folder);
        end
    end
    addpath(foldersArray, '-end');
end
