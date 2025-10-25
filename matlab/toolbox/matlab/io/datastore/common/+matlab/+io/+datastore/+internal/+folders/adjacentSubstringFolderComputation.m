function folders = adjacentSubstringFolderComputation(location, resolvedSubfolders)
%adjacentSubstringFolderComputation   an alternative way of computing the
%   Folders property that prioritizes substring matching in memory, thus
%   avoiding disk access as much as possible. This can be very helpful when
%   working with NFS filesystems and other remote storage providers.
%
%   Still attempts to be O(n) by only performing substring matching on
%   adjacent folder names.
%
%   The location input must be a cellstr. The resolvedSubfolders input
%   must be a cellstr of the same length as location containing
%   fully-resolved folder names.
%
%   The output will be a subset of the input locations that only contain a
%   few top-level folders based on whether they were adjacent in the list
%   or not.

%   Copyright 2019 The MathWorks, Inc.

    % Validate inputs.
    import matlab.io.datastore.internal.normalizeToCellstrColumnVector;
    import matlab.io.datastore.internal.folders.addTrailingSlash;
    import matlab.io.datastore.internal.folders.removeTrailingSlash;
    location = normalizeToCellstrColumnVector(location);
    resolvedSubfolders = normalizeToCellstrColumnVector(resolvedSubfolders);
    resolvedSubfolders = addTrailingSlash(resolvedSubfolders);
    
    % Sort the resolvedSubfolders input to attempt to get similar folder
    % names closer to each other. Order will be preserved by undoing the
    % sort order later.
    [resolvedSubfolders, sortIndices] = sort(resolvedSubfolders);
    location = location(sortIndices); % Apply the sort order to location too.
    
    % The result can be at most a cellstr of the same size as the inputs.
    folders = cell(numel(location), 1);

    % The main loop. Iterate over each folder name, check whether it has
    % the same parent folder as a previous value, and assign a value into
    % the output if necessary.
    previousFolderName = '';
    for index = 1:numel(location)
         isChildOfPreviousFolder = ~isempty(previousFolderName) ...
                                && startsWith(resolvedSubfolders(index), previousFolderName);

        if isChildOfPreviousFolder
            if ~isequal(resolvedSubfolders(index), previousFolderName)
                % Add this path's resolvedSubfolder to the list.
                folders(index) = resolvedSubfolders(index);
            end
        else
            % Find the actual folder value for this location input.
            folders(index) = computeParentFolder(location(index), resolvedSubfolders(index));
            previousFolderName = folders(index);
        end
    end

    % Undo the sort transformation to recover the original location order
    % that was specified by the user.
    folders(sortIndices) = folders;

    % Remove empty folder names and shrink the resulting cellstr.
    emptyValues = cellfun(@isempty, folders);
    folders = folders(~emptyValues);

    folders = removeTrailingSlash(folders);
end

function parentFolder = computeParentFolder(location, resolvedFolder)
%computeParentFolder   Finds the parent folder of a location value,
%   regardless of it being a folder name, file name, or wildcard name.
    import matlab.io.datastore.internal.folders.addTrailingSlash;
    if isfolder(location)
        parentFolder = matlab.io.datastore.internal.folders.absolutizeFolderNames(location);
        % Add a trailing slash to make sure that "/a/ba" doesn't count
        % as a subfolder of "/a/b".
        parentFolder = addTrailingSlash(parentFolder);
    else
        parentFolder = resolvedFolder;
    end
end