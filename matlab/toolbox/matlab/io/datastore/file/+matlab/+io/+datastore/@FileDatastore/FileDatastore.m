classdef (Sealed) FileDatastore < ...
                  matlab.io.datastore.CustomReadDatastore & ...
                  matlab.io.datastore.FoldersPropertyProvider & ...
                  matlab.io.datastore.mixin.CrossPlatformFileRoots & ...
                  matlab.io.datastore.internal.ScalarBase & ...
                  matlab.mixin.CustomDisplay & ...
                  matlab.io.datastore.Shuffleable & ...
                  matlab.io.datastore.FileWritable
%FILEDATASTORE Datastore for a collection of files with custom data format.
%   FDS = fileDatastore(LOCATION,'ReadFcn',@MYCUSTOMREADER) creates a
%   FileDatastore if a file or a collection of files are present in LOCATION.
%   LOCATION has the following properties:
%      - Can be a filename or a folder name
%      - Can be a cell array or string vector of multiple file or folder names
%      - Can be a matlab.io.datastore.DsFileSet object
%      - Can be a matlab.io.datastore.FileSet object
%      - Can contain a relative path (HDFS requires a full path)
%      - Can contain a wildcard (*) character.
%      - Can be a remote location specified using an internationalized
%        resource identifier (IRI). For more information on accessing remote
%        data, see "Read Remote Data" in the documentation.
%   'ReadFcn',@MYCUSTOMREADER Name-Value pair specifies the user-defined
%   function to read files. By default, the value of 'ReadFcn' must be a
%   function handle with a signature similar to the following:
%      function data = MYCUSTOMREADER(filename)
%          ...
%      end
%   If the 'ReadMode' name-value pair has been set, the 'ReadFcn' signature
%   may change from the above value. See the 'ReadMode' name-value pair below
%   for more information about this.
%
%   FDS = fileDatastore(__,'UniformRead',TF) specifies the logical
%   true or false to indicate whether multiple reads of FileDatastore will
%   return uniform data that can be vertically concatenated. The default
%   value is false. If true, the ReadFcn must return vertically concatenable
%   data or the readall method will error. If true, the readall method will
%   return vertically concatenated data, otherwise returns a cell array with
%   data from each read method call added to the cell array.
%
%   FDS = fileDatastore(__,'IncludeSubfolders',TF) specifies the logical
%   true or false to indicate whether the files in each folder and its
%   subfolders are included recursively or not.
%
%   FDS = fileDatastore(__,'FileExtensions',EXTENSIONS) specifies the
%   extensions of files to be included. Values for EXTENSIONS can be:
%      - A character vector or string scalar, such as '.jpg' or '.png'
%        (empty quotes '' are allowed for files without extensions)
%      - A cell array of character vectors or a string vector, such as {'.jpg', '.mat'}
%
%   FDS = fileDatastore(__,'AlternateFileSystemRoots',ALTROOTS) specifies
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
%   FDS = fileDatastore(__,'PreviewFcn',@MYCUSTOMPREVIEWER) customizes the
%   function that is executed when previewing the FileDatastore. The 'PreviewFcn'
%   must return data with a similar type as the 'ReadFcn'.
%   The signature of the 'PreviewFcn' also depends on the 'ReadMode' of the
%   FileDatastore. By default (with 'ReadMode' set to 'file') the value of
%   'PreviewFcn' must be a function handle with a signature similar to:
%      function data = MYCUSTOMPREVIEWER(filename)
%          ...
%      end
%   If a custom function handle has not been specified using the 'PreviewFcn'
%   name-value pair, the 'ReadFcn' is executed instead when the FileDatastore
%   is previewed.
%
%   FDS = fileDatastore(__,'ReadMode',MODE) specifies the behavior of the
%   read operations. You can choose to read the full file with every read
%   operation, or read the file in chunks. Specify MODE as one of these values:
%
%      - 'file' (default): Read a full file with every read operation. This
%         is the default behavior. The 'ReadFcn' must have the following
%         signature:
%
%             function data = MYCUSTOMREADER(filename) 
%                 ...
%             end
% 
%      - 'partialfile': Read a portion of a file with every read operation.
%         This facilitates serially reading chunks of data from a single
%         large file in parts. The 'ReadFcn' must have the following
%         signature:
%
%             function [data, userdata, done] = MYCUSTOMREADER(filename, userdata) 
%                 ... 
%             end
%
%          MYCUSTOMREADER must accept filename and userdata.
%           'filename' is the name of the file to read. The 'userdata' input
%            argument can be set to any value. On subsequent reads of the
%            same file, this input argument is populated using the value of
%            the 'userdata' output argument from the preceding read of the
%            same file. Use 'userdata' to maintain state between multiple
%            reads of the same file. 
%          MYCUSTOMREADER must return three output arguments.
%           'data' contains a portion of data from the file specified in
%           'filename'. 'userdata' can contain updated information about the 
%            read operation that can be used in the next read. 'done' is a 
%            logical flag indicating that the specified file has been read
%            completely.
% 
%      - 'bytes': Read portions of large files in parallel.
%           A single file can be partitioned into multiple subset datastores 
%           after building a FileDatastore with the 'bytes' ReadMode. 
%           This is a byte-offset based mode, where the
%           'ReadFcn' signature should look like the following:
% 
%             function data = MYCUSTOMREADER(filename, offset, size) 
%                 ...
%             end
% 
%          Here MYCUSTOMREADER must accept three input arguments.
%           'offset' specifies the byte offset from the first byte in
%           the file, and 'size' specifies the number of bytes that
%           should be read during the current read operation. The
%           'offset' and 'size' ReadFcn inputs are automatically
%           incremented by the FileDatastore using the value specified 
%           in the 'BlockSize' name-value pair.
%
%   FDS = fileDatastore(__,'BlockSize',SIZE) specifies the number of bytes
%   that should be read by the 'ReadFcn' during each FileDatastore read
%   call. The BlockSize can only be modified if the 'ReadMode' is set to
%   'bytes'. 
%   The default value of BlockSize depends on the ReadMode:
%    - If ReadMode is 'file' and 'partialfile', then BlockSize is Inf 
%    - If ReadMode is 'bytes', the default value of BlockSize is 128 MB.
%
%
%   FileDatastore Properties:
%
%      Files                    - Cell array of character vectors of file names. You
%                                 can also set this property using a string array.
%      Folders                  - The input folders used to construct this datastore.
%                                 Specifies the folders to be duplicated during writeall.
%      AlternateFileSystemRoots - Alternate file system root paths for the Files.
%      ReadFcn                  - Function handle used to read files.
%      PreviewFcn               - Function handle used to preview files.
%      UniformRead              - Indicates whether or not the output of multiple
%                                 read method calls can be vertically concatenated.
%      ReadMode                 - Defines how the read functions reads from
%                                 the datastore: 'file', 'partialfile', or 
%                                 'bytes'.
%      BlockSize                - Indicates the maximum number of bytes that 
%                                 should be read from each file during each read. 
%                                 This property is read-only unless the 'ReadMode' 
%                                 is set to 'bytes'.
%      SupportedOutputFormats   - List of formats supported for writing
%                                 by this datastore.
%
%   FileDatastore Methods:
%
%      hasdata         - Returns true if there is more data in the datastore
%      read            - Reads the next consecutive file
%      reset           - Resets the datastore to the start of the data
%      preview         - Reads the first file from the datastore for preview
%      readall         - Reads all of the files from the datastore
%      partition       - Returns a new datastore that represents a single
%                        partitioned portion of the original datastore
%      numpartitions   - Returns an estimate for a reasonable number of
%                        partitions according to the total data size to use
%                        with the partition function
%      transform       - Create an altered form of the current datastore by
%                        specifying a function handle that will execute
%                        after read on the current datastore.
%      combine         - Create a new datastore that horizontally
%                        concatenates the result of read from two or more
%                        input datastores.
%      isPartitionable - Returns true if this datastore is partitionable.
%                        FileDatastore is always partitionable.
%      isShuffleable   - Returns true if this datastore is shuffleable.
%                        FileDatastore is not shuffleable.
%      writeall        - Writes all the data in the datastore to a new 
%                        output location.
%      subset          - Return a new FileDatastore that contains only the
%                        files corresponding to the input indices. Only
%                        available when the FileDatastore is in the "file"
%                        ReadMode.
%      shuffle         - Return a new FileDatastore that shuffles all the
%                        Files in the original FileDatastore. Only available
%                        when the FileDatastore is in the "file" ReadMode.
%
%
%   Example 1:
%   ----------
%      folder = fullfile(matlabroot,'toolbox','matlab','demos');
%      fds = fileDatastore(folder,'ReadFcn',@load,'FileExtensions','.mat');
%
%      data1 = read(fds);                   % Read the first MAT-file
%      data2 = read(fds);                   % Read the next MAT-file
%      readall(fds)                         % Read all of the MAT-files
%      dataArr = cell(numel(fds.Files),1);
%      i = 1;
%      reset(fds);                          % Reset to the beginning of data
%      while hasdata(fds)                   % Read files using a while-loop
%          dataArr{i} = read(fds);
%          i = i + 1;
%      end
%
%   Example 2:
%   ----------
%      % Read a 12 MB file using the different FileDatastore ReadModes.
%      filename = fullfile(matlabroot, 'toolbox','matlab', 'demos', 'airlinesmall.csv');
%
%      ds1 = fileDatastore(filename,'ReadFcn',@(f,g,h)readtable(f),'ReadMode','bytes',...
%                          'BlockSize', 1024 * 1024); % 1 MB block size.
%      disp(numpartitions(ds1));                      % 12 partitions are generated
%
%      ds2 = fileDatastore(filename,'ReadFcn',@readtable,'ReadMode','file');
%      disp(numpartitions(ds2));                      % Entire file is in one partition
%
%      ds3 = fileDatastore(filename,'ReadFcn',@(f,g)readtable(f),'ReadMode','partialfile');
%      disp(numpartitions(ds3));                      % Entire file is in one partition
%
%   See also datastore, mapreduce, load, fileDatastore.

%   Copyright 2015-2023 The MathWorks, Inc.

    properties (Dependent)
        %Files
        % A cell array of character vectors of file names. You can also set
        % this property using a string array.
        Files;
    end

    properties (Access = private)
        %UnResolvedFiles
        % Deployment needs a way to get files before resolving them.
        UnResolvedFiles;

        %BufferedZero1DimData
        % preview and readall methods needs buffered data with zero first
        % dimension if UniformRead is true.
        BufferedZero1DimData;
    end

    properties (SetAccess = private)
        %UniformRead
        % Indicates whether multiple reads of FileDatastore will
        % return uniform data that can be vertically concatenated.
        % The default value is false. If true, the ReadFcn must return
        % vertically concatenable data or the readall method will error.
        % If true, the readall method will return vertically concatenated
        % data, otherwise returns a cell array with data from each read
        % method call added to the cell array.
        UniformRead = false; %  Loading objects saved in previous versions will just have the default value.

        %ReadMode
        % Determines the ReadFcn signature and FileDatastore partitioning
        % behavior.
        ReadMode(1, :) char {mustBeMember(ReadMode, ...
            {'file', 'partialfile', 'bytes'})} = 'file';
    end

    properties
        %BlockSize
        % Defines the number of bytes to be read during each read method call.
        % Can only be customized to a specific numeric value if 'ReadMode' is
        % 'bytes'. Otherwise set to Inf for the 'file' and 'partialfile' read modes.
        BlockSize(1, 1) {mustBeNumeric, mustBeReal, mustBePositive} = Inf;

        %PreviewFcn
        % A function handle that gets executed when the preview method
        % is called. Must take the same input arguments, and return
        % output data with the same datatypes as the ReadFcn.
        PreviewFcn;
    end

    properties (Constant, Access = private)
        WHOLE_FILE_CUSTOM_READ_SPLITTER_NAME = 'matlab.io.datastore.splitter.WholeFileCustomReadSplitter';
        PARTIAL_FILE_CUSTOM_READ_SPLITTER_NAME = 'matlab.io.datastore.splitter.PartialFileCustomReadSplitter';
        BYTE_BASED_CUSTOM_READ_SPLITTER_NAME = 'matlab.io.datastore.splitter.ByteBasedCustomReadSplitter';
        CONVENIENCE_CONSTRUCTOR_FCN_NAME = 'fileDatastore';
    end

    properties (Hidden)
        ReadFailureRule;
        MaxFailures;
    end

    properties (Constant)
        %SUPPORTEDOUTPUTFORMATS list of formats supported by this datastore
        SupportedOutputFormats = matlab.io.datastore.internal.FileWritableSupportedOutputFormats.SupportedOutputFormats;
    end

    properties (Constant, Hidden)
        DefaultOutputFormat = string(missing);
    end

    % Constructor
    methods
        % FileDataStore can be constructed with files argument, optionally
        % with ReadFcn, IncludeSubfolders, FileExtensions Name-Value pairs.
        function fds = FileDatastore(files, varargin)
            try
                matlab.io.datastore.internal.throwFileSetMustBeScalarError(files);
                files = matlab.io.datastore.FileBasedDatastore.convertFileSetToFiles(files);
                % string adoption - convert all NV pairs specified as
                % string to char
                files = convertStringsToChars(files);
                [varargin{:}] = convertStringsToChars(varargin{:});
                nv = iParseNameValues(varargin{:});
                location = files;
                initDatastore(fds, files, nv);
                % Populate the Folders property.
                fds.populateFoldersFromResolvedPaths(location, {}, fds.Files);
                fds.AlternateFileSystemRoots = nv.AlternateFileSystemRoots;
                fds.UnResolvedFiles = files;
            catch e
                throwAsCaller(e);
            end
        end
    end

    % Set and Get methods for properties
    methods
        % Set method for Files
        function set.Files(fds, files)
            try
                [diffIndexes, ~, files, fileSizes, diffPaths] = setNewFilesAndFileSizes(fds, files);
                files(diffIndexes) = diffPaths;
                initFromReadFcnAndReadMode(fds, fds.ReadFcn, files, fileSizes, false, fds.BlockSize);

                % Recompute the Folders property on the next get.Folders.                
                fds.updateFoldersProperty();
            catch e
                throw(e)
            end
        end
        % Get Files
        function files = get.Files(fds)
            files = fds.Splitter.Files;
        end
        % ReadFailureRule getter
        function readfailrule = get.ReadFailureRule(ds)
            readfailrule = ds.PrivateReadFailureRule;
        end
        % MaxFailures getter
        function maxfails = get.MaxFailures(ds)
            maxfails = ds.PrivateMaxFailures;
        end

        % Set method for PreviewFcn
        % Perform validation here for correct number of input and output arguments.
        function set.PreviewFcn(fds, fcn)
            try
                validateFcnFromConstructor(fds, fcn, false, 'PreviewFcn');

                fds.PreviewFcn = fcn;
            catch ME
                throw(ME);
            end
        end

        % Set method for BlockSize
        % Can only be set if 'ReadMode' is 'bytes'.
        function set.BlockSize(fds, newBlockSize)
            try
                if isempty(fds.Splitter)
                    % loadobj codepath on threads. Avoid cross-validation
                    % and return early.
                    fds.BlockSize = newBlockSize;
                    return;
                end

                % validate blocksize value
                newBlockSize = iValidateBlockSize(newBlockSize, fds.ReadMode);

                % return immediately if blockSize is unchanged (no need to recompute splits).
                if ~isequal(fds.BlockSize, newBlockSize)
                    fds.BlockSize = double(newBlockSize);

                    % recompute splits for the datastore.
                    initFromReadFcnAndReadMode(fds, fds.ReadFcn, fds.Files, [], ...
                                               false, fds.BlockSize);
                end
            catch ME
                throw(ME);
            end
        end
        
        function writeall(ds, location, varargin)
            %WRITEALL    Read all the data in the datastore and write to disk
            %   WRITEALL(DS, OUTPUTLOCATION, "OutputFormat", FORMAT) writes 
            %   files to the specified output folder using the
            %   specified output format. The allowed FORMAT values are:
            %     - Tabular formats: "txt", "csv", "xlsx", "xls",
            %     "parquet", "parq"
            %     - Image formats: "png", "jpg", "jpeg", "tif", "tiff"
            %     - Audio formats: "wav", "ogg", "opus", "flac", "mp4",
            %                      "m4a"
            %
            %   WRITEALL(__, "FolderLayout", LAYOUT) specifies whether folders
            %   should be copied from the input data locations. Specify
            %   LAYOUT as one of these values:
            %
            %     - "duplicate" (default): Input folders contained
            %       within the folders listed in the "Folders"
            %       property are copied to the output location.
            %
            %     - "flatten": Files are written directly to the output
            %       location without generating any intermediate folders.
            %
            %   WRITEALL(__, "UseParallel", TF) specifies whether a parallel
            %   pool is used to write data. By default, "UseParallel" is
            %   set to false.
            %
            %   WRITEALL(__, "FilenamePrefix", PREFIX) specifies a common
            %   prefix to be applied to the output file names.
            %
            %   WRITEALL(__, "FilenameSuffix", SUFFIX) specifies a common
            %   suffix to be applied to the output file names.
            % 
            %   WRITEALL(DS, OUTPUTLOCATION, "WriteFcn", @MYCUSTOMWRITER)
            %   customizes the function that is executed to write each 
            %   file. The function signature of the "WriteFcn" must be
            %   similar to:
            %
            %      function MYCUSTOMWRITER(data, writeInfo, outputFmt, varargin)
            %         ...
            %      end
            %
            %   where 'data' is the output of the read method on the
            %   datastore, 'outputFmt'  is the output format to be written,
            %   and 'writeInfo' is a struct containing the
            %   following fields:
            %
            %     - "ReadInfo": the second output of the read method.
            %
            %     - "SuggestedOutputName": a fully qualified, unique file
            %       name that meets the location and naming requirements.
            %
            %     - "Location": the location argument passed to the write
            %       method.
            %   Any optional Name-Value pairs can be passed in via varargin.
            %
            %   See also: matlab.io.Datastore
            import matlab.io.datastore.write.*;
            try
                % Validate the location input first.
                location = validateOutputLocation(ds, location);
                ds.OrigFileSep = matlab.io.datastore.internal.write.utility.iFindCorrectFileSep(location);

                % if this datastore is backed by files, get list of files
                files = getFiles(ds);
                if isempty(files)
                    error(message("MATLAB:io:datastore:write:write:EmptyDatastore"));
                end

                % if this datastore is backed by files, get list of folders
                folders = getFolders(ds);

                % Validate name-value pairs.
                nvStruct = parseWriteallOptions(ds, varargin{:});
                outFmt = ds.SupportedOutputFormats;

                nvStruct = validateWriteallOptions(ds, folders, nvStruct, outFmt);
                
                % Construct the output folder structure.
                createFolders(ds, location, folders, nvStruct.FolderLayout);

                % Write using a serial or parallel strategy.
                writeParallel(ds, location, files, nvStruct);
            catch ME
                % Throw an exception without the full stack trace. If the
                % MW_DATASTORE_DEBUG environment variable is set to 'on',
                % the full stacktrace is shown.
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end
        end
        
        function subds = subset(ds, indices)
        %SUBSET   Subset a FileDatastore using file indices.

            import matlab.io.datastore.internal.validators.validateSubsetIndices;
            try
                indices = validateSubsetIndices(indices, ds.numobservations(), ...
                                                'matlab.io.datastore.FileDatastore');
                ds.verifySubsettable();
            catch ME
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end

            files = ds.Files(indices);
            subds = ds.copy();
            folders = subds.Folders;
            subds.Files = files;

            % Recompute the Folders property on the next get.Folders for convenience.
            subds.Folders = folders;
            subds.RecalculateFolders = true;
        end

        function tf = isShuffleable(ds)
        %isShuffleable   returns true if FileDatastore is shuffleable.
        %
        %   FileDatastore can only be shuffled when in the "file" ReadMode.
        %
        %   See also matlab.io.datastore.Shuffleable.
            tf = ds.ReadMode == "file";
        end

        function shufds = shuffle(ds)
        %SHUFFLE Return a shuffled version of a FileDatastore.
        %
        %   NEWDS = SHUFFLE(DS) returns a randomly shuffled copy of a
        %   FileDatastore.
        %
        %   See also matlab.io.datastore.Shuffleable.

            try
                ds.verifyShuffleable();
            catch ME
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end

            % Compute the subset indices to shuffle.
            indices = randperm(ds.numobservations());
            
            % Return a new datastore with these indices.
            shufds = ds.subset(indices);
        end

        function tf = isSubsettable(ds)
            % Only subsettable in the "file" ReadMode.
            tf = ds.ReadMode == "file";
        end
    end

    methods (Hidden)
        function n = numobservations(ds)
            try
                ds.verifySubsettable();
            catch ME
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end
            n = numel(ds.Files);
        end

        function tf = isequaln(ds, obj2, varargin)
        %ISEQUALN   Return whether input FileDatastore objects are equal,
        %           based on equality of the objects' properties.
        %           FileDatastore inherits from
        %           matlab.io.datastore.FoldersPropertyProvider, which
        %           overrides the default builtin implementation of
        %           isequaln. It is overriden to prevent properties related
        %           to the state of the datastore to affect equality
        %           comparison.
            isFileDatastore = @(x) isa(x, "matlab.io.datastore.FileDatastore");
            
            tf = true;

            % Verify that the object classes are correct and the properties are
            % equal
            if ~isFileDatastore(ds) || ~isFileDatastore(obj2) ...
                    || ~isequaln@matlab.io.datastore.FoldersPropertyProvider(ds, obj2)
                tf = false;
                return
            end

            % Iterate over the rest of the input objects and check equality.
            for objIdx = 1:length(varargin)
                obj = varargin{objIdx};
                if ~isFileDatastore(ds) || ~isFileDatastore(obj) ...
                    || ~isequaln@matlab.io.datastore.FoldersPropertyProvider(ds, obj)
                    tf = false;
                    return
                end
            end
        end
    end

    methods (Access = private)
        function verifySubsettable(ds)
            if ~ds.isSubsettable()
                msgid = "MATLAB:datastoreio:filedatastore:invalidReadModeForSubset";
                error(message(msgid, "subset"));
            end
        end

        function verifyShuffleable(ds)
            if ~ds.isShuffleable()
                msgid = "MATLAB:datastoreio:filedatastore:invalidReadModeForSubset";
                error(message(msgid, "shuffle"));
            end
        end

        function initDatastore(fds, files, nv)
            import matlab.io.datastore.FileDatastore;
            import matlab.io.datastore.internal.validators.validateCustomReadFcn;
            import matlab.io.datastore.internal.validators.validateLogicalOption;

            fds.ReadMode = validatestring(nv.ReadMode, {'file', 'partialfile', 'bytes'}, ...
                FileDatastore.CONVENIENCE_CONSTRUCTOR_FCN_NAME, 'ReadMode');

            fds.UniformRead = validateLogicalOption(nv.UniformRead,...
                'MATLAB:datastoreio:filedatastore:invalidUniformRead');
            readFcn = nv.ReadFcn;
            if ismember('ReadFcn', nv.UsingDefaults) && ...
                    isnumeric(readFcn) && readFcn == -1
                error(message('MATLAB:datastoreio:filedatastore:readFcnNotProvided'));
            end
            validateFcnFromConstructor(fds, readFcn, true, 'ReadFcn');

            [~, files, fileSizes] = FileDatastore.supportsLocationHelper(files, nv);
            fds.TotalFiles = numel(files);

            fds.PrivateReadFailureRule = 'error';
            fds.PrivateMaxFailures = Inf;
            fds.PrivateReadFailuresList = zeros(fds.TotalFiles,1);
            % Files are resolved @supportsLocationHelper
            setCurrentSplitterName(fds);

            % Set BlockSize to a default value if it isn't provided. Validate
            % user-provided BlockSize values.
            blockSize = setBlockSizeDefaults(fds, nv);
            blockSize = iValidateBlockSize(blockSize, fds.ReadMode);

            initFromReadFcnAndReadMode(fds, readFcn, files, fileSizes, ...
                                        nv.IncludeSubfolders, blockSize);

            if ismember('PreviewFcn', nv.UsingDefaults) && ...
                    isnumeric(nv.PreviewFcn) && nv.PreviewFcn == -1
                % PreviewFcn not specified by user; use ReadFcn instead.
                fds.PreviewFcn = fds.ReadFcn;
            else
                validateFcnFromConstructor(fds, nv.PreviewFcn, true, 'PreviewFcn');
                fds.PreviewFcn = nv.PreviewFcn;
            end
            fds.BlockSize = blockSize;

            setBufferedData(fds);
        end

        % use the ReadMode to find and set the current splitter name.
        function setCurrentSplitterName(fds)
            import matlab.io.datastore.FileDatastore;
            switch fds.ReadMode
                case 'file'
                    fds.SplitterName = FileDatastore.WHOLE_FILE_CUSTOM_READ_SPLITTER_NAME;
                case 'partialfile'
                    fds.SplitterName = FileDatastore.PARTIAL_FILE_CUSTOM_READ_SPLITTER_NAME;
                case 'bytes'
                    fds.SplitterName = FileDatastore.BYTE_BASED_CUSTOM_READ_SPLITTER_NAME;
            end
        end

        function blockSize = setBlockSizeDefaults(fds, nv)
            if ismember('BlockSize', nv.UsingDefaults)
                if strcmp(fds.ReadMode, 'bytes')
                    % If ReadMode is bytes and the user hasn't specified a BlockSize,
                    % set it to the HDFS block size.
                    blockSize = 128 * 1024 * 1024;
                else
                    % ReadMode is file or partialfile.
                    blockSize = Inf;
                end
            else
                blockSize = nv.BlockSize;
            end
        end

        function initFromReadFcnAndReadMode(fds, readFcn, files, fileSizes, ...
                                            includeSubFolders, blockSize, oldSplits)
            % The splitters used for each ReadMode have different 'create' method
            % signatures. Therefore we pass different input args to initFromReadFcn
            % based on the ReadMode.
            % Ensure that correct SplitterName is set based on ReadMode.
            setCurrentSplitterName(fds);
            if strcmp(fds.ReadMode, 'bytes')
                % if split information is available, re-use that.
                if nargin < 7
                    initFromReadFcn(fds, readFcn, files, fileSizes, blockSize);
                else
                    initFromReadFcn(fds, readFcn, files, fileSizes, blockSize, oldSplits);
                end
            else
                initFromReadFcn(fds, readFcn, files, fileSizes, includeSubFolders);
            end
        end

        function setBufferedData(fds)
            if ~fds.UniformRead
                % empty cell for non-uniform read
                fds.BufferedZero1DimData = cell(0,1);
                return;
            end
            % empty matrix for an uninitialized SplitReader
            fds.BufferedZero1DimData = zeros(0,1);
            if isempty(fds.SplitReader)
                % This will not happen for empty datastores created from partition
                % of non-empty datastores
                return;
            end
            % Used by preview and readall
            % This subsrefs the value from the first available data
            % using a substruct with zero first dimension.
            if hasNext(fds.SplitReader)
                data = preview(fds);
                reset(fds.SplitReader);
                % colon : for all non-tall dimensions
                col = repmat({':'}, 1, ndims(data) - 1);
                % () subsref'ing with zero 1st dimension.
                substr = substruct('()', [{[]}, col]);
                fds.BufferedZero1DimData = subsref(data, substr);
            end
        end

        function validateFcnBasedOnReadMode(fds, validationFcn)
            switch fds.ReadMode
                case 'file'
                    validationFcn(1, 1);
                case 'partialfile'
                    validationFcn(2, 3);
                case 'bytes'
                    validationFcn(3, 1);
            end
        end
    end

    methods (Access = protected)

        function tf = currentFileIndexComparator(ds, currFileIndex)
            tf = isequal(ds.Splitter.Splits(ds.SplitIdx).FileIndex, currFileIndex);
        end

        function validateReadFcn(fds, readFcn)
            validateFcnFromConstructor(fds, readFcn, false, 'ReadFcn');
        end

        % validates custom ReadFcn based on the ReadMode.
        function validateFcnFromConstructor(fds, readFcn, fromConstructor, fcnName)
            import matlab.io.datastore.FileDatastore;
            import matlab.io.datastore.internal.validators.validateCustomReadFcn;

            validationFcn = @(minInputs, minOutputs) validateCustomReadFcn(readFcn, ...
                                fromConstructor, ...
                                FileDatastore.CONVENIENCE_CONSTRUCTOR_FCN_NAME, ...
                                minInputs, minOutputs, fcnName);

            fds.validateFcnBasedOnReadMode(validationFcn);
        end

        function displayScalarObject(fds)
            %DISPLAYSCALAROBJECT Control the display of the datastore.
            %   This function is used to control the display of the
            %   FileDatastore. It divides the display in a set of groups and
            %   helps organize the display of the datastore.

            disp(getHeader(fds));
            groups = getPropertyGroups(fds);
            groups = matlab.io.datastore.internal.util.displayScalarObjectFiles(fds, groups, 'Files');
            groups = matlab.io.datastore.internal.util.displayScalarObjectFiles(fds, groups, 'Folders');
            matlab.mixin.CustomDisplay.displayPropertyGroups(fds, groups);
            disp(getFooter(fds));
        end
    end

    methods (Hidden)
        function files = getUnresolvedFiles(fds)
            files = fds.UnResolvedFiles;
        end
    end

    methods (Static, Hidden)

        function tf = supportsLocation(~, ~)
            % This function is responsible for determining whether a given
            % location is supported by FileDatastore. For FileDatastore
            % 'Type' Name-Value pair must be provided for datastore function.

            tf = false;
        end

        function varargout = supportsLocationHelper(loc, nvStruct)
            % This function is responsible for determining whether a given
            % location is supported by FileDatastore. It also returns a
            % resolved filelist.
            defaultExtensions = {};
            % validate file extensions, include subfolders is validated in
            % pathlookup
            import matlab.io.datastore.internal.validators.validateFileExtensions;
            import matlab.io.datastore.FileBasedDatastore;

            isDefaultExts = validateFileExtensions(nvStruct.FileExtensions, nvStruct.UsingDefaults);
            [varargout{1:nargout}] = FileBasedDatastore.supportsLocation(loc, nvStruct, defaultExtensions, ~isDefaultExts);
        end

        function outds = loadobj(ds)
            if isa(ds, 'struct')
                ds = matlab.io.datastore.FileDatastore.structToDatastore(ds);
            end
            if ds.Splitter.NumSplits ~= 0
                % create a split reader that points to the
                % first split index.
                if ds.SplitIdx == 0
                    ds.SplitIdx = 1;
                end
                ds.SplitReader = ds.Splitter.createReader(ds.SplitIdx);
            end
            outds = loadobj@matlab.io.datastore.FileBasedDatastore(ds);
            replaceUNCPaths(outds);
        end
    end

    methods (Static, Access = private)
        function ds = structToDatastore(inStruct)
            %STRUCTTODATASTORE Set the struct fields to the datastore properties
            %   This is a private helper which assigns the struct field values to the
            %   datastore properties.
            ds = fileDatastore({}, 'ReadFcn', inStruct.Splitter.ReadFcn);
            % Setting up the datastore.
            inSplitter = inStruct.Splitter;
            inAlternateFileSystemRoots = inStruct.AlternateFileSystemRoots;
            inStruct = rmfield(inStruct, {'AlternateFileSystemRoots', 'Splitter'});
            field_list = fields(inStruct);
            for field_index = 1: length(field_list)
                field = field_list{field_index};
                ds.(field) = inStruct.(field);
            end
            files = inSplitter.getFilesAsCellStr();
            fileSizes = inSplitter.getFileSizes();
            oldSplits = inSplitter.Splits;
            initFromReadFcnAndReadMode(ds, inSplitter.ReadFcn, files, ...
                                       fileSizes, false, ds.BlockSize, oldSplits);
            c = onCleanup(@()defaultSetFromLoadObj(ds));
            ds.SetFromLoadObj = true;
            ds.AlternateFileSystemRoots = inAlternateFileSystemRoots;
            ds.ReadFcn = inSplitter.ReadFcn;
        end
    end
end

% validates BlockSize value and checks if appropriate ReadMode is set.
function blockSize = iValidateBlockSize(blockSize, readMode)

    types = {'double','single','uint32','uint64','int32','int64'};
    attrs = {'scalar', 'real', 'nonnan', 'positive'};
    validateattributes(blockSize, types, attrs, 'FileDatastore', 'BlockSize');
   
    % Return early if the BlockSize is Inf. 
    if isinf(blockSize)
        return;
    end

    % Verify that the BlockSize is an integer greater than 128 kB.
    attrs = [attrs, 'integer', '>=', 128 * 1024];
    validateattributes(blockSize, types, attrs, 'FileDatastore', 'BlockSize');

    % Error out if the BlockSize in file or partialfile ReadMode is set
    % to anything other than Inf.
    if (readMode ~= "bytes") && ~isinf(blockSize)
        error(message( ...
            'MATLAB:datastoreio:filedatastore:invalidReadModeForSettingBlockSize'));
    end
end

function parsedStruct = iParseNameValues(varargin)
    import matlab.io.datastore.FileDatastore;
    import matlab.io.datastore.mixin.CrossPlatformFileRoots;
    persistent inpP;
    if isempty(inpP)
        inpP = inputParser;
        addParameter(inpP, 'ReadFcn', -1);
        addParameter(inpP, 'UniformRead', false);
        addParameter(inpP, 'IncludeSubfolders', false);
        addParameter(inpP, 'FileExtensions', -1);
        addParameter(inpP, 'PreviewFcn', -1);
        addParameter(inpP, 'ReadMode', 'file');
        addParameter(inpP, 'BlockSize', Inf);
        addParameter(inpP, CrossPlatformFileRoots.ALTERNATE_FILESYSTEM_ROOTS_NV_NAME, CrossPlatformFileRoots.DEFAULT_ALTERNATE_FILESYSTEM_ROOTS);
        inpP.FunctionName = FileDatastore.CONVENIENCE_CONSTRUCTOR_FCN_NAME;
    end
    parse(inpP, varargin{:});
    if ~isa(inpP.Results.IncludeSubfolders,'logical') && ~isnumeric(inpP.Results.IncludeSubfolders)
        error(message('MATLAB:datastoreio:pathlookup:invalidIncludeSubfolders'));
    end
    parsedStruct = inpP.Results;
    parsedStruct.UsingDefaults = inpP.UsingDefaults;
end
