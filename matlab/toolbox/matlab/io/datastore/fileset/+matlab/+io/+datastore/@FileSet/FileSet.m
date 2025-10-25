classdef FileSet < matlab.io.datastore.internal.HandleUnwantedHideable & ...
                   matlab.mixin.internal.Scalar & ...
                   matlab.mixin.Copyable
%FileSet A file set object for a collection of files.
%   FS = matlab.io.datastore.FileSet(LOCATION) creates a file set object
%   that can be used to collect a very large collection of files. This
%   provides an easier and iterative way of going over the collection of files.
%   LOCATION has the following properties:
%      - Can be a filename or a folder name
%      - Can be a cell array or a string array of multiple file or folder names
%      - Can contain a relative path (HDFS requires a full path)
%      - Can contain a wildcard (*) character
%      - Can be a struct containing fields: FileName, Offset, Size
%
%   FS = matlab.io.datastore.FileSet(__,'IncludeSubfolders',TF) specifies the logical
%   true or false to indicate whether the files in each folder and its
%   subfolders are included recursively or not.
%
%   FS = matlab.io.datastore.FileSet(__,'FileExtensions',EXTENSIONS) specifies the
%   extensions of files to be included. Values for EXTENSIONS can be:
%      - A character vector or a string scalar, such as '.jpg' or '.png'
%        (empty quotes '' are allowed for files without extensions)
%      - A cell array of character vectors or a string array, such as {'.jpg', '.png'}
%
%   FS = matlab.io.datastore.FileSet(__,'AlternateFileSystemRoots',ALTROOTS) specifies
%   the alternate file system root paths for the files provided in the
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
%
%   The value of ALTROOTS must also satisfy these conditions:
%      - Each row of ALTROOTS must specify multiple root paths and each root
%        path must contain at least 2 characters.
%      - Root paths specified must be unique and should not be subfolders of
%        each other
%      - ALTROOTS must have at least one root path entry that points to the
%        location of files
%
%   FileSet Properties:
%
%      NumFiles                 - Number of files represented by this file
%                                 set
%      NumFilesRead             - Index of the next file to be read
%      FileInfo                 - Information about individual files in the
%                                 file set
%      AlternateFileSystemRoots - Alternate file system root paths for the
%                                 files
%
%   FileSet Methods:
%
%      hasNextFile     - Returns true if there are more files in the file set
%      nextfile        - Returns the next consecutive file and advances the
%                        file set to the next consecutive file
%      hasPreviousFile - Returns true if there are previous files in the
%                        file set
%      previousfile    - Returns the previous file and recedes the file set
%                        to the previous file
%      reset           - Reset the file set to the start of the first file
%      subset          - Subsets the file set specified by the indices
%      partition       - Returns a new fileset that represents a single
%                        partitioned portion of the original file set
%      maxpartitions   - Returns the maximum number of partitions possible
%                        for the file set
%
%   Example:
%   --------
%      folder = fullfile(matlabroot,'toolbox','matlab','demos');
%      fs = matlab.io.datastore.FileSet(folder,'IncludeSubfolders',true,'FileExtensions','.mat');
%
%      fInfo1 = nextfile(fs)     % Obtain the file name and file size of the first file
%      fInfo2 = nextfile(fs)     % Obtain the file name and file size of the second file
%      fInfo3 = previousfile(fs) % Obtain the file name and file size of the second file
%      allfiles = fs.FileInfo    % Obtain the file name and file size of all the files
%      tenthFile = fs.FileInfo(10) % Obtain the file name and file size of the 10th file
%
%      ft = cell(fs.NumFiles,1);
%      i = 1;
%      reset(fs);                  % Reset to the beginning of the fileset
%      while hasNextFile(fs)       % Get files using a while-loop
%          ft{i} = nextfile(fs);
%          i = i + 1;
%      end
%      allFiles = vertcat(ft{:});
%
%      ft = cell(fs.NumFiles,1);
%      i = 1;
%      while hasPreviousFile(fs)     % Get files using a while-loop
%          ft{i} = previousfile(fs);
%          i = i + 1;
%      end
%      allFiles = vertcat(ft{:});
%
%   See also matlab.io.Datastore,
%            matlab.io.datastore.BlockedFileSet,
%            matlab.io.datastore.DsFileReader,
%            matlab.io.datastore.Partitionable,
%            matlab.io.datastore.HadoopLocationBased.

%   Copyright 2019-2023 The MathWorks, Inc.

    properties (Dependent, SetAccess = protected)
        %FILEINFO Information about any file in the file set object.
        FileInfo
        %NUMFILES Number of files represented by this file set object.
        NumFiles
        %NUMFILESREAD Number of files read from the file set object.
        NumFilesRead
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
    end

    properties (Dependent, Hidden, GetAccess = private)
        RecalculateFolders(1, 1) logical;
    end

    properties (Constant, Access = private)
        DEFAULT_INCLUDE_SUBFOLDERS = false;
        DEFAULT_FILE_EXTENSIONS = -1;
        DEFAULT_FULL_FILE_PATHS = 'compressed';
        IN_MEMORY_FULL_FILE_PATHS = 'in-memory';
        DEFAULT_FILE_SPLIT_SIZE = 'file';
        FILE_SPLIT_SIZE_NV_NAME = 'FileSplitSize';
        INCLUDE_SUBFOLDERS_NV_NAME = 'IncludeSubfolders';
        FILE_EXTENSIONS_NV_NAME = 'FileExtensions';
        FULL_FILE_PATHS_NV_NAME = 'FullFilePaths';
        M_FILENAME = mfilename;
    end

    properties (Access = private)
        % An internal fileset object chosen by this FileSet object
        InternalFileSet
        % Logical to indicate whether to copy internal fileset or not
        DoNotCopyInternalFileSet = false
    end

    methods
        function fs = FileSet(location, varargin)
            % Constructor
            import matlab.io.datastore.internal.fileset.ResolvedFileSetFactory;
            try
                nvStruct = iParseNameValues(varargin);
                nvStruct.FileSplitSize = 'file';
                if isa(location, "matlab.io.datastore.internal.fileset.CompressedFileSet") || ...
                        isa(location, "matlab.io.datastore.internal.fileset.InMemoryFileSet")
                    fs.InternalFileSet = location;
                else
                    % Choose an internal fileset object built by the ResolvedFileSetFactory.
                    fs.InternalFileSet = ResolvedFileSetFactory.build(location, ...
                        nvStruct);
                end
            catch ME
                throw(ME);
            end
        end

        function N = maxpartitions(fs)
            %MAXPARTITIONS Return the maximum number of partitions possible for FileSet.
            %
            %   N = MAXPARTITIONS(FS) returns the maximum number of partitions 
            %   for a given FileSet, FS.
            %
            %   Example:
            %   --------
            %      folder = fullfile(matlabroot,'toolbox','matlab','demos');
            %      files = fullfile(folder, {'patients.mat','accidents.mat'});
            %
            %      fs = matlab.io.datastore.FileSet(files);
            %      isequal(fs.NumFiles, maxpartitions(fs))
            %
            %      % find the maximum number of partitions provided by the fileset for the 2 files
            %      n = maxpartitions(fs);
            %      subfs_1 = partition(fs, n, 1)    % subfs_1 contains the first partition off of n partitions
            %      subfs_2 = partition(fs, n, 2)    % subfs_2 contains the second partition off of n partitions
            %
            %   See also partition, matlab.io.datastore.FileSet, 
            %            matlab.io.datastore.Partitionable.
            try
                N = maxpartitions(fs.InternalFileSet);
            catch ME
                throw(ME);
            end
        end

        function subfs = subset(fs, indices)
            %SUBSET Subset a file set using file indices.
            %   SUBFS = SUBSET(FS, INDICES) creates a deep copy of the input 
            %   file set, FS, resulting in the file set SUBFS that contains
            %   files corresponding to INDICES.
            %
            %   Example: Subset the first 4 files
            %   ----------------------------------
            %      folders = fullfile(matlabroot,'toolbox','matlab',{'demos','imagesci'});
            %      exts = {'.jpg','.png','.tif'};
            %      fs = matlab.io.datastore.FileSet(folders,'FileExtensions',exts)
            %      % subfs contains the first 4 files
            %      subfs = subset(fs, 1:4)
            %
            %   Example: Subset the first 60% randomly selected files
            %   -----------------------------------------------------
            %      folders = fullfile(matlabroot,'toolbox','matlab',{'demos','imagesci'});
            %      exts = {'.jpg','.png','.tif'};
            %      fs = matlab.io.datastore.FileSet(folders,'FileExtensions',exts)
            %      n = maxpartitions(fs);
            %      indices = randperm(n);
            %      st = round(0.6 * n);
            %      subfs = subset(fs, indices(1:st))
            %
            %   See also matlab.io.datastore.ImageDatastore/subset,
            %            matlab.io.datastore.FileSet/partition,
            %            matlab.io.datastore.FileSet,
            %            matlab.io.datastore.Partitionable.
            import matlab.io.datastore.internal.validators.validateSubsetIndices;
            indices = validateSubsetIndices(indices, maxpartitions(fs), mfilename, false);
            subfs = copy(fs);
            newCopy = copyAndOrShuffle(subfs, double(indices));
            if ~isempty(newCopy)
                % Ensure that any unnecessary folders are removed from the
                % Folders property on the next get.Folders.
                newCopy.InternalFileSet.setRecalculateFolders(true);

                numSplits = numSplitsForSubset(newCopy.InternalFileSet, indices);
                setNumSplits(newCopy.InternalFileSet,numSplits);
                subfs = newCopy;
            end
        end

        function subfs = partition(fs, N, ii)
            %PARTITION Return a partitioned part of the file set object.
            %
            %   SUBFS = PARTITION(FS,NUMPARTITIONS,INDEX) partitions FS into
            %   NUMPARTITIONS parts and returns the partitioned file set,
            %   SUBFS, corresponding to INDEX. An estimate for a reasonable
            %   value for the NUMPARTITIONS input can be obtained by using
            %   the NUMFILES property of the file set.
            %
            %   Example:
            %   --------
            %      folder = fullfile(matlabroot,'toolbox','matlab','demos');
            %
            %      % fs contains 41 files
            %      fs = matlab.io.datastore.FileSet(folder,'IncludeSubfolders',true,'FileExtensions','.mat');
            %
            %      % partition the 41 files into 5 partitions and obtain the first portion
            %      subfs_1 = partition(fs, 5, 1)       % subfs contains the first 9 files
            %      allSubfsFiles_1 = subfs_1.FileInfo  % Obtain the file name and file size of all the 9 files
            %
            %      % partition the 41 files into 5 partitions and obtain the second portion
            %      subfs_2 = partition(fs, 5, 2)       % subfs contains the second 8 files
            %      allSubfsFiles_2 = subfs_2.FileInfo  % Obtain the file name and file size of all the 8 files
            %
            %   See also resolve, matlab.io.Datastore,
            %            matlab.io.datastore.FileSet/maxpartitions,
            %            matlab.io.datastore.FileSet/subset,
            %            matlab.io.datastore.FileSet,
            %            matlab.io.datastore.Partitionable.
            try
                subfs = copy(fs);
                subfs.InternalFileSet = partition(fs.InternalFileSet, N, ii);
            catch ME
                throw(ME);
            end
        end

        function fileInfo = nextfile(fs)
            %NEXTFILE Returns the next file information available in the file set object.
            %   NF = NEXTFILE(FS) returns the next consecutive file 
            %   information from FS. NF is a matlab.io.datastore.FileInfo 
            %   with properties, Filename and FileSize.
            %   NEXTFILE(FS) errors if there are no more files in the file 
            %   set object. FS and should be used with hasNextFile(FS) and
            %   reset(FS).
            %
            %   Example:
            %   --------
            %      folder = fullfile(matlabroot,'toolbox','matlab','demos');
            %      fs = matlab.io.datastore.FileSet(folder,'IncludeSubfolders',true,'FileExtensions','.mat');
            %
            %      while hasNextFile(fs)
            %         file = nextfile(fs); % Obtain one file at a time
            %      end
            %
            %   See also hasNextFile, previousfile, matlab.io.Datastore,
            %            matlab.io.datastore.FileSet,
            %            matlab.io.datastore.Partitionable.
            try
                [fName, fSize] = nextfile(fs.InternalFileSet);
                fileInfo = matlab.io.datastore.FileInfo(fName, fSize);
            catch ME
                if ME.identifier == "MATLAB:datastoreio:dsfileset:noMoreFiles"
                    error(message("MATLAB:datastoreio:dsfileset:noMoreInfo", ...
                        "files","hasNextFile","nextfile"));
                else
                    throwAsCaller(ME);
                end
            end
        end

        function file = previousfile(fs)
            %PREVIOUSFILE Returns the previous file information in the file set object.
            %   PF = PREVIOUSFILE(FS) returns the previous file
            %   information from FS. PF is a matlab.io.datastore.FileInfo
            %   object with properties, Filename and FileSize.
            %   PREVIOUSFILE(FS) errors when called at the start of the
            %   file set. FS should be used with hasPreviousFile(FS) and
            %   reset(FS).
            %
            %   Example:
            %   --------
            %      folder = fullfile(matlabroot,'toolbox','matlab','demos');
            %      fs = matlab.io.datastore.FileSet(folder,'IncludeSubfolders',true,'FileExtensions','.mat');
            %
            %      while hasNextFile(fs)    % Traverse to the end of the file set
            %         nextfile(fs);  
            %      end
            %
            %      while hasPreviousFile(fs)
            %         file = previousfile(fs);  % Obtain one file at a time
            %      end
            %
            %   See also nextfile, hasPreviousFile, matlab.io.Datastore,
            %            matlab.io.datastore.FileSet,
            %            matlab.io.datastore.Partitionable.
            try
                [fName, fSize] = previousfile(fs.InternalFileSet);
                file = matlab.io.datastore.FileInfo(fName, fSize);
            catch ME
                if ME.identifier == "MATLAB:datastoreio:dsfileset:noPreviousFiles"
                    error(message("MATLAB:datastoreio:dsfileset:noPreviousInfo","files","nextfile"));
                else
                    throwAsCaller(ME);
                end
            end
        end

        function tf = hasNextFile(fs)
            %HASNEXTFILE Returns true if there is more file information not yet obtained from the file set object.
            %   TF = hasNextFile(FS) returns true if the file set has one 
            %   or more files available to obtain with the nextfile method.
            %   nextfile(FS) returns an error when hasNextFile(FS) returns false.
            %
            %   Example:
            %   --------
            %      folder = fullfile(matlabroot,'toolbox','matlab','demos');
            %      fs = matlab.io.datastore.FileSet(folder,'IncludeSubfolders',true,'FileExtensions','.mat');
            %
            %      while hasNextFile(fs)
            %         file = nextfile(fs);  % Obtain one file at a time
            %      end
            %
            %   See also nextfile, hasPreviousFile, matlab.io.Datastore,
            %            matlab.io.datastore.FileSet,
            %            matlab.io.datastore.Partitionable.
            tf = hasNextFile(fs.InternalFileSet);
        end

        function tf = hasPreviousFile(fs)
            %HASPREVIOUSFILE Returns true if there is previous file information that has been obtained from the file set object.
            %   TF = hasPreviousFile(FS) returns true if the file set has 
            %   one or more files available to obtain with the previousfile
            %   method. previousfile(FS) returns an error when
            %   hasPreviousFile(FS) returns false.
            %
            %   Example:
            %   --------
            %      folder = fullfile(matlabroot,'toolbox','matlab','demos');
            %      fs = matlab.io.datastore.FileSet(folder,'IncludeSubfolders',true,'FileExtensions','.mat');
            %
            %      while hasNextFile(fs)
            %         nextfile(fs);
            %      end
            %
            %      while hasPreviousFile(fs)
            %         file = previousfile(fs);  % Obtain one file at a time
            %      end
            %
            %   See also previousfile, hasNextFile, matlab.io.Datastore,
            %            matlab.io.datastore.FileSet,
            %            matlab.io.datastore.Partitionable.
            tf = hasPreviousFile(fs.InternalFileSet);
        end

        function reset(fs)
            %RESET Reset the file set to the start of the files information in the file set object.
            %   RESET(FS) resets FS to the beginning of the file set.
            %
            %   Example:
            %   --------
            %      folder = fullfile(matlabroot,'toolbox','matlab','demos');
            %      fs = matlab.io.datastore.FileSet(folder,'IncludeSubfolders',true,'FileExtensions','.mat');
            %
            %      ft = cell(fs.NumFiles,1);
            %      i = 1;
            %      while hasNextFile(fs)       % Get files using a while-loop
            %          ft{i} = nextfile(fs);
            %          i = i + 1;
            %      end
            %      allFiles = vertcat(ft{:});
            %
            %      reset(fs);                  % Reset to the beginning of the fileset
            %      file1 = nextfile(fs)        % Obtain the file name and file size of the first file
            %      file2 = nextfile(fs)        % Obtain the file name and file size of the second file
            %      allfiles = fs.FileInfo      % Obtain the file name and file size of all the files
            %
            %   See also hasNextFile, nextfile, matlab.io.Datastore,
            %            matlab.io.datastore.FileSet,
            %            matlab.io.datastore.Partitionable.
            try
                reset(fs.InternalFileSet);
            catch ME
                throw(ME);
            end
        end

        function frac = progress(fs)
            %PROGRESS   Percentage of consumed data between 0.0 and 1.0.
            %   Return fraction between 0.0 and 1.0 indicating progress as a
            %   double.
            %
            %   See also hasNextFile, nextfile, matlab.io.datastore.FileSet
            frac = fs.NumFilesRead/fs.NumFiles;
        end

        % Getter for AlternateFileSystemRoots
        function aRoots = get.AlternateFileSystemRoots(fs)
            aRoots = fs.InternalFileSet.AlternateFileSystemRoots;
        end

        % Setter for AlternateFileSystemRoots
        function set.AlternateFileSystemRoots(fs, aRoots)
            fs.InternalFileSet.AlternateFileSystemRoots = aRoots;
        end

        % Setter for RecalculateFolders
        function set.RecalculateFolders(fs, recalculateFolders)
            if ~isempty(fs.InternalFileSet)
                fs.InternalFileSet.setRecalculateFolders(recalculateFolders);
            end
        end

        % Getter for NumFiles
        function nfiles = get.NumFiles(fs)
            nfiles = fs.InternalFileSet.NumFiles;
        end

        % Getter for NumFilesRead
        function nfilesread = get.NumFilesRead(fs)
            nfilesread = fs.InternalFileSet.NumBlocksRead;
        end

        % Getter for FileInfo
        function fileInfo = get.FileInfo(fs, varargin)
            [fName, fSize] = resolveInfo(fs.InternalFileSet, varargin{:});
            fileInfo = matlab.io.datastore.FileInfo(fName, fSize);
        end

        % Forward to the underlying FileSet to get the value of the Folders
        % property.
        function folders = get.Folders(fs)
            folders = fs.InternalFileSet.Folders;
        end
    end

    methods (Access = protected)
        function cpObj = copyElement(fs)
            cpObj = copyElement@matlab.mixin.Copyable(fs);
            if ~fs.DoNotCopyInternalFileSet
                cpObj.InternalFileSet = copy(fs.InternalFileSet);
            end
        end

        function link = propDisplayLink(~, name, propname)
            %PROPDISPLAYLINK get a link for displaying a property
            msg = getString(message('MATLAB:graphicsDisplayText:FooterLinkFailureMissingVariable', name));
            codeToExecute = sprintf(['if exist(''' name ''',''var''),%%s,else,fprintf(''%s\\\\n'');end'], msg);
            codeToExecute = sprintf(codeToExecute,"fprintf('" + name + "." + propname + " = \n\n');dispFileInfo("+name+")");
            link = sprintf('<a href="matlab:%s" style="font-weight:bold">%s</a>', codeToExecute, propname);
        end
    end

    methods (Access = {?matlab.io.datastore.internal.fileset.ResolvedFileSetFactory})
        function setInternalFileSet(fs, internalFileSet)
            %SETINTERNALFILESET Set the internal fileset object created by ResolvedFileSetFactory.
            fs.InternalFileSet = internalFileSet;
        end
    end

    methods (Access = {?matlab.io.datastore.splitter.Splitter, ...
            ?matlab.io.datastore, ?matlab.io.Datastore, ...
            ?matlab.io.datastore.FileSet, ...
            ?matlab.io.datastore.internal.fileset.ResolvedFileSet, ...
            ?matlab.io.datastore.internal.util.SubsasgnableFileSet, ...
            ?matlab.io.datastore.Partitionable})

        function setFilesAndFileSizes(fs, varargin)
            %SETFILESANDFILESIZES Set the files and file sizes for the fileset object.
            %   This is useful when creating an empty file set object and setting the
            %   valid folders and files that are already resolved without any need for
            %   file existence or validity.
            fs.InternalFileSet.setFilesAndFileSizes(varargin{:});
        end

        function setFileSizes(fs, varargin)
            %SETFILESIZES Set the file sizes for the fileset object.
            fs.InternalFileSet.setFileSizes(varargin{:});
        end

        function fileSizes = getFileSizes(fs, indices)
            %GETFILESIZES Get the file sizes from the fileset object.
            %   If a set of indices are given just get those file sizes or just
            %   get all the file sizes.
            if nargin == 2
                fileSizes = fs.InternalFileSet.getFileSizes(indices);
            else
                fileSizes = fs.InternalFileSet.getFileSizes;
            end
        end

        function files = getFiles(fs, ii)
            %GETFILES Get the file paths from the fileset object.
            %   If a set of indices are given just get those files or just
            %   get all the files.
            files = fs.InternalFileSet.getFiles(ii);
        end

        function newCopy = copyAndOrShuffle(fs, varargin)
            %COPYANDORSHUFFLE This copies the current object, with or without shuffling.
            %   Based on the inputs fileset object can decide to either copy
            %   and/or shuffle the fileset. If just shuffling is done, then the output
            %   of this function is empty since a copy is not created.
            internalFileSetCpy = fs.InternalFileSet.copyAndOrShuffle(varargin{:});
            if isempty(internalFileSetCpy)
                newCopy = [];
                return;
            end
            newCopy = copy(fs);
            newCopy.InternalFileSet = internalFileSetCpy;
        end

        function newCopy = copyWithFileIndices(fs, varargin)
            %COPYWITHFILEINDICES This copies the current object using the input indices.
            %   Based on the input indices fileset object creates a copy.
            internalFileSetCpy = fs.InternalFileSet.copyWithFileIndices(varargin{:});
            newCopy = copy(fs);
            newCopy.InternalFileSet = internalFileSetCpy;
        end

        function setShuffledIndices(fs, varargin)
            %SETSHUFFLEDIINDICES Set the shuffled indices for the fileset object.
            %   Any subsequent nextfile calls to the fileset object gets the files
            %   using the shuffled indices.
            fs.InternalFileSet.setShuffledIndices(varargin{:});
        end

        function setDuplicateIndices(fs, varargin)
            %SETDUPLICATEINDICES Set the duplicate indices for the fileset object.
            %   Any subsequent nextfile calls to the fileset object gets the files
            %   using the already existing indices and duplicate indices.
            fs.InternalFileSet.setDuplicateIndices(varargin{:});
            if nargin < 3
                numSplits = fs.InternalFileSet.numSplitsForSubset(varargin{1});
            elseif nargin < 4
                numSplits = fs.InternalFileSet.numSplitsForSubset(varargin{2});
            end
            setNumSplits(fs.InternalFileSet,numSplits);
        end

        function setHoldPartitionIndices(fs, tf)
            %SETHOLDPARTITIONINDICES Set logical value to whether hold partition indices or not.
            %   This will set the logical value on the fileset object, indicating whether
            %   partition indices must be held by the fileset or not.
            fs.InternalFileSet.setHoldPartitionIndices(tf);
        end

        function clearPartitionIndices(fs)
            %CLEARPARTITIONINDICES Clears the partition indices held by the fileset object.
            %   This will clear the partition indices held by the fileset object.
            fs.InternalFileSet.clearPartitionIndices;
        end

        function indices = getPartitionIndices(fs)
            %GETPARTITIONINDICES Gets the partition indices held by the fileset object.
            %   setHoldPartitionIndices(true) must have been called prior to this
            %   to get non-empty values from this function.
            indices = fs.InternalFileSet.getPartitionIndices;
        end

        function setDoNotCopyInternalFileSet(fs, tf)
            fs.DoNotCopyInternalFileSet = tf;
        end

        function updateFoldersProperty(fs)
            fs.InternalFileSet.updateInternalFoldersProperty();
        end

    end

    methods(Hidden)
        function disp(fs)
            %DISP controls the display of the FileSet.
            h = matlab.internal.datatypes.DisplayHelper(class(fs));
            addPropertyGroupNoTitle(h, fs, {'NumFiles','NumFilesRead', ...
                                'FileInfo','AlternateFileSystemRoots'});
            if h.usingHotlinks()
                fileInfoLink = fs.propDisplayLink(inputname(1), "FileInfo");
                replacePropDisp(h,"FileInfo",sprintf("Show %s for all %d files", ...
                    fileInfoLink, fs.NumFiles));
            else
                fileInfoLink = "FileInfo";
                replacePropDisp(h,"FileInfo",sprintf("%s for all %d files", ...
                    fileInfoLink, fs.NumFiles));
            end

            h.printToScreen("FileSet",false);
        end

        function dispFileInfo(fs)
            % Render the table display into a string.
            fh = feature('hotlinks');
            tempVar = fs.FileInfo;
            tempVar = table(tempVar.Filename, tempVar.FileSize, ...
                'VariableNames',{'Filename','FileSize'});
            if fh
                disp(tempVar);
            else
                % For no desktop, use hotlinks off on evalc to get rid of
                % xml attributes for display, like, <strong>Var1</strong>, etc.
                disp(evalc('feature hotlinks off; disp(tempVar);'));
                feature('hotlinks', fh);
            end
        end
    end

    methods(Hidden, Static)
        function fs = empty(varargin)
            % Create an empty FileSet
            if nargin == 0 || (nargin == 2 && varargin{1} == 0 && varargin{2} == 1)
                fs = matlab.io.datastore.FileSet({});
            else
                error(message('MATLAB:class:EmptyScalar', ...
                    'matlab.io.datastore.FileSet','matlab.io.datastore.FileSet'));
            end
        end
    end
end

function parsedStruct = iParseNameValues(args)
    % Parse the FileSet Name-Value pairs using inputParser
    import matlab.io.datastore.FileSet;
    persistent inpP;
    if isempty(inpP)
        inpP = inputParser;
        addParameter(inpP, FileSet.INCLUDE_SUBFOLDERS_NV_NAME, FileSet.DEFAULT_INCLUDE_SUBFOLDERS);
        addParameter(inpP, FileSet.FILE_EXTENSIONS_NV_NAME, FileSet.DEFAULT_FILE_EXTENSIONS);
        addParameter(inpP, FileSet.FULL_FILE_PATHS_NV_NAME, FileSet.DEFAULT_FULL_FILE_PATHS);
        addParameter(inpP, 'AlternateFileSystemRoots', {});
        inpP.FunctionName = FileSet.M_FILENAME;
    end
    [args{:}] = convertStringsToChars(args{:});
    parse(inpP, args{:});
    parsedStruct = inpP.Results;
    parsedStruct.UsingDefaults = inpP.UsingDefaults;
    parsedStruct.FullFilePaths = validatestring(parsedStruct.FullFilePaths, ...
        {FileSet.IN_MEMORY_FULL_FILE_PATHS, FileSet.DEFAULT_FULL_FILE_PATHS},...
        FileSet.M_FILENAME, FileSet.FULL_FILE_PATHS_NV_NAME);
end
