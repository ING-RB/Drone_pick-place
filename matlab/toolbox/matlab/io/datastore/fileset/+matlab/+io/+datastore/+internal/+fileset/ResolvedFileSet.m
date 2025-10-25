classdef (Abstract, Hidden, ...
        AllowedSubclasses = {?matlab.io.datastore.internal.fileset.InMemoryFileSet, ...
                             ?matlab.io.datastore.internal.fileset.CompressedFileSet}) ...
        ResolvedFileSet < matlab.mixin.Copyable ...
                        & matlab.io.datastore.FoldersPropertyProvider
%ResolvedFileSet An in-memory abstract FileSet for collecting files.
%
%   See also datastore, matlab.io.datastore.Partitionable.

%   Copyright 2017-2019 The MathWorks, Inc.

    properties
        %NUMFILES Number of files represented by this file set object.
        NumFiles
        %FILESPLITSIZE Size in bytes to be used to represent a split of a file.
        FileSplitSize
        %NUMBLOCKSREAD Number of files read from the file set object.
        NumBlocksRead
    end

    properties(GetAccess = public, SetAccess = protected)
        %CURRENTFILEINDEX The index of the next file in the file set object.
        CurrentFileIndex (1,1) = 1;
    end

    properties (Access = protected)
        FileSizes (:, 1)
        %ACTUALFILESIZEIFSTRUCT The actual file size if LOCATION provided is a
        % struct containing the fields: FileName, Size and Offset
        % The value is either
        %    - Actual file's size calculated from path lookup,
        %      if the given location is a struct
        %    - double value -1 (DEFAULT_ACTUAL_FILE_SIZE_IF_NOT_STRUCT),
        %      if the given location is not a struct
        %   See also matlab.io.datastore.FileSet.
        ActualFileSizeIfStruct
        CurrentOffset
        CurrentFileName
        StartOffset
        EndOffset
        %HOLDTOPARTITIONINDICES A boolean indicating to hold on to the partition
        % indices during the partition of the fileset object.
        HoldToPartitionIndices = false
        %PARTITIONINDICES A vector of partition indices held by the fileset
        % object during the partition of the fileset object.
        PartitionIndices
        %NUMSPLITS Number of splits contained within this FileSet.
        NumSplits
        %BLOCKSPERFILE cumsum of the splits per file.
        BlocksPerFile = [];
    end

    properties (Constant)
        % If the given location is not a struct, the default value for the property
        % ActualFileSizeIfStruct.
        DEFAULT_ACTUAL_FILE_SIZE_IF_NOT_STRUCT = -1
    end

    methods
        function fs = ResolvedFileSet(nvStruct)
            % Constructor for ResolvedFileSet - an intermediary class
            % between FileSet/DsFileSet/BlockedFileSet and
            % CompressedFileSet/InMemoryFileSet
            fs.FileSizes = nvStruct.FileSizes;
            fs.FileSplitSize = nvStruct.FileSplitSize;
            fs.StartOffset = nvStruct.StartOffset;
            fs.ActualFileSizeIfStruct = nvStruct.ActualFileSizeIfStruct;
            if isempty(nvStruct.Files)
                fs.EndOffset = 0;
            else
                fs.EndOffset = nvStruct.FileSizes(end);
            end
            if ischar(fs.FileSplitSize)
                fs.NumSplits = numel(nvStruct.FileSizes);
            else
                [splits, cumSplits] = splitsWithFileSplitSize(fs);
                if ~splits
                    fs.NumSplits = 0;
                else
                    fs.NumSplits = size(splits,1);
                    fs.BlocksPerFile = cumsum(cumSplits);
                end
            end

            fs.populateFolders(nvStruct);
        end

        function subfs = partition(fs, N, ii)
            %PARTITION Return a partitioned part of the file set.
            %   SUBFS = PARTITION(FS,N,ii) returns a new file set, SUBFS, that represents
            %   the part of the files corresponding to the original file set, FS,
            %   given
            %       N  - the number of partitions for the original file set
            %       ii - the index chosen for the new file set
            %
            %   See also matlab.io.datastore.DsFileSet, nextfile, matlab.io.datastore.Partitionable.

            import matlab.io.datastore.internal.util.pigeonHole
            validateattributes(N, {'double'}, {'scalar', 'positive', 'integer'}, 'partition', 'NumPartitions');
            validateattributes(ii, {'double'}, {'scalar', 'positive', 'integer'}, 'partition', 'Index');
            if ii > N
                error(message('MATLAB:datastoreio:dsfileset:invalidPartitionIndex', ii));
            end

            % pigeonhole the files in the FileSet
            %    n(r-1) + 1 objects into n boxes
            if ischar(fs.FileSplitSize)
                boxIndices = pigeonHole(N, fs.NumFiles);
                splits = 0;
                cumSplits = [];
            else
                [splits, cumSplits] = splitsWithFileSplitSize(fs);
                boxIndices = pigeonHole(N, size(splits,1));
            end

            if N > fs.NumFiles 
                if (ischar(fs.FileSplitSize) && ii > fs.NumFiles) || ...
                        (~ischar(fs.FileSplitSize) && ii > size(splits,1))
                    % create an empty partition
                    subfs = emptyPartition(fs);
                    return;
                end
            end

            zeroSplits = 0;
            % find the file indices that belong to the given box index
            if ~splits
                zeroSplits = 1;
                fileIndices = find(boxIndices == ii);
            else
                % FileSplitSize is specified
                if ~isempty(boxIndices)
                    fileIndices = unique(splits(boxIndices == ii,3))';
                else
                    fileIndices = [];
                end
            end

            % if fileIndices is empty we need a column vector to index file sizes
            % to form a table in the resolve method. See help for resolveAll.
            if isempty(fileIndices)
                fileIndices = fileIndices(:);
            end

            scalarSplits = isscalar(splits);
            emptyFileIndices = isempty(fileIndices);
            if ~scalarSplits && ~emptyFileIndices
                numSplits = numel(find(splits(:,3) == unique(fileIndices)));
            elseif (scalarSplits && splits == 0) || emptyFileIndices
                numSplits = 0;
            end

            if fs.HoldToPartitionIndices
                % If the clients need these file indices, setHoldPartitionIndices(true)
                % must be called prior to partition of the fileset object.
                fs.PartitionIndices = fileIndices;
            end
            % Create a copy of the FileSet for the boxed file indices
            subfs = copyWithFileIndices(fs, fileIndices, numSplits);

            % get the start and end offset for the partition
            startOffset = 0;
            if ~zeroSplits && ~isempty(boxIndices) && ~ischar(fs.FileSplitSize)
                % save only the end offset of the last split in each
                % partition
                endOffset = splits(find(boxIndices == ii, 1, 'last'),2);
                startOffset = splits(find(boxIndices == ii, 1, 'first'),1);
            else
                if fs.NumFiles
                    endOffset = fs.FileSizes(fs.NumFiles);
                else
                    endOffset = 0;
                end
            end
            subfs.EndOffset = endOffset;
            subfs.StartOffset = startOffset;
            subfs.CurrentOffset = subfs.StartOffset;
            subfs.NumSplits = numel(find(boxIndices == ii));
            if ~isempty(cumSplits)
                subfs.BlocksPerFile = cumsum(cumSplits(fileIndices));
            end

            % Recompute the folders property if a non-trivial partition is
            % generated.
            subfs.partitionFoldersProperty(N, ii);
        end

        function subfs = emptyPartition(fs)
	        % Create an empty partition
            subfs = copyWithFileIndices(fs, []);
            subfs.EndOffset = 0;
            subfs.StartOffset = 0;
            subfs.CurrentOffset = subfs.StartOffset;
            subfs.NumSplits = 0;
            subfs.BlocksPerFile = 0;
            subfs.Folders = cell.empty(0, 1);
        end

        function numSplits = numSplitsForSubset(fs, fileIndices)
            %NUMSPLITSFORSUBSET Return NumSplits when creating a subset
            %   SUBFS = NumSplitsForSubset(FS,ii) returns the number of splits,
            %   NUMSPLITS, for the subset of the FileSet
            %   fileIndices - the indices of the files that are part of the subset
            %
            %   See also matlab.io.datastore.FileSet, nextfile, matlab.io.datastore.Partitionable.

            if ~isempty(fileIndices) && size(fileIndices,1) > 1
                fileIndices = fileIndices';
            end
            if ischar(fs.FileSplitSize)
                numSplits = numel(fileIndices);
            else
                [splits, cumSplits] = splitsWithFileSplitSize(fs, fileIndices);
                fs.BlocksPerFile = cumsum(cumSplits);
                if ~isempty(splits) && ~isscalar(splits)
                    numSplits = numel(find(splits(:,3) == unique(fileIndices)));
                elseif isscalar(splits) && splits == 0
                    numSplits = 0;
                end
            end
        end

        function [splits, cumSplits] = splitsWithFileSplitSize(fs,varargin)
            % get splits when FileSplitSize is specified
            files = numel(fs.FileSizes);
            allSizes = fs.FileSizes;
            splits = cell(files,1);
            cumSplits = zeros(numel(fs.FileSizes),1);
            if ~isempty(varargin)
                fileIndices = varargin{1};
            else
                fileIndices = 1 : files;
            end
            for jj = 1 : numel(fileIndices)
                % split each file based on FileSplitSize
                thisSplit = 0:fs.FileSplitSize:allSizes(jj);
                endOffset = [thisSplit(2:end)-1, allSizes(jj)];
                thisSize = size(thisSplit,2);
                cumSplits(jj) = thisSize;
                if thisSize > 1
                    splits{jj} = [thisSplit', endOffset', ...
                        repmat(fileIndices(jj),thisSize,1)];
                else
                    splits{jj} = [thisSplit, endOffset, fileIndices(jj)];
                end
            end
            if isempty(splits)
                splits = 0;
            else
                splits = vertcat(splits{:});
            end
        end

        function files = resolve(fs)
            % resolve all files and return a table with 2 variables
            % FileName and FileSize
            [f, fsize] = resolveAll(fs);
            fsize = getActualFileSizeIfStruct(fs, fsize);
            % Reshape the filename and file size to always be a column vector.
            f = reshape(f, [], 1);
            fsize = reshape(fsize, [], 1);
            files = table(f, fsize, 'VariableNames', {'FileName', 'FileSize'});
        end

        function [fName, fSize, offset, blockSize] = resolveInfo(fs, varargin)
            % resolve either all file names or only the specified index
            offset = [];
            blockSize = [];
            fName = [];
            fSize = [];
            if ~isempty(fs.BlocksPerFile) && ~isempty(varargin)
                % For a BlockedFileSet, we need to map the block index to
                % the file index
                blks = find(varargin{1} <= fs.BlocksPerFile);
                if numel(blks) == numel(fs.BlocksPerFile)
                    fileIndex = 1;
                    blkIdxWithinFile = varargin{1};
                else
                    fileIndex = blks(1);
                    blkIdxWithinFile = varargin{1} - fs.BlocksPerFile(fileIndex-1);
                end
                [fName, fSize] = resolveAll(fs, fileIndex);
                offset = fs.StartOffset + (blkIdxWithinFile-1)*fs.FileSplitSize;
                if fSize - offset > fs.FileSplitSize
                    blockSize = fs.FileSplitSize;
                else
                    blockSize = fSize - offset;
                end
            elseif isempty(fs.BlocksPerFile)
                [fName, fSize] = resolveAll(fs, varargin{:});
                offset = zeros(size(fName,1),1);
                blockSize = fSize;
            end
            fSize = getActualFileSizeIfStruct(fs, fSize);
        end

        function [fName, fSize, offset, splitSize] = nextfile(fs)
            % return the next chunk in the FileSet/DsFileSet/BlockedFileSet
            if ~hasNextFile(fs)
                error(message('MATLAB:datastoreio:dsfileset:noMoreFiles'));
            end
            ci = fs.CurrentFileIndex;
            fSize = fs.FileSizes(ci);
            if ischar(fs.FileSplitSize)
                % If FileSplitSize is 'file' get the next file.
                fName = resolveFile(fs);
                % CurrentOffset will always be the start offset for this FileSet.
                offset = fs.CurrentOffset;
                % Split size is the file size for a file. This could be the Size
                % passed using a LOCATION-struct or the size of the file.
                splitSize = fSize - offset;
                % Always increment to the next file
                fs.CurrentFileIndex = ci + 1;
                fs.NumBlocksRead = fs.NumBlocksRead + 1;
                fs.CurrentFileName = fName;
            else
                if fs.CurrentOffset == 0 || isempty(fs.CurrentFileName)
                    % only get the next file when CurrentOffset is 0 or
                    % filename was not initialized
                    fs.CurrentFileName = resolveFile(fs);
                end
                fName = fs.CurrentFileName;
                offset = fs.CurrentOffset;
                splitSize = fs.FileSplitSize;
                if offset + splitSize > fSize
                    % split size is the remaining amount in the full file size.
                    splitSize = fSize - offset;
                end
                fs.CurrentOffset = fs.CurrentOffset + splitSize;
                if fs.CurrentOffset >= fSize || (fs.CurrentOffset >= fs.EndOffset ...
                        && fs.CurrentFileIndex == fs.NumFiles)
                    % Set the CurrentOffset to 0 once the current file is done.
                    if ci + 1 <= fs.NumFiles
                        fs.CurrentOffset = 0;
                    end
                    % Increment to the next file once the current file is done.
                    if fs.CurrentFileIndex <= fs.NumFiles
                        fs.CurrentFileIndex = ci + 1;
                    end
                end
                fs.NumBlocksRead = fs.NumBlocksRead + 1;
            end
            fSize = getActualFileSizeIfStruct(fs, fSize);
        end

        function [fName, fSize, offset, splitSize] = previousfile(fs)
            % return the previous chunk in the FileSet/BlockedFileSet
            if ~hasPreviousFile(fs)
                error(message('MATLAB:datastoreio:dsfileset:noPreviousFiles'));
            end

            fs.NumBlocksRead = fs.NumBlocksRead - 1;
            % If FileSplitSize is 'file' get the previous file.
            if ischar(fs.FileSplitSize)
                % Always decrement to the previous file.
                ci = fs.CurrentFileIndex - 1;
                % Get file size for this file
                fSize = fs.FileSizes(ci);
                % Update index of current file
                fs.CurrentFileIndex = ci;
                % Get file name
                fName = resolveFile(fs);
                % CurrentOffset will always be the start offset for this FileSet.
                offset = fs.CurrentOffset;
                % Split size is the file size for a file. This could be the Size
                % passed using a LOCATION-struct or the size of the file.
                splitSize = fSize - offset;
                % Update file name of current file
                fs.CurrentFileName = fName;
            else
                if fs.CurrentFileIndex > fs.NumFiles || ~fs.CurrentOffset
                    ci = fs.CurrentFileIndex - 1;
                else
                    ci = fs.CurrentFileIndex;
                end
                % Get file size for this file
                fSize = fs.FileSizes(ci);
                % Update index of current file
                fs.CurrentFileIndex = ci;

                if fs.CurrentOffset == 0 || isempty(fs.CurrentFileName)
                    % only get the previous file when CurrentOffset is 0 or
                    % filename was not initialized
                    fs.CurrentFileName = resolveFile(fs);
                    fs.CurrentOffset = fSize;
                end
                fName = fs.CurrentFileName;
                numBlocks = floor(fSize/fs.FileSplitSize);
                if fs.CurrentOffset > numBlocks*fs.FileSplitSize
                    % last incomplete block
                    blockBounds = fs.CurrentOffset - numBlocks*fs.FileSplitSize;
                else
                    % complete block
                    blockBounds = mod(fs.CurrentOffset,fs.FileSplitSize);
                end
                if ~blockBounds
                    % at block boundary
                    offset = fs.CurrentOffset - fs.FileSplitSize;
                    splitSize = fs.FileSplitSize;
                else
                    % last noncomplete block
                    splitSize = blockBounds;
                    offset = fSize - splitSize;
                end
                
                fs.CurrentOffset = offset;
            end
            fSize = getActualFileSizeIfStruct(fs, fSize);
        end

        function reset(fs)
            % Reset the FileSet to the beginning where no files have been
            % read from the FileSet
            fs.NumFiles = numel(fs.FileSizes);
            fs.NumBlocksRead = 0;
            fs.CurrentFileIndex = 1;
            if ~isempty(fs.StartOffset)
                fs.CurrentOffset = fs.StartOffset(1);
            else
                fs.CurrentOffset = [];
            end
        end

        function tf = hasNextFile(fs)
            % Are there more files to be read
            tf = fs.CurrentFileIndex <= fs.NumFiles;
        end

        function tf = hasPreviousFile(fs)
            % Are there files that have been read
            tf = fs.CurrentFileIndex >= 1 && fs.NumBlocksRead >= 1;
        end

        function N = maxpartitions(fs)
            if ischar(fs.FileSplitSize)
                N = fs.NumFiles;
            else
                N = fs.NumSplits;
            end
        end

        function numSplits = getNumSplits(fs)
            numSplits = fs.NumSplits;
        end
    end

    methods(Static, Access = protected)
        function iCleanupWarnOnSave(lastWarningState, lastWarnMsg, lastWarnId)
            %iCleanupWarnOnSave Restores the previous state of warning.
            % We need to reset the lastwarn with previous values. This is because
            % variable editor checks for lastwarn to throw a warning dialog if the last
            % warning id is not the same. This of course only happens when 'SaveAs' in
            % workspace editor is used to save.
            warning(lastWarningState);
            lastwarn(lastWarnMsg, lastWarnId);
        end
    end

    methods (Abstract, Access = protected)
        %RESOLVEALL Return a resolved set of files and filesizes.
        %   Subclasses must implement how all files and filesizes are resolved.
        %   [FILES, FSIZES] = resolveAll(FS) returns resolved files and file
        %   sizes represented by the DsFileSet object.
        %       FILES - A string column vector of files
        %       FSIZES - A double column vector of file sizes
        %
        %   See also matlab.io.datastore.DsFileSet, resolve.
        [f, fs] = resolveAll(fs);

        % Subclasses must implement how each file will be resolved.
        f = resolveFile(fs);

        % Subclasses must implement how to obtain a column cell array of files
        % that can be obtained from the fileset object.
        getFilesAsCellStr(fs, indices);
    end

    methods (Abstract, Hidden)
        %COPYWITHFILEINDICES This copies the current object using the input indices.
        %   Based on the input indices fileset object creates a copy.
        %   Subclasses must implement on how they can be created from a list of file indices.
        newCopy = copyWithFileIndices(fs, indices, varargin);

        %SETFILESANDFILESIZES Set the files and file sizes for the fileset object.
        %   This is useful when creating an empty file set object and setting the
        %   valid folders and files that are already resolved without any need for
        %   file existence or validity.
        setFilesAndFileSizes(fs, files, fileSizes);

        %SETSHUFFLEDINDICES Set the shuffled indices for files and file sizes of the fileset object.
        %   Any subsequent nextfile calls to the fileset object gets the files
        %   using the shuffled indices. This sets the corresponding file sizes to reflect
        %   the new indices.
        setShuffledIndices(fs, idxes);

        %SETDUPLICATEINDICES Set the duplicate indices for the fileset object.
        %   Any subsequent nextfile calls to the fileset object gets the files
        %   using the already existing indices and duplicate indices.
        setDuplicateIndices(fs, duplicateIndices, addedIndices);

        %COPYANDORSHUFFLE This copies the current object, with or without shuffling.
        %   Based on the inputs fileset object can decide to either copy
        %   and/or shuffle the fileset. If just shuffling is done, then the output
        %   of this function is empty since a copy is not created.
        newCopy = copyAndOrShuffle(fs, indices);
    end

    methods (Hidden)
        function setFileSizes(fs, fileSizes)
            %SETFILESIZES Set the file sizes for the fileset object.
            fs.FileSizes = fileSizes;
            reset(fs);
        end

        function fileSizes = getFileSizes(fs, indices)
            %GETFILESIZES Get the file sizes from the fileset object.
            %   If a set of indices are given just get those file sizes or just
            %   get all the file sizes.
            if nargin == 2
                fileSizes = fs.FileSizes(indices);
            else
                fileSizes = fs.FileSizes;
            end
        end

        function files = getFiles(fs, ii)
            %GETFILES Get the file paths from the fileset object.
            %   If a set of indices are given just get those files or just
            %   get all the files.
            files = getFilesAsCellStr(fs, ii);
        end

        function setHoldPartitionIndices(fs, tf)
            %SETHOLDPARTITIONINDICES Set logical value to whether hold partition indices or not.
            %   This will set the logical value on the fileset object, indicating whether
            %   partition indices must be held by the fileset or not.
            fs.HoldToPartitionIndices = tf;
        end

        function setNumSplits(fs, numSplits)
            %SETNUMSPLITS Set the number of splits possible for this
            %   fileset. Used when creating a subset of the fileset.
            fs.NumSplits = numSplits;
        end

        function clearPartitionIndices(fs)
            %CLEARPARTITIONINDICES Clears the partition indices held by the fileset object.
            %   This will clear the partition indices held by the fileset object.
            if ~fs.HoldToPartitionIndices
                return;
            end
            fs.PartitionIndices = [];
        end

        function indices = getPartitionIndices(fs)
            %GETPARTITIONINDICES Gets the partition indices held by the fileset object.
            %   setHoldPartitionIndices(true) must have been called prior to this
            %   to get non-empty values from this function.
            indices = fs.PartitionIndices;
        end

        function setRecalculateFolders(fs, recalculateFolders)
            fs.RecalculateFolders = recalculateFolders;
        end
        
        function updateInternalFoldersProperty(fs)
            % Update the folders property through the
            % FoldersPropertyProvider mixin.
            fs.updateFoldersProperty();
        end
    end

    methods (Access = private)

        function populateFolders(fs, nvStruct)
            %populateFolders is a helper function that uses the Location and
            %   Files fields in the nvStruct to populate the Folders
            %   property.

            % Account for the possibility that the Location isn't stored in
            % the nvStruct. This may happen during loadobj.
            if ~isfield(nvStruct, "Location")
                nvStruct.Location = {};
            end

            % Convert location to a column vector to make it safe to
            % vertcat.
            if ischar(nvStruct.Location)
                nvStruct.Location = {nvStruct.Location};
            end
            location = reshape(nvStruct.Location, [], 1);

            % Handle the empty case for the Folders property.
            if isempty(nvStruct.Files)
                parentFolders = cell.empty(0, 1);
            else
                parentFolders = nvStruct.Files(:, 1);
            end

            % In-memory FileSet's construction doesn't resolve folders
            % ahead-of-time. So branch when populating the Folders property.
            if isfield(nvStruct, "FullFilePaths") && nvStruct.FullFilePaths == "in-memory"
                fs.populateFoldersFromLocation(location);
            else
                % Populate the Folders property. We already have a list of
                % directories in the nvStruct that can be used for this. This
                % list of directories is recursively resolved, so we don't need
                % to set IncludeSubfolders to true.
                fs.populateFoldersFromResolvedPaths(location, parentFolders);
            end
        end

        function fsize = getActualFileSizeIfStruct(fs, fsize)
            import matlab.io.datastore.internal.fileset.ResolvedFileSet;
            if fs.ActualFileSizeIfStruct ~= ResolvedFileSet.DEFAULT_ACTUAL_FILE_SIZE_IF_NOT_STRUCT
                fsize = fs.ActualFileSizeIfStruct;
            end
        end
    end
end
