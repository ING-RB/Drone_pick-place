function folders = removeFoldersWithoutFiles(folders, files)
%removeFoldersWithoutFiles   filters the folders list by removing any
%   folders that do not contain at least one relevant file.
%
%   Both the files and folders input here must be fully-resolved cell
%   arrays of character vectors.

%   Copyright 2019 The MathWorks, Inc.

    % Add a trailing slash to make sure that full folder names are matched.
    % This ensures that '/dat' doesn't match '/data/a.txt', since it will
    % be treated as '/dat/'.
    folders = matlab.io.datastore.internal.folders.addTrailingSlash(folders);

    % Call into a utility function to find the folder names that contain
    % valid files.
    containsValidFiles = findValidFolders(folders, files);

    % Trim the Folders property using the populated bitmap.
    folders = folders(containsValidFiles);
    
    % Remove trailing slashes again.
    folders = matlab.io.datastore.internal.folders.removeTrailingSlash(folders);
end

function containsValidFiles = findValidFolders(folders, files)
    % Allocate a logical array to track whether there is at least one file
    % provided for a folder value.
    containsValidFiles = false(numel(folders), 1);
    
    % Allocate another logical array to track whether there is at least one
    % folder parenting a file.
    hasParentFolder = false(numel(files), 1);

    for index = 1:numel(folders)
        filesWithParentsMask = startsWith(files, folders{index});

        % Store whether this particular folder has at least one valid
        % file.
        containsValidFiles(index) = any(filesWithParentsMask);

        % Accumulate the state of having at least one parent folder.
        hasParentFolder = hasParentFolder | filesWithParentsMask;
    end
    
    % Clear the Folders property if we find that any file doesn't have a
    % parent folder. This should only occur after set.Files.
    if any(~hasParentFolder)
        containsValidFiles = false(numel(folders), 1);
    end
end