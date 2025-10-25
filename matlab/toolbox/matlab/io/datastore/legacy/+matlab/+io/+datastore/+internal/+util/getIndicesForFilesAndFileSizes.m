function [diffIndexes, currIndexes, files, fileSizes, diffPaths] = getIndicesForFilesAndFileSizes(getFilesFcn, getFileSizesFcn, files)
%GETINDICESFORFILESANDFILESIZES Get diff indices of new files compared to current set of files.
%   Inputs:
%      - getFilesFcn: A function to get the current set of files as a cellstr.
%      - getFileSizesFcn: A function to get the current set of file sizes.
%      - files: New set of files as a cellstr.
%   Outputs:
%      - diffIndexes: A logical array of size of new set of files. This indicates the newly
%                     added compared to the old ones.
%      - currIndexes: A double array of size of old set of files. This indicates the new arrangement
%                     of old files (e.g., if shuffled).
%      - files: New set of files as a cellstr.
%      - fileSizes: New set of file sizes.
%      - diffPaths: equals to files(diffIndexes), but fully resolved.

%   Copyright 2018-2020 The MathWorks, Inc.
    import matlab.io.internal.vfs.validators.validatePaths;
    import matlab.io.datastore.internal.indexOfFirstFolderOrWildCard;
    
    if ischar(files)
        files = {files};
    end
    
    % Ensure that:
    % 1) the given paths are valid strings or cell array of strings
    % 2) any local paths provided in IRI form are converted back to an
    %    absolute local path. This can arise when initializing from a Hadoop
    %    split using locally stored files.
    files = validatePaths(files);
    files = iLocalPathFromIRI(files);
    dsFiles = iLocalPathFromIRI(getFilesFcn());
    
    % get the appended or modified file list
    [sfiles, sdsFiles] = convertCharsToStrings(files, dsFiles);
    [newIndexes, currIndexes] = ismember(sfiles, sdsFiles);

    diffIndexes = ~newIndexes;
    % currIndexes is a double array. Get indexes of current Files property.
    sizes = size(files);
    fileSizes = zeros(sizes);
    currIndexes = currIndexes(currIndexes ~= 0);
    if ~isempty(currIndexes)
        % There's definitely splits for current files
        fileSizes(newIndexes) = getFileSizesFcn(currIndexes);
    end
    diffPaths = files(diffIndexes);
    if ~isempty(diffPaths)
        % get the index of the first string which is a folder or
        % contains a wildcard
        idx = indexOfFirstFolderOrWildCard(diffPaths);

        % error for folder or wild card inputs
        if (-1 ~= idx)
            error(message('MATLAB:datastoreio:filebaseddatastore:nonFilePaths', diffPaths{idx}));
        end
        % resolve only the modified paths
        [diffPaths, diffFileSizes] = matlab.io.datastore.internal.pathLookup(diffPaths, false);
        fileSizes(diffIndexes) = diffFileSizes;
    end
end

function files = iLocalPathFromIRI(files)
    % Convert from IRI to local path *and* colonize input
    files = matlab.io.datastore.internal.localPathFromIRI(files(:));
end