classdef (Hidden, Abstract) CrossPlatformFileRoots < handle
%CROSSPLATFORMROOTS Support for cross platform roots for files.
%   This mixin class can be added to all file based datastores when
%   they need to support cross platform roots for files.

%   Copyright 2017-2022 The MathWorks, Inc.

    properties (Access = protected)
        %CREATEDONPC We want to use this to replace only for slashes
        CreatedOnPC = ispc;
        %MULTIPLEFILESEPS If set to true, the files have multiple file seps on various files on PC.
        MultipleFileSeps = false;
        %BACKSLASHINDICES Can be 'all' or empty or logical indices for to replace on PC.
        BackSlashIndices = [];
        SetFromLoadObj = false;
    end

    properties
        %ALTERNATEFILESYSTEMROOTS Alternate file system roots for the files.
        %   Alternate file system root paths for the files provided in the
        %   LOCATION argument. ALTROOTS contains one or more rows, where each row
        %   specifies a set of equivalent root paths. Values for ALTROOTS can be one
        %   of these:
        %
        %      - A string row vector of root paths, such as
        %                 ["Z:\datasets", "/mynetwork/datasets"]
        %
        %      - A cell array of root paths, where each row of the cell array can be
        %        specified as string row vector or a cell array of character vectors,
        %        such as
        %                 {["Z:\datasets", "/mynetwork/datasets"];...
        %                  ["Y:\datasets", "/mynetwork2/datasets","S:\datasets"]}
        %        or
        %                 {{'Z:\datasets','/mynetwork/datasets'};...
        %                  {'Y:\datasets', '/mynetwork2/datasets','S:\datasets'}}
        AlternateFileSystemRoots = {};
    end

    properties (Constant, Access = protected)
        ALTERNATE_FILESYSTEM_ROOTS_NV_NAME = 'AlternateFileSystemRoots';
        DEFAULT_ALTERNATE_FILESYSTEM_ROOTS = {};
        CLOUD_PATH_IRI_SCHEMES = {'s3:', 'wasb:', 'wasbs:', 'hdfs:', 'cloudmock:'};
    end

    methods (Abstract, Access = protected)
        % Subclasses need to implement whether files are empty or not.
        tf = isEmptyFiles(ds);

        %SETTRANSFORMEDFILES Subclasses need to implement how to set the transformed files.
        %   In order to support AlternateFileSystemRoots, which can change the roots
        %   of the file paths in the datastore, we need to set the changed file paths
        %   on to the subclasses.
        setTransformedFiles(ds, files);

        %GETFILESFORTRANSFORM Subclasses need to implement how to get the files to be transformed.
        %   In order to support AlternateFileSystemRoots, which can change the roots
        %   of the file paths in the datastore, we need to get the file paths
        %   from the subclasses that could be changed based upon AlternateFileSytemRoots.
        files = getFilesForTransform(ds);
    end
    
    methods (Access = protected)
        %transformFolders is a helper method for updating the Folders
        %   property after loading a datastore.
        %   Neither oldPaths nor newPaths should have a trailing folder
        %   separator here.
        function transformFolders(ds, oldPaths, newPaths)
            % Only update if "Folders" is truly a property on this
            % datastore.
            if isprop(ds, "Folders")
                % Update only folders that correspond to the old path.
                nonExistentFolders = startsWith(ds.Folders, oldPaths);
                if any(nonExistentFolders)
                    % Provide a warning/error if these paths can be found on the
                    % remote system.
                    checkForNonExistingCloudPaths(ds, ds.Folders(nonExistentFolders), oldPaths);
                    
                    % Replace the old path with the new path and set on the
                    % Folders property.
                    ds.Folders(nonExistentFolders) = ...
                        iReplaceNonExisting(ds.Folders(nonExistentFolders), oldPaths, newPaths);
                end
            end
        end
    end

    methods (Access = private)
        function checkForNonExistingCloudPaths(~, inputFilesClaimedNonExisting, nonExistingAltPaths)
            %CHECKFORNONEXISTINGCLOUDPATHS This helper if claimed non-existing input files are actually
            % non existent. We already know non existing alternate roots do not exist at this point.
            import matlab.io.datastore.mixin.CrossPlatformFileRoots;
            cloudNonExisting = startsWith(nonExistingAltPaths, CrossPlatformFileRoots.CLOUD_PATH_IRI_SCHEMES);
            if ~any(cloudNonExisting)
                return;
            end
            altPaths = nonExistingAltPaths(cloudNonExisting);
            for ii = 1:numel(altPaths)
                nonExistingFiles = inputFilesClaimedNonExisting(startsWith(inputFilesClaimedNonExisting, altPaths{ii}));

                if ~isempty(nonExistingFiles) && any(matlab.io.internal.vfs.validators.isAbsoluteFolder(nonExistingFiles(1)))
                    % Cloud alternate root does not exist, but input files exist.
                    error(message('MATLAB:datastoreio:filebaseddatastore:partialPathNonexistent', ...
                        altPaths{ii} ...
                        ));
                end
            end
        end
    end

    methods (Access = protected)

        %DEFAULTSETFROMLOADOBJ Set SetFromLoadObj property to default 'false' value.
        function defaultSetFromLoadObj(ds)
            ds.SetFromLoadObj = false;
        end

        %ISSETFROMLOADOBJ Check if SetFromLoadObj property is true.
        function tf = isSetFromLoadObj(ds)
            tf = ds.SetFromLoadObj == true;
        end

        %UPDATEFILESFROMPATHMAP Update the Files property or an equivalent, based on the AlternateFileSystemRoots values.
        function basicFolders = updateFilesFromPathMap(ds, aFolders)
            import matlab.io.datastore.mixin.CrossPlatformFileRoots;
            basicFolders = aFolders;
            if isempty(aFolders)
                return;
            end
            if iscellstr(aFolders) %#ok<ISCLSTR>
                aFolders = {aFolders};
            end
            numFolders = numel(aFolders);
            nonExisting = false;
            inFiles = getFilesForTransform(ds);            
            existing = false(numFolders, 1);
            for ii = 1:numFolders
                aPath = aFolders{ii};
                [isAbsOrFile,cloudPaths] = iLookAtNonCloud(aPath, CrossPlatformFileRoots.CLOUD_PATH_IRI_SCHEMES);
                if any(isAbsOrFile(:,1))
                    relativePaths = join(aPath(isAbsOrFile(:,1)), ', ');
                    error(message('MATLAB:datastoreio:filebaseddatastore:relativePathsUnsupported', relativePaths{1}));
                end
                isAbsOrFile = iLookAtCloudIfNecessary(isAbsOrFile, inFiles, aPath, cloudPaths);
                ex = isAbsOrFile(:,2);
                existing(ii) = any(ex);
                if ~existing(ii)
                    continue;
                end
                if all(ex)
                    continue;
                end
                rep = aPath(ex);
                if numel(rep) > 1
                    rep = rep(1);
                end
                nonExistingPaths = iAddTrailingSep(aPath(~ex));
                nonExisting = startsWith(inFiles, nonExistingPaths);
                if any(nonExisting)
                    checkForNonExistingCloudPaths(ds, inFiles(nonExisting), aPath(~ex));
                    inFiles(nonExisting) = iReplaceNonExisting(inFiles(nonExisting), aPath(~ex), rep);
                    % Update the Folders property too.
                    ds.transformFolders(aPath(~ex), rep);
                end
            end

            if isprop(ds, "Folders")
                dsFolders = ds.Folders;
            else
                dsFolders = [];
            end
            if ~any(existing)
                % canonicalize roots as a last attempt
                [noValidPaths, basicFolders] = canonicalizeFolderPaths(dsFolders, basicFolders, inFiles);
                if noValidPaths
                    noEntryRoots = join(iCatAllAltPaths(aFolders), ', ');
                    error(message('MATLAB:datastoreio:filebaseddatastore:noAlternateFileSystemRootsExist', noEntryRoots{1}));
                end
            end

            allPaths = iCatAllAltPaths(aFolders);
            if ~any(startsWith(inFiles, allPaths))
                % canonicalize roots as a last attempt
                [noValidPaths, basicFolders] = canonicalizeFolderPaths(dsFolders, basicFolders, inFiles);

                % For empty location input, AlternateFileSystemRoots should
                % also be empty.
                if (isempty(inFiles) && ~isempty(aFolders))
                    error(message("MATLAB:datastoreio:filebaseddatastore:nonEmptyAlternateFileSystemRoots"));
                end

                if noValidPaths
                    noEntryRoots = join(allPaths, ', ');
                    error(message('MATLAB:datastoreio:filebaseddatastore:noEntryMatchesFiles', noEntryRoots{1}));
                end
            end

            if any(nonExisting)
                ds.setTransformedFiles(inFiles);
            end
        end

        %REPLACEUNCPATHS If AlternateFileSystemRoots is empty, relace the UNC paths appropriate
        % to a platform.
        function replaceUNCPaths(ds)
            if isempty(ds.AlternateFileSystemRoots)
                files = getFilesForTransform(ds);
                if ispc
                    startsWithChar = '/';
                    repThis= '/';
                    repBetFcn =@(x)replaceBetween(x,1,1,'\\');
                else
                    startsWithChar = '\\';
                    repThis= '\';
                    repBetFcn =@(x)replaceBetween(x,1,2,'/');
                end
                uncPaths = startsWith(files, startsWithChar);
                if any(uncPaths)
                    files(uncPaths) = replace(files(uncPaths), repThis, filesep);
                    files(uncPaths) = repBetFcn(files(uncPaths));
                    ds.setTransformedFiles(files);
                end
            end
        end
    end

    methods
        % Setter for AlternateFileSystemRoots
        function set.AlternateFileSystemRoots(ds, aFolders)
            try
                if ~isSetFromLoadObj(ds)
                    aFolders = convertStringsToChars(aFolders);
                    aFolders = iValidateAlternateFileSystemRoots(aFolders);
                    try
                        aFolders = updateFilesFromPathMap(ds, aFolders);
                    catch ME
                        if strcmp(ME.identifier, "MATLAB:virtualfileio:path:invalidFilesInput")
                            % throw better error message
                            error(message("MATLAB:datastoreio:filebaseddatastore:invalidAlternateFileSystemRoots"));
                        else
                            throw(ME);
                        end
                    end
                else
                    % On loadobj we want to throw the exception (that converts to warning)
                    % and also not lose the property value.
                    try
                        aFolders = updateFilesFromPathMap(ds, aFolders);
                    catch ME
                        onState = warning('off', 'backtrace');
                        c = onCleanup(@() warning(onState));
                        warning(ME.identifier, '%s', ME.message);
                    end
                end
                ds.AlternateFileSystemRoots = aFolders;
                if ~isSetFromLoadObj(ds)
                    reset(ds);
                end
            catch e
                throw(e)
            end
        end
    end
end

function apaths = iValidateAlternateFileSystemRoots(apaths)
    if iscell(apaths) && isempty(apaths)
        return;
    end
    isCellPaths = iscell(apaths);
    isCharOrNotCellPaths = ischar(apaths) || ~isCellPaths;
    isCellStrAndSinglePath = iscellstr(apaths) && numel(apaths) < 2; %#ok<ISCLSTR>
    isCellStrAndNotStringOrCharOrCell = isCellPaths && any(~cellfun(@(x) isStringPathVector(x) || ...
        isCharPath(x) || isCellCharPath(x), apaths), "all");

    if isCharOrNotCellPaths || isCellStrAndSinglePath ...
        || (isCellPaths && isCellStrAndNotStringOrCharOrCell)
        error(message('MATLAB:datastoreio:filebaseddatastore:invalidAlternateFileSystemRoots'));
    end
    if iscell(apaths) && isstring(apaths{1})
        apaths = cellfun(@cellstr, apaths, 'UniformOutput', false);
    end
    catpaths = iCatAllAltPaths(apaths);
    indices = 1:numel(catpaths);
    arrayfun(@(x,y)iValidateStartsWithPath(x, catpaths, y), catpaths, indices(:));
end

function iValidateStartsWithPath(pth, allPaths, i)
    allPaths(i) = [];
    sep = "\";
    if ~contains(pth, sep)
        sep = "/";
    end
    sw = startsWith(allPaths + sep, pth + sep);
    if any(sw)
        swPath = allPaths(sw);
        error(message('MATLAB:datastoreio:filebaseddatastore:ambiguousAlternateFileSystemRoots', pth, swPath(1)));
    end
end

function tf = isCharPath(pth)
    tf = ischar(pth) && isrow(pth) && numel(pth) > 1;
end

function tf = isStringPathVector(pth)
    tf = isstring(pth) && isvector(pth) && numel(pth) > 1 && all(strlength(pth) > 1);
end

function tf = isCellCharPath(pth)
    tf = iscell(pth) && all(cellfun(@isCharPath, pth)) && numel(pth) > 1;
end

function aPath = iRemoveTrailingSep(aPath)
    %IREMOVETRAILINGSEP Removes trailing file separators.
    trailingSep = endsWith(aPath, {'\', '/'});
    if any(trailingSep)
        aPath(trailingSep) = strip(aPath(trailingSep), 'right', '/');
        aPath(trailingSep) = strip(aPath(trailingSep), 'right', '\');
    end
end

function [isAbsOrFile,cloudPaths] = iLookAtNonCloud(aPath, cloudIRISchemes)
    %ILOOKATNONCLOUD We want to look at the non-cloud paths first
    %   The cloud paths take longer to lookup as it stands now.
    %   Look at the non-cloud paths first, if any non-cloud paths exist, then use
    %   them as the chosen alternate path.
    import matlab.io.internal.vfs.validators.isAbsoluteFolder;
    cloudPaths = startsWith(aPath, cloudIRISchemes);
    if any(cloudPaths)
        isAbsOrFile = false(numel(aPath), 2);
        isAbsOrFile(cloudPaths,1) = false;
        isAbsOrFile(~cloudPaths,:) = isAbsoluteFolder(aPath(~cloudPaths));
        if any(isAbsOrFile(:,2))
            return;
        end
        isAbsOrFile(cloudPaths,:) = isAbsoluteFolder(aPath(cloudPaths));
    else
        isAbsOrFile = isAbsoluteFolder(aPath);
    end
    if ~ispc
        % Mark any folder that starts with '~' as relative.
        tildeRelative = startsWith(aPath(isAbsOrFile(:,2)), '~');
        isAbsOrFile(tildeRelative,1) = true;
    end
end

function isAbsOrFile = iLookAtCloudIfNecessary(isAbsOrFile, inFiles, aPath, cloudPaths)
    %ILOOKATCLOUDIFNECESSARY We want to look at the cloud paths only when necessary
    %   Since the cloud paths take longer to lookup as it stands now we look at the
    %   non-cloud paths first. If the input files contain any cloud paths, we want to look
    %   at them for existence.
    import matlab.io.internal.vfs.validators.isAbsoluteFolder;
    if any(cloudPaths)
        cloudPathInFiles = startsWith(inFiles, aPath(cloudPaths));
        if any(cloudPathInFiles)
            cloudInFiles = inFiles(cloudPathInFiles);
            needsLookup = arrayfun(@(x)any(startsWith(cloudInFiles,x)), aPath(cloudPaths));
            if any(needsLookup)
                cloudIndices = find(cloudPaths);
                pathsForLookup = aPath(cloudIndices(needsLookup));
                noTrailingSep = ~endsWith(pathsForLookup, '/');
                % Paths like "hdfs://mycluster:[port#]/myfolder" can be part of the files, but
                % alternate paths like "hdfs://mycluster:[port#]" will not be found by the
                % path lookup api. Adding a trailing sep will make sure these paths exist
                % or not.
                pathsForLookup(noTrailingSep) = strcat(pathsForLookup(noTrailingSep), '/');
                isAbsOrFile(cloudIndices(needsLookup),:) = isAbsoluteFolder(pathsForLookup);
            end
        end
    end
end

function nonExistingInFiles = iReplaceNonExisting(nonExistingInFiles, nonExistingAltPath, replacement)
    nonExistingAltPath = iRemoveTrailingSep(nonExistingAltPath);
    replacement = iRemoveTrailingSep(replacement);
    nonExistingInFiles = replace(nonExistingInFiles, nonExistingAltPath, replacement);
    [fileSeparator, replaceThis]  = iFindFileSeparator(replacement);
    nonExistingInFiles = replace(nonExistingInFiles, replaceThis, fileSeparator);
end

function [fileSeparator, replaceThis]  = iFindFileSeparator(replacement)
    switch class(replacement)
        case 'cell'
            replacement = replacement{1};
        case 'string'
            replacement = char(replacement);
    end
    ind = find(replacement== '/'| replacement== '\', 1, 'first');
    if ~isempty(ind)
        fileSeparator = replacement(ind);
        if fileSeparator == '\'
            replaceThis = '/';
        else
            replaceThis = '\';
        end
        return;
    end
    % Match Windows-Drive-Only paths, like "C:", "d:" or "Z:"
    if ~isempty(regexp(replacement, "^([A-Z]|[a-z]:)$", 'once'))
        fileSeparator = '\';
        replaceThis = '/';
        return;
    end
    fileSeparator = '/';
    replaceThis = '\';
end

function altPathsInp = iAddTrailingSep(altPathsInp)
    %IADDTRAILINGSEP This adds trailing separator to the alternate paths provided
    %   Add forward/back slashes to the respective paths. If no slashes are found in
    %   some paths add
    %     - back slash only for Windows-Drive-Only paths, like "C:", "d:" or "Z:"
    %     - otherwise add forward slash.
    %   If a trailing separator already exists, do nothing.
    trailingSep = endsWith(altPathsInp, {'\', '/'});
    if all(trailingSep)
        return;
    end
    altPaths = altPathsInp(~trailingSep);

    altPaths = string(altPaths);
    forwardSlash = contains(altPaths, '/');
    backSlash = contains(altPaths, '\');
    altPaths(forwardSlash) = altPaths(forwardSlash) + '/';
    altPaths(backSlash) = altPaths(backSlash) + '\';
    noSlashes = ~(forwardSlash | backSlash);
    if any(noSlashes)
        noSlashPaths = altPaths(noSlashes);
        % Match Windows-Drive-Only paths, like "C:", "d:" or "Z:"
        winDrivePaths = regexp(noSlashPaths, "^([A-Z]|[a-z]:)$", 'forcecelloutput');
        winDrivePaths = ~cellfun(@isempty, winDrivePaths);
        anyWinDrivePaths = any(winDrivePaths);
        anyNonWinDrivePaths = any(~winDrivePaths);
        if anyWinDrivePaths
            noSlashPaths(winDrivePaths) = noSlashPaths(winDrivePaths) + '\';
        end
        if anyNonWinDrivePaths
            noSlashPaths(~winDrivePaths) = noSlashPaths(~winDrivePaths) + '/';
        end
        if anyWinDrivePaths || anyNonWinDrivePaths
            altPaths(noSlashes) = noSlashPaths;
        end
    end
    altPaths = cellstr(altPaths);

    % update just the paths without trailing separator.
    altPathsInp(~trailingSep) = altPaths;
end

function catpaths = iCatAllAltPaths(catpaths)
    if ~iscellstr(catpaths) %#ok<ISCLSTR>
        numPaths = numel(catpaths);
        combpaths = cell(numPaths, 1);
        for i = 1:numPaths
            c = catpaths{i};
            combpaths{i} = c(:);
        end
        catpaths = vertcat(combpaths{:});
    end
    catpaths = string(catpaths(:));
end

function [noValidPaths, aFolders] = canonicalizeFolderPaths(dsFolders, aFolders, dsFiles)
    noValidPaths = true;
    % loop over the AlternateFileSystemRoots provided as input
    for index = 1 : numel(aFolders)
        thisLineRoots = aFolders{index};
        % handle cell input (multi-line case) vs char input (single-line case)
        if iscell(thisLineRoots)
            sizeOfLine = numel(thisLineRoots);
        else
            sizeOfLine = 1;
        end

        % loop over and canonicalize indidivual roots specified together to
        % determine whether any valid roots exist
        for jj = 1 : sizeOfLine
            % handle char vs cell case (multi-line vs single-line)
            if iscell(thisLineRoots)
                tempLoc = dir(thisLineRoots{index});
            else
                tempLoc = dir(thisLineRoots);
            end

            if ~isempty(tempLoc)
                % get the folder name from the first file returned from dir
                tempLoc = tempLoc(1).folder;
                % compare to either the Folders propety of the datastore
                % (if existing), otherwise compare to the parent of the
                % files within the datastore
                if (~isempty(dsFolders) && any(strcmp(tempLoc, dsFolders))) || ...
                        (isempty(dsFolders) && any(startsWith(dsFiles, tempLoc)))
                    noValidPaths = false;
                    % valid root path is found, update the
                    % AlternateFileSystemRoots values
                    if iscell(thisLineRoots)
                        aFolders{index}{jj} = tempLoc;
                    else
                        aFolders{index} = tempLoc;
                    end
                    break;
                end
            end
        end
    end
end
