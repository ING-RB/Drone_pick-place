function createFolders(ds, outputLocation, topLevelFolders, folderLayout)
%createFolders    Generates all the necessary subfolders in the output location
%   when FolderLayout is set to "duplicate". 
%
%   Ensures that a folder at the output location is generated when FolderLayout
%   is set to "flatten".

%   Copyright 2023 The MathWorks, Inc.

    % For convenience, handle the empty Folders property case similarly to
    % the FolderLayout: flatten case.
    if folderLayout == "flatten" || isempty(topLevelFolders)
        % No need to add any folder structure, just create the output
        % folder and exit early.
        createFolderIfNonExistent(outputLocation);
        return;
    end

    % Get a unique list of the deepest-level subfolder names to generate in the
    % output location.
    inputSubfolders = listInputSubfolders(ds);

    % Map the input subfolders to corresponding output subfolders in the output
    % location. Use the top-level folders to limit the structure that is generated
    % in the output location.
    createOutputSubfolders(inputSubfolders, outputLocation, topLevelFolders);
end

function createOutputSubfolders(inputSubfolders, outputLocation, topLevelFolders)
%createOutputSubfolders   a utility to create a list of output subfolders based
%   on a list of input subfolders. The list of top-level folders is used as a guide
%   to trim the level of folder structure replication in the output location.

    import matlab.io.datastore.internal.write.utility.makeOutputName;
    import matlab.io.datastore.internal.folders.cloudAwareFilesep;

    % Find the appropriate file separator for the output location.
    outputFileSeparator = char(cloudAwareFilesep(outputLocation));

    % Every unique subfolder in the input location should result in a
    % corresponding subfolder in the output location.
    for index = 1:numel(inputSubfolders)
        % Convert to string for compatibility with makeOutputName.
        inputSubfolder = string(inputSubfolders(index));

        % Map the input subfolder name to an output subfolder name using a
        % top-level folder that preserves the most folder structure.
        outputSubfolder = makeOutputName(inputSubfolder, outputLocation, ...
            topLevelFolders, "duplicate", "", "", "", outputFileSeparator, "");

        % Create a new folder if it doesn't already exist in the
        % output location.
        createFolderIfNonExistent(outputSubfolder);
    end
end

function createFolderIfNonExistent(folder)
%createFolderIfNonExistent   creates a folder in the output location
%   after checking that it doesn't already exist.
    % Folders are created on the fly for MS Azure.
    if ~exist(folder, "dir") && ~startsWith(folder, ["wasbs://", "wasb://"])
        mkdir(folder);
    end
end

function subfolders = listInputSubfolders(ds)
    import matlab.io.datastore.internal.folders.listParentFolderNames;
    import matlab.io.datastore.internal.folders.addTrailingSlash;

    files = ds.getFiles();

    % Normalize to a column cell vector of character arrays.
    files = matlab.io.datastore.internal.normalizeToCellstrColumnVector(files);

    % Get the parent folders of these files and clean the list up for
    % efficient processing.
    subfolders = listParentFolderNames(files);
    subfolders = unique(subfolders);
    subfolders = addTrailingSlash(subfolders);
end
