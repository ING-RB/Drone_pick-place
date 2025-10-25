classdef BlockedFileSet < matlab.io.datastore.internal.HandleUnwantedHideable & ...
                          matlab.mixin.internal.Scalar & ...
                          matlab.mixin.Copyable
%BlockedFileSet A file set object for a collection of blocks within files.
%   BS = matlab.io.datastore.BlockedFileSet(LOCATION) creates a blocked file 
%   set object that can be used to collect a very large collection of blocks
%   within files. This provides an easier and iterative way of going over
%   the collection of files.
%   LOCATION has the following properties:
%      - Can be a filename or a folder name
%      - Can be a cell array or a string array of multiple file or folder names
%      - Can contain a relative path (HDFS requires a full path)
%      - Can contain a wildcard (*) character
%      - Can be a struct containing fields: FileName, Offset, Size
%
%   BS = matlab.io.datastore.BlockedFileSet(__,'BlockSize',SPLITSIZE) specifies 
%   the size in bytes to be used to split file information. The default value for
%   BlockSize is 'file', which means one file information from the
%   nextblock method contains the whole file. SPLITSIZE can also be number
%   of bytes. In this case, nextblock returns the same file multiple times
%   with increasing offsets based on SPLITSIZE.
%   For example, if LOCATION has one file of size 5MB and SPLITSIZE is 1MB,
%   then fileset provides file information for the same file 5 times when
%   calling the nextblock method.
%
%   BS = matlab.io.datastore.BlockedFileSet(__,'IncludeSubfolders',TF) 
%   specifies the logical true or false to indicate whether the files in 
%   each folder and its subfolders are included recursively or not.
%
%   BS = matlab.io.datastore.BlockedFileSet(__,'FileExtensions',EXTENSIONS) 
%   specifies the extensions of files to be included. Values for EXTENSIONS 
%   can be:
%      - A character vector or a string scalar, such as '.jpg' or '.png'
%        (empty quotes '' are allowed for files without extensions)
%      - A cell array of character vectors or a string array, such as {'.jpg', '.png'}
%
%   BS = matlab.io.datastore.BlockedFileSet(__,'AlternateFileSystemRoots',ALTROOTS) 
%   specifies the alternate file system root paths for the files provided 
%   in the LOCATION argument. ALTROOTS contains one or more rows, where 
%   each row specifies a set of equivalent root paths. Values for ALTROOTS 
%   can be one of these:
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
%
%   The value of ALTROOTS must also satisfy these conditions:
%      - Each row of ALTROOTS must specify multiple root paths and each root
%        path must contain at least 2 characters.
%      - Root paths specified must be unique and should not be subfolders of
%        each other
%      - ALTROOTS must have at least one root path entry that points to the
%        location of files
%
%   BlockedFileSet Properties:
%
%      NumBlocks                - Number of files represented by this file set
%      NumBlocksRead            - Index of the next file to be read
%      BlockSize                - Size in bytes to split file information
%      BlockInfo                - Information about all files in the file set
%      AlternateFileSystemRoots - Alternate file system root paths for the files
%
%   BlockedFileSet Methods:
%
%      hasNextBlock     - Returns true if there are more files in the file set
%      nextblock        - Returns the next consecutive file and advances the
%                         file set to the next consecutive file
%      hasPreviousBlock - Returns the next consecutive file without advancing
%                         the file set to the next consecutive file
%      previousblock    - Returns the previous file and recedes the file set
%                         to the previous file
%      reset            - Reset the file set to the start of the first file
%      subset           - Subsets the file set specified by the indices
%      partition        - Returns a new fileset that represents a single
%                         partitioned portion of the original file set
%      maxpartitions    - Returns the maximum number of partitions possible 
%                         for the file set
%
%   Example:
%   --------
%      folder = fullfile(matlabroot,'toolbox','matlab','demos');
%      bs = matlab.io.datastore.BlockedFileSet(folder,'IncludeSubfolders',true,'FileExtensions','.mat');
%
%      blk1 = nextblock(bs)        % Obtain block information for the first block
%      blk2 = nextblock(bs)        % Obtain block information for the second block
%      blk3 = previousblock(bs)    % Obtain block information for the second block
%      allBlks = bs.BlockInfo      % Obtain block information for all the blocks
%      tenthBlk = bs.BlockInfo(10) % Obtain block information for the 10th block
%
%      ft = cell(bs.NumBlocks,1);
%      i = 1;
%      reset(bs);                  % Reset to the beginning of the fileset
%      while hasNextBlock(bs)       % Get blocks using a while-loop
%          ft{i} = nextblock(bs);
%          i = i + 1;
%      end
%      allBlocks1 = vertcat(ft{:});
%
%      ft = cell(bs.NumBlocks,1);
%      i = 1;
%      while hasPreviousBlock(bs)     % Get blocks using a while-loop
%          ft{i} = previousblock(bs);
%          i = i + 1;
%      end
%      allBlocks2 = vertcat(ft{:});
%
%   See also matlab.io.Datastore,
%            matlab.io.datastore.FileSet,
%            matlab.io.datastore.DsFileReader,
%            matlab.io.datastore.Partitionable,
%            matlab.io.datastore.HadoopFileBased.

%   Copyright 2019-2023 The MathWorks, Inc.

    properties (SetAccess = protected, Dependent)
        %BLOCKINFO Information about any block in the blocked file set object.
        BlockInfo
        %BLOCKSIZE Size in bytes to be used to represent a split of a file.
        BlockSize
        %NUMFILES Number of blocks represented by this blocked file set object.
        NumBlocks
        %NUMBLOCKSREAD Number of blocks read from the blocked file set object.
        NumBlocksRead
    end
 

    properties (Dependent)
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
        AlternateFileSystemRoots
    end


    properties (Dependent, Hidden, SetAccess = private)
        %Folders lists the folders provided in the 'location' argument
        %   during datastore construction
        %
        %   If "IncludeSubFolders" was set to true when constructing the
        %   datastore, then the Folders property includes any new
        %   subfolders that were added to the datastore.
        %
        %   The Folders property must contain a non-empty value in order
        %   to use the 'writeall' method on file-based datastores.
        %
        %   See also matlab.io.datastore.TabularTextDatastore.writeall
        Folders(:, 1) cell;
        NumFiles;
    end

    properties (Constant, Access = private)
        DEFAULT_INCLUDE_SUBFOLDERS = false;
        DEFAULT_FILE_EXTENSIONS = -1;
        DEFAULT_FULL_FILE_PATHS = 'compressed';
        IN_MEMORY_FULL_FILE_PATHS = 'in-memory';
        DEFAULT_FILE_SPLIT_SIZE = 'file';
        INCLUDE_SUBFOLDERS_NV_NAME = 'IncludeSubfolders';
        FILE_EXTENSIONS_NV_NAME = 'FileExtensions';
        FULL_FILE_PATHS_NV_NAME = 'FullFilePaths';
        BLOCK_SIZE_NV_NAME = 'BlockSize';
        M_FILENAME = mfilename;
    end

    properties (Access = private)
        % An internal fileset object chosen by this BlockedFileSet object
        InternalFileSet
        % Logical to indicate whether to copy internal fileset or not
        DoNotCopyInternalFileSet = false
    end

    methods
        function bs = BlockedFileSet(location, varargin)
            % Constructor
            import matlab.io.datastore.internal.fileset.ResolvedFileSetFactory;
            try
                nvStruct = iParseNameValues(varargin);
                if isa(location, "matlab.io.datastore.DsFileSet")
                    allFileInfo = resolve(location);
                    splitSizeParam = location.FileSplitSize;
                    altRoots = location.AlternateFileSystemRoots;
                    location = allFileInfo.FileName;
                    nvStruct.FileSplitSize = splitSizeParam;
                    nvStruct.AlternateFileSystemRoots = altRoots;
                end
                % Choose an internal fileset object built by the ResolvedFileSetFactory.
                bs.InternalFileSet = ResolvedFileSetFactory.build(location, ...
                    nvStruct);
            catch ME
                throw(ME);
            end
        end

        function N = maxpartitions(bs)
            %MAXPARTITIONS Return the maximum number of partitions possible for BlockedFileSet.
            %
            %   N = MAXPARTITIONS(BS) returns the maximum number of partitions for a
            %   given BlockedFileSet, BS. Returns the number of files, represented
            %   by the BlockedFileSet object, when BlockSize = 'file'. When BlockSize is
            %   numeric, then MAXPARTITIONS is the sum of the ceil of block sizes of each file
            %   divided by the BlockSize.
            %
            %   Example:
            %   --------
            %      folder = fullfile(matlabroot,'toolbox','matlab','demos');
            %      files = fullfile(folder, {'patients.mat','accidents.mat'});
            %
            %      bs = matlab.io.datastore.BlockedFileSet(files);
            %
            %      % When BlockSize is file, maxpartitions is equal to NumBlocks
            %      isequal(bs.NumBlocks, maxpartitions(bs))
            %
            %      % bs contains 2 files but split into partitions of size 2000 bytes
            %      bs = matlab.io.datastore.BlockedFileSet(files,'BlockSize',2000);
            %
            %      % find the maximum number of partitions provided by the BlockedFileSet for the 2 files
            %      n = maxpartitions(bs);
            %      subfs_1 = partition(bs, n, 1)    % subfs_1 contains the first partition off of n partitions
            %      subfs_2 = partition(bs, n, 2)    % subfs_2 contains the second partition off of n partitions
            %
            %   See also partition, matlab.io.datastore.BlockedFileSet, 
            %            matlab.io.datastore.Partitionable.
            try
                N = maxpartitions(bs.InternalFileSet);
            catch ME
                throw(ME);
            end
        end

        function subbs = subset(bs, indices)
            %SUBSET Subset a file set using file indices.
            %   SUBBS = SUBSET(BS, INDICES) creates a deep copy of the input file set, BS,
            %   resulting in the file set SUBBS that contains files corresponding to INDICES.
            %
            %   Example: Subset the first 4 files
            %   ----------------------------------
            %      folders = fullfile(matlabroot,'toolbox','matlab',{'demos','imagesci'});
            %      exts = {'.jpg','.png','.tif'};
            %      bs = matlab.io.datastore.BlockedFileSet(folders,'FileExtensions',exts)
            %      % subbs contains the first 4 files
            %      subbs = subset(bs, 1:4)
            %
            %   Example: Subset the first 60% randomly selected files
            %   -----------------------------------------------------
            %      folders = fullfile(matlabroot,'toolbox','matlab',{'demos','imagesci'});
            %      exts = {'.jpg','.png','.tif'};
            %      bs = matlab.io.datastore.BlockedFileSet(folders,'FileExtensions',exts)
            %      n = maxpartitions(bs);
            %      indices = randperm(n);
            %      st = round(0.6 * n);
            %      subbs = subset(bs, indices(1:st))
            %
            %   See also matlab.io.datastore.ImageDatastore/subset,
            %            matlab.io.datastore.BlockedFileSet/partition,
            %            matlab.io.datastore.BlockedFileSet,
            %            matlab.io.datastore.Partitionable.
            import matlab.io.datastore.internal.validators.validateSubsetIndices;
            indices = validateSubsetIndices(indices, maxpartitions(bs), mfilename, false);
            subbs = copy(bs);
            newCopy = copyAndOrShuffle(subbs, double(indices));
            if ~isempty(newCopy)
                % Ensure that any unnecessary folders are removed from the
                % Folders property on the next get.Folders.
                newCopy.InternalFileSet.setRecalculateFolders(true);

                numSplits = numSplitsForSubset(newCopy.InternalFileSet, indices);
                setNumSplits(newCopy.InternalFileSet,numSplits);
                subbs = newCopy;
            end
        end

        function subbs = partition(bs, N, ii)
            %PARTITION Return a partitioned part of the file set object.
            %
            %   SUBBS = PARTITION(BS,NUMPARTITIONS,INDEX) partitions BS into
            %   NUMPARTITIONS parts and returns the partitioned file set,
            %   SUBBS, corresponding to INDEX. An estimate for a reasonable value for the
            %   NUMPARTITIONS input can be obtained by using the NUMBLOCKS property
            %   of the file set.
            %
            %   Example:
            %   --------
            %      folder = fullfile(matlabroot,'toolbox','matlab','demos');
            %
            %      % bs contains 41 files
            %      bs = matlab.io.datastore.BlockedFileSet(folder,'IncludeSubfolders',true,'FileExtensions','.mat');
            %
            %      % partition the 41 files into 5 partitions and obtain the first portion
            %      subbs_1 = partition(bs, 5, 1);       % subbs_1 contains the first 9 files
            %      allSubbsFiles_1 = subbs_1.BlockInfo  % Obtain block information of all the 9 files
            %
            %      % partition the 41 files into 5 partitions and obtain the second portion
            %      subbs_2 = partition(bs, 5, 2);       % subbs contains the second 8 files
            %      allSubbsFiles_2 = subbs_2.BlockInfo  % Obtain the block information of all the 8 files
            %
            %   See also matlab.io.Datastore, 
            %            matlab.io.datastore.BlockedFileSet/maxpartitions,
            %            matlab.io.datastore.BlockedFileSet/subset,
            %            matlab.io.datastore.BlockedFileSet,
            %            matlab.io.datastore.Partitionable.
            try
                subbs = copy(bs);
                subbs.InternalFileSet = partition(bs.InternalFileSet, N, ii);
            catch ME
                throw(ME);
            end
        end

        function blockInfo = nextblock(bs)
            %NEXTBLOCK Returns the next block information available in the file set object.
            %   NB = NEXTBLOCK(BS) returns the next consecutive file information from BS.
            %   NB is a matlab.io.datastore.BlockInfo with properties,
            %   Filename, FileSize, Offset, and BlockSize.
            %   NEXTBLOCK(BS) errors if there are no more blocks in the file 
            %   set object. BS and should be used with hasNextBlock(BS) and
            %   reset(BS).
            %
            %   Example:
            %   --------
            %      folder = fullfile(matlabroot,'toolbox','matlab','demos');
            %      bs = matlab.io.datastore.BlockedFileSet(folder,'IncludeSubfolders',true,'FileExtensions','.mat');
            %
            %      while hasNextBlock(bs)
            %         block = nextblock(bs);   % Obtain one block at a time
            %      end
            %
            %   See also hasNextBlock, previousblock, matlab.io.Datastore,
            %            matlab.io.datastore.BlockedFileSet,
            %            matlab.io.datastore.Partitionable.
            try
                [fName, fSize, offset, splitSize] = nextfile(bs.InternalFileSet);
                blockInfo = matlab.io.datastore.BlockInfo(fName, fSize, offset, splitSize);
            catch ME
                if ME.identifier == "MATLAB:datastoreio:dsfileset:noMoreFiles"
                    error(message("MATLAB:datastoreio:dsfileset:noMoreInfo", ...
                        "blocks","hasNextBlock","nextblock"));
                else
                    throwAsCaller(ME);
                end
            end
        end

        function blockInfo = previousblock(bs)
            %PREVIOUSFILE Returns the previous block information in the file set object.
            %   PB = PREVIOUSBLOCK(BS) returns the previous block
            %   information from BS.
            %   PB is a matlab.io.datastore.BlockInfo object with properties, 
            %   Filename, FileSize, Offset, and BlockSize.
            %   PREVIOUSBLOCK(BS) errors when called at the start of the
            %   file set. BS should be used with hasPreviousBlock(BS) and
            %   reset(BS).
            %
            %   Example:
            %   --------
            %      folder = fullfile(matlabroot,'toolbox','matlab','demos');
            %      bs = matlab.io.datastore.BlockedFileSet(folder,'IncludeSubfolders',true,'FileExtensions','.mat');
            %
            %      while hasNextBlock(bs)    % Traverse to the end of the file set
            %         nextblock(bs);  
            %      end
            %
            %      while hasPreviousBlock(bs)
            %         block = previousblock(bs);  % Obtain one block at a time
            %      end
            %
            %   See also nextblock, hasPreviousBlock, matlab.io.Datastore,
            %            matlab.io.datastore.BlockedFileSet,
            %            matlab.io.datastore.Partitionable.
            try
                [fName, fSize, offset, splitSize] = previousfile(bs.InternalFileSet);
                blockInfo = matlab.io.datastore.BlockInfo(fName, fSize, offset, splitSize);
            catch ME
                if ME.identifier == "MATLAB:datastoreio:dsfileset:noPreviousFiles"
                    error(message("MATLAB:datastoreio:dsfileset:noPreviousInfo","blocks","nextblock"));
                else
                    throwAsCaller(ME);
                end
            end
        end

        function tf = hasNextBlock(bs)
            %HASNEXTBLOCK Returns true if there is more block information not yet obtained from the file set object.
            %   TF = hasNextBlock(BS) returns true if the file set has one
            %   or more blocks available to obtain with the nextblock method. 
            %   nextblock(BS) returns an error when hasNextBlock(BS) returns false.
            %
            %   Example:
            %   --------
            %      folder = fullfile(matlabroot,'toolbox','matlab','demos');
            %      bs = matlab.io.datastore.BlockedFileSet(folder,'IncludeSubfolders',true,'FileExtensions','.mat');
            %
            %      while hasNextBlock(bs)
            %         file = nextBlock(bs);  % Obtain one block at a time
            %      end
            %
            %   See also nextblock, hasPreviousBlock, matlab.io.Datastore,
            %            matlab.io.datastore.BlockedFileSet,
            %            matlab.io.datastore.Partitionable.
            tf = hasNextFile(bs.InternalFileSet);
        end

        function tf = hasPreviousBlock(bs)
            %HASPREVIOUSBLOCK Returns true if there is previous block information that has been obtained from the file set object.
            %   TF = hasPreviousBlock(BS) returns true if the file set has
            %   one or more blocks available to obtain with the previousblock
            %   method. previousblock(BS) returns an error when
            %   hasPreviousBlock(BS) returns false.
            %
            %   Example:
            %   --------
            %      folder = fullfile(matlabroot,'toolbox','matlab','demos');
            %      bs = matlab.io.datastore.BlockedFileSet(folder,'IncludeSubfolders',true,'FileExtensions','.mat');
            %
            %      while hasNextBlock(bs)
            %         nextblock(bs);
            %      end
            %
            %      while hasPreviousBlock(bs)
            %         block = previousblock(bs);  % Obtain one block at a time
            %      end
            %
            %   See also previousblock, hasNextBlock, matlab.io.Datastore,
            %            matlab.io.datastore.BlockedFileSet,
            %            matlab.io.datastore.Partitionable.
            tf = hasPreviousFile(bs.InternalFileSet);
        end

        function reset(bs)
            %RESET Reset the file set to the start of the blocks information in the file set object.
            %   RESET(BS) resets FS to the beginning of the file set.
            %
            %   Example:
            %   --------
            %      folder = fullfile(matlabroot,'toolbox','matlab','demos');
            %      bs = matlab.io.datastore.BlockedFileSet(folder,'IncludeSubfolders',true,'FileExtensions','.mat');
            %
            %      ft = cell(bs.NumBlocks,1);
            %      i = 1;
            %      while hasNextBlock(bs)      % Get files using a while-loop
            %          ft{i} = nextblock(bs);
            %          i = i + 1;
            %      end
            %      allFiles = vertcat(ft{:});
            %
            %      reset(bs);                  % Reset to the beginning of the BlockedFileSet
            %      block1 = nextblock(bs)      % Obtain block information for the first block
            %      block2 = nextblock(bs)      % Obtain block information for the second block
            %      allfiles = bs.BlockInfo     % Obtain block information for all blocks
            %
            %   See also hasNextblock, nextblock, matlab.io.Datastore,
            %            matlab.io.datastore.BlockedFileSet,
            %            matlab.io.datastore.Partitionable.
            try
                reset(bs.InternalFileSet);
            catch ME
                throw(ME);
            end
        end

        function frac = progress(bs)
            %PROGRESS   Percentage of consumed data between 0.0 and 1.0.
            %   Return fraction between 0.0 and 1.0 indicating progress as a
            %   double.
            %
            %   See also hasNextBlock, nextblock, 
            %            previousblock, hasPreviousBlock,
            %            matlab.io.datastore.BlockedFileSet
            frac = bs.NumBlocksRead/bs.NumBlocks;
        end

        % Getter for AlternateFileSystemRoots
        function aRoots = get.AlternateFileSystemRoots(bs)
            aRoots = bs.InternalFileSet.AlternateFileSystemRoots;
        end

        % Setter for AlternateFileSystemRoots
        function set.AlternateFileSystemRoots(bs, aRoots)
            bs.InternalFileSet.AlternateFileSystemRoots = aRoots;
        end

        % Getter for NumBlocks
        function bBlocks = get.NumBlocks(bs)
            bBlocks = getNumSplits(bs.InternalFileSet);
        end

        function blocksRead = get.NumBlocksRead(bs)
            blocksRead = bs.InternalFileSet.NumBlocksRead;
        end

        % Getter for BlockSize
        function blockSize = get.BlockSize(bs)
            blockSize = bs.InternalFileSet.FileSplitSize;
        end

        % Getter for BlockInfo
        function blockInfo = get.BlockInfo(bs, varargin)
            if strcmp(bs.InternalFileSet.FileSplitSize, 'file')
                [fName, fSize, offset, blockSize] = resolveInfo(bs.InternalFileSet);
            else
                [fName, fSize, offset, blockSize] = getAllBlocks(bs);
            end
            blockInfo = matlab.io.datastore.BlockInfo(fName, fSize, offset, blockSize);
        end

        function folders = get.Folders(bs)
            folders = bs.InternalFileSet.Folders;
        end
        
        function nfiles = get.NumFiles(bs)
             nfiles = bs.InternalFileSet.NumFiles;
        end
    end

    methods (Access = protected)
        function cpObj = copyElement(bs)
            cpObj = copyElement@matlab.mixin.Copyable(bs);
            if ~bs.DoNotCopyInternalFileSet
                cpObj.InternalFileSet = copy(bs.InternalFileSet);
            end
        end

        function [fName, fSize, offset, blockSize] = getAllBlocks(bs)
            fName = strings(bs.NumBlocks,1);
            fSize = zeros(bs.NumBlocks,1);
            offset = zeros(bs.NumBlocks,1);
            blockSize = zeros(bs.NumBlocks,1);
            for ii = 1 : bs.NumBlocks
                [fName(ii), fSize(ii), offset(ii), blockSize(ii)] = ...
                    resolveInfo(bs.InternalFileSet, ii);
            end
        end

        function link = propDisplayLink(~, name, propname)
            %PROPDISPLAYLINK get a link for displaying a property
            msg = getString(message('MATLAB:graphicsDisplayText:FooterLinkFailureMissingVariable', name));
            codeToExecute = sprintf(['if exist(''' name ''',''var''),%%s,else,fprintf(''%s\\\\n'');end'], msg);
            codeToExecute = sprintf(codeToExecute,"fprintf('" + name + "." + propname + " = \n\n');dispBlockInfo("+name+")");
            link = sprintf('<a href="matlab:%s" style="font-weight:bold">%s</a>', codeToExecute, propname);
        end
    end

    methods (Access = {?matlab.io.datastore.internal.fileset.ResolvedFileSetFactory})
        function setInternalFileSet(bs, internalFileSet)
            %SETINTERNALFILESET Set the internal fileset object created by ResolvedFileSetFactory.
            bs.InternalFileSet = internalFileSet;
        end
    end

    methods (Hidden)
        function setFilesAndFileSizes(bs, varargin)
            %SETFILESANDFILESIZES Set the files and file sizes for the fileset object.
            %   This is useful when creating an empty file set object and setting the
            %   valid folders and files that are already resolved without any need for
            %   file existence or validity.
            bs.InternalFileSet.setFilesAndFileSizes(varargin{:});
        end

        function setFileSizes(bs, varargin)
            %SETFILESIZES Set the file sizes for the fileset object.
            bs.InternalFileSet.setFileSizes(varargin{:});
        end

        function fileSizes = getFileSizes(bs, indices)
            %GETFILESIZES Get the file sizes from the fileset object.
            %   If a set of indices are given just get those file sizes or just
            %   get all the file sizes.
            if nargin == 2
                fileSizes = bs.InternalFileSet.getFileSizes(indices);
            else
                fileSizes = bs.InternalFileSet.getFileSizes;
            end
        end

        function files = getFiles(bs, ii)
            %GETFILES Get the file paths from the fileset object.
            %   If a set of indices are given just get those files or just
            %   get all the files.
            if nargin == 1                
                ii = 1:bs.InternalFileSet.NumFiles;
            end
            files = bs.InternalFileSet.getFiles(ii);
        end        
        
        function newCopy = copyAndOrShuffle(bs, varargin)
            %COPYANDORSHUFFLE This copies the current object, with or without shuffling.
            %   Based on the inputs fileset object can decide to either copy
            %   and/or shuffle the fileset. If just shuffling is done, then the output
            %   of this function is empty since a copy is not created.
            internalFileSetCpy = bs.InternalFileSet.copyAndOrShuffle(varargin{:});
            if isempty(internalFileSetCpy)
                newCopy = [];
                return;
            end
            newCopy = copy(bs);
            newCopy.InternalFileSet = internalFileSetCpy;
        end

        function newCopy = copyWithFileIndices(bs, varargin)
            %COPYWITHFILEINDICES This copies the current object using the input indices.
            %   Based on the input indices fileset object creates a copy.
            internalFileSetCpy = bs.InternalFileSet.copyWithFileIndices(varargin{:});
            newCopy = copy(bs);
            newCopy.InternalFileSet = internalFileSetCpy;
        end

        function setShuffledIndices(bs, varargin)
            %SETSHUFFLEDIINDICES Set the shuffled indices for the fileset object.
            %   Any subsequent nextfile calls to the fileset object gets the files
            %   using the shuffled indices.
            bs.InternalFileSet.setShuffledIndices(varargin{:});
        end

        function setDuplicateIndices(bs, varargin)
            %SETDUPLICATEINDICES Set the duplicate indices for the fileset object.
            %   Any subsequent nextfile calls to the fileset object gets the files
            %   using the already existing indices and duplicate indices.
            bs.InternalFileSet.setDuplicateIndices(varargin{:});
            if nargin < 3
                numSplits = bs.InternalFileSet.numSplitsForSubset(varargin{1});
            elseif nargin < 4
                numSplits = bs.InternalFileSet.numSplitsForSubset(varargin{2});
            end
            setNumSplits(bs.InternalFileSet,numSplits);
        end

        function setHoldPartitionIndices(bs, tf)
            %SETHOLDPARTITIONINDICES Set logical value to whether hold partition indices or not.
            %   This will set the logical value on the fileset object, indicating whether
            %   partition indices must be held by the fileset or not.
            bs.InternalFileSet.setHoldPartitionIndices(tf);
        end

        function clearPartitionIndices(bs)
            %CLEARPARTITIONINDICES Clears the partition indices held by the fileset object.
            %   This will clear the partition indices held by the fileset object.
            bs.InternalFileSet.clearPartitionIndices;
        end

        function indices = getPartitionIndices(bs)
            %GETPARTITIONINDICES Gets the partition indices held by the fileset object.
            %   setHoldPartitionIndices(true) must have been called prior to this
            %   to get non-empty values from this function.
            indices = bs.InternalFileSet.getPartitionIndices;
        end

        function setDoNotCopyInternalFileSet(bs, tf)
            bs.DoNotCopyInternalFileSet = tf;
        end

        function dispBlockInfo(bs)
            % Render the table display into a string.
            fh = feature('hotlinks');
            tempVar = bs.BlockInfo;
            tempVar = table(tempVar.Filename, tempVar.FileSize, tempVar.Offset, ...
                tempVar.BlockSize, 'VariableNames',{'Filename','FileSize', ...
                'Offset','BlockSize'});
            if fh
                disp(tempVar);
            else
                % For no desktop, use hotlinks off on evalc to get rid of
                % xml attributes for display, like, <strong>Var1</strong>, etc.
                disp(evalc('feature hotlinks off; disp(tempVar);'));
                feature('hotlinks', fh);
            end
        end


        function disp(bs)
            %DISP controls the display of the BlockedFileSet.
            h = matlab.internal.datatypes.DisplayHelper(class(bs));
            addPropertyGroupNoTitle(h, bs, {'NumBlocks','NumBlocksRead', ...
                'BlockSize','BlockInfo','AlternateFileSystemRoots'});
            if ischar(bs.InternalFileSet.FileSplitSize) && ...
                    strcmp(bs.InternalFileSet.FileSplitSize,'file')
                blockSize = "'file'";
            else
                blockSize = string(bs.InternalFileSet.FileSplitSize);
            end

            replacePropDisp(h,"BlockSize",blockSize);
            if h.usingHotlinks()
                fileInfoLink = bs.propDisplayLink(inputname(1), "BlockInfo");
                replacePropDisp(h,"BlockInfo",sprintf("Show %s for all %d blocks", ...
                    fileInfoLink, bs.NumBlocks));
            else
                fileInfoLink = "BlockInfo";
                replacePropDisp(h,"BlockInfo",sprintf("%s for all %d blocks", ...
                    fileInfoLink, bs.NumBlocks));
            end

            h.printToScreen("BlockedFileSet",false);
        end
    end

    methods(Hidden, Static)
        function bs = empty(varargin)
            % Create an empty FileSet
            if nargin == 0 || (nargin == 2 && varargin{1} == 0 && varargin{2} == 1)
                bs = matlab.io.datastore.BlockedFileSet({});
            else
                error(message('MATLAB:class:EmptyScalar', ...
                    'matlab.io.datastore.BlockedFileSet','matlab.io.datastore.BlockedFileSet'));
            end
        end
    end
end

function parsedStruct = iParseNameValues(args)
    % Parse the BlockedFileSet Name-Value pairs using inputParser
    import matlab.io.datastore.BlockedFileSet;
    persistent inpP;
    if isempty(inpP)
        inpP = inputParser;
        addParameter(inpP, BlockedFileSet.INCLUDE_SUBFOLDERS_NV_NAME, BlockedFileSet.DEFAULT_INCLUDE_SUBFOLDERS);
        addParameter(inpP, BlockedFileSet.FILE_EXTENSIONS_NV_NAME, BlockedFileSet.DEFAULT_FILE_EXTENSIONS);
        addParameter(inpP, BlockedFileSet.FULL_FILE_PATHS_NV_NAME, BlockedFileSet.DEFAULT_FULL_FILE_PATHS);
        addParameter(inpP, BlockedFileSet.BLOCK_SIZE_NV_NAME, BlockedFileSet.DEFAULT_FILE_SPLIT_SIZE);
        addParameter(inpP, 'AlternateFileSystemRoots', {});
        inpP.FunctionName = BlockedFileSet.M_FILENAME;
    end
    [args{:}] = convertStringsToChars(args{:});
    parse(inpP, args{:});
    parsedStruct = inpP.Results;
    parsedStruct.UsingDefaults = inpP.UsingDefaults;
    parsedStruct.FullFilePaths = validatestring(parsedStruct.FullFilePaths, ...
        {BlockedFileSet.IN_MEMORY_FULL_FILE_PATHS, BlockedFileSet.DEFAULT_FULL_FILE_PATHS},...
        BlockedFileSet.M_FILENAME, BlockedFileSet.FULL_FILE_PATHS_NV_NAME);
    parsedStruct.BlockSize = iValidateSplitSize(parsedStruct.BlockSize);
    parsedStruct.FileSplitSize = parsedStruct.BlockSize;
    parsedStruct = rmfield(parsedStruct,"BlockSize");
end

function splitSize = iValidateSplitSize(splitSize)
    import matlab.io.datastore.BlockedFileSet;
    try
        if ischar(splitSize)
            splitSize = validatestring(splitSize, {BlockedFileSet.DEFAULT_FILE_SPLIT_SIZE},...
                BlockedFileSet.M_FILENAME, BlockedFileSet.BLOCK_SIZE_NV_NAME);
            return;
        end
        classes = {'numeric'};
        attrs = {'scalar', 'positive', 'integer'};
        validateattributes(splitSize, classes, attrs,...
            BlockedFileSet.M_FILENAME, BlockedFileSet.BLOCK_SIZE_NV_NAME);
        splitSize = double(splitSize);
    catch ME
        if any(strcmp(ME.identifier, ["MATLAB:BlockedFileSet:unrecognizedStringChoice", ...
                "MATLAB:BlockedFileSet:invalidType"]))
            error(message("MATLAB:datastoreio:dsfileset:invalidFileSplitSize", ...
                "BlockSize"));
        end
        throw(ME);
    end
end
