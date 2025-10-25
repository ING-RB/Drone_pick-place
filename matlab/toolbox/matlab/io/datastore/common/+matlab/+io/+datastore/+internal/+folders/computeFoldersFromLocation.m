function folders = computeFoldersFromLocation(location, folderMask, ...
    fileMask, wildcardMask)
%computeFoldersFromLocation   computes the folders provided in the
%   input location.
%
%   This is the pessimized stage that occurs if we couldn't exit
%   early by populating the Folders property in an optimized manner. Either:
%     - A mixed list of files and folders is provided. resolvedSubfolders
%         and resolvedFilenames don't guarantee the correct order.
%         Instead we need to iterate through 'location' and
%         correctly assign folders from each location value.
%     - resolvedSubfolders or resolvedFilenames is not provided,
%         so the previous optimizations weren't possible.
%   The files and folders masks computed earlier is re-used here.

%   Copyright 2019 The MathWorks, Inc.

    % Add some folder-calculation utilities to the namespace.
    import matlab.io.datastore.internal.folders.*;
    import matlab.io.datastore.internal.pathLookup;

    % Input normalization.
    if nargin < 2
        folderMask = isfolder(location);
    end
    if nargin < 3
        fileMask = isfile(location);
    end
    if nargin < 4
        wildcardMask = iswildcard(location);
    end

    % Pre-allocate the expected folders. The length of this may 
    % change if wildcard paths are provided in the input.
    folders = cell(numel(location), 1);

    % Store any folder names from the input location
    if any(folderMask)
        folders(folderMask) = absolutizeFolderNames(location(folderMask));
    end

    % Store the parent folders of any filenames from the input
    % location.
    if any(fileMask)
        folders(fileMask) = listParentFolderNames(pathLookup(location(fileMask)));
    end

    % Find the indices of the wildcard values in the input.
    wildcardIndices = find(wildcardMask | ~(fileMask | folderMask));

    % If we have any wildcard paths from the input, iterate over
    % them and add them to the folders variable.
    for index = 1:numel(wildcardIndices)
        % Resolve the filenames using datastore's common 
        % pathlookup workflow.
        filenames = pathLookup(location{wildcardIndices(index)});

        % Store the computed folders from the wildcard in the
        % accumulated variable. Note that this variable now
        % contains nested cell arrays, and is no longer a true cellstr.
        folders{wildcardIndices(index)} = removeTrailingSlash(listParentFolderNames(filenames));
    end

    % If there are any wildcard names, we need to flatten the
    % nested cell array back to a true cellstr.
    if any(wildcardIndices)
        folders = flattenToCellstr(folders);
    end

    % Remove any duplicates from the folders list. 
    folders = unique(folders, "stable");
end

function output = flattenToCellstr(input)
    % Ensure that the output grows in the columnar dimension.
    output = cell(0, 1);
    
    % Iterate over the input values, flatten them, and then append to the
    % output.
    for index = 1:numel(input)
        if isempty(input{index})
            newFolders = {''};
        else
            newFolders = cellstr(input{index});
        end

        % Append all the new folders to the list.
        startIndex = numel(output) + 1;
        endIndex = startIndex + numel(newFolders) - 1;
        output(startIndex:endIndex) = newFolders;
    end
end