function populateFoldersFromResolvedPaths(ds, location, resolvedSubfolders, ...
        resolvedFilenames)
%populateFoldersFromResolvedPaths is an internal function for
%   populating the Folders property from resolved locations that are
%   provided as input to datastores.
%
%   The location input must be either:
%     - A character vector listing a valid folder, file, or
%       wildcard name.
%     - A string array or cell array of character vectors 
%       containing valid folder, file, or wildcard names.
%     - A matlab.io.datastore.DsFileSet object.
%
%   If a list of resolved folders or resolved files is already
%   available, the second and third inputs can be provided as
%   input to this method to optimize the Folders calculation.
%
%   resolvedSubfolders and resolvedFilenames must both be
%   string arrays or cell arrays of character vectors. The paths
%   contained in these inputs must be fully-resolved, i.e. they must be
%   fully qualified absolute paths to local filesystems or remote URLs.
%
%   The location input must be a list of valid files, folders, or
%   wildcards on the system.
%
%   See also: matlab.io.datastore.FoldersPropertyProvider

%   Copyright 2019-2024 The MathWorks, Inc.

    % Add some folder-calculation utilities to the namespace.
    import matlab.io.datastore.internal.folders.*;
    import matlab.io.datastore.internal.normalizeToCellstrColumnVector;

    % Exit early if a DsFileSet is provided as input by copying its
    % Folders property.
    if isa(location, "matlab.io.datastore.DsFileSet") || isa(location, "matlab.io.datastore.FileSet")
        % DsFileSet only contains this property from MATLAB R2020a
        % onwards.
        if isprop(location, "Folders")
            ds.Folders = location.Folders;
        end
        return;
    end

    location = normalizeToCellstrColumnVector(location);
    if ~iscellstr(location) %#ok<ISCLSTR>
        % If location isn't a cellstr yet, exit early without
        % setting the Folders property. This helps support the
        % Hadoop struct that may be passed in as the location
        % input.
        return;
    end

    % Some input checking for convenience.
    hasResolvedSubfolders = true;
    if nargin < 3 || isempty(resolvedSubfolders)
        hasResolvedSubfolders = false;
    end

    hasResolvedFilenames = true;
    if nargin < 4 || isempty(resolvedFilenames)
        hasResolvedFilenames = false;
    end

    % Optimization for pure lists of files (also fits folders with one
    % matching file, or wildcards with one matching file).
    mappedResolvedSubfolders = hasResolvedSubfolders && (numel(resolvedSubfolders) == numel(location));
    mappedResolvedFilenames = hasResolvedFilenames && (numel(resolvedFilenames) == numel(location));
    if mappedResolvedFilenames
        resolvedSubfolders = listParentFolderNames(resolvedFilenames);
        ds.Folders = unique(adjacentSubstringFolderComputation(location, resolvedSubfolders), "stable");
        ds.Folders = removeHttpsPathsFromFolders(ds.Folders);
        return;
    elseif mappedResolvedSubfolders
        ds.Folders = unique(adjacentSubstringFolderComputation(location, resolvedSubfolders), "stable");
        ds.Folders = removeHttpsPathsFromFolders(ds.Folders);
        return;
    end

    % If the resolvedSubfolders input is provided, use it to populate the
    % Subfolders property.
    if hasResolvedSubfolders
        resolvedSubfolders = normalizeToCellstrColumnVector(resolvedSubfolders);
        resolvedSubfolders = removeTrailingSlash(resolvedSubfolders);
        resolvedSubfolders = unique(resolvedSubfolders, "stable");
    end

    % If no locations, store that and exit early.
    if isempty(location)
        ds.Folders = location;
        return;
    end
    
    % If all location input values are valid folder names, use those
    % names and exit early.
    folderMask = isfolder(location);
    if all(folderMask)
        % Make all folder names absolute paths and remove trailing slashes.
        location = absolutizeFolderNames(location);

        % Make values in the input unique. The Folders property will
        % not list any duplicate folder names.
        location = unique(location, "stable");
        ds.Folders = removeHttpsPathsFromFolders(location);
        return;
    end

    % If all inputs are valid file/wildcard names, optimize the
    % Folders calculation by using a pre-allocated list of
    % resolvedSubfolders or resolvedFilenames.
    fileMask = isfile(location);
    wildcardMask = iswildcard(location);
    if all(fileMask | wildcardMask)
        if hasResolvedSubfolders
            % The resolved subfolders can contain a lot of repeated
            % folder names if the location contains a lot of files
            % from a few folders. Therefore make the list unique
            % before checking for folder existence.
            ds.Folders = removeHttpsPathsFromFolders(resolvedSubfolders);
            return;
        end

        if hasResolvedFilenames
            % Compute the parent folder names of each of these
            % files using a vectorized fileparts implementation.
            resolvedFilenames = normalizeToCellstrColumnVector(resolvedFilenames);
            folders = listParentFolderNames(resolvedFilenames);
            folders = removeTrailingSlash(folders);
            folders = unique(folders, "stable");
            ds.Folders = removeHttpsPathsFromFolders(folders);
            return;
        end
    end

    % If none of the optimizations apply, iterate over the location
    % inputs and populate the Folders property.
    ds.Folders = removeHttpsPathsFromFolders(computeFoldersFromLocation(location, ...
        folderMask, fileMask, wildcardMask));
end

function folders = removeHttpsPathsFromFolders(folders)
    folders(startsWith(folders, ["http://", "https://"])) = [];
end