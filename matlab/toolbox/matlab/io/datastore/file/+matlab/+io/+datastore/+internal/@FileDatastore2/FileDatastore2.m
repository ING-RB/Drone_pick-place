classdef FileDatastore2 < matlab.io.Datastore ...
                        & matlab.io.datastore.mixin.Subsettable
%matlab.io.datastore.internal.FileDatastore2   Datastore for a set of files with custom data format.
%
%   FDS = FileDatastore2(LOCATION, ReadFcn=@MYCUSTOMREADER) creates a
%       datastore that iterates over the list of files/folders in LOCATION and
%       calls MYCUSTOMREADER with each filename in LOCATION.
%
%       LOCATION can be:
%           - A filename, folder name, or URL, specified as a string scalar or
%             character vector.
%           - Multiple filenames, folder names, or URLs, specified as a string vector
%             or a cell array of character vectors.
%           - A matlab.io.datastore.DsFileSet or matlab.io.datastore.FileSet object
%
%       LOCATION can also contain a wildcard (*) character.
%
%       MYCUSTOMREADER must be a function handle with the following signature:
%
%           function data = MYCUSTOMREADER(filename)
%               ...
%           end
%
%       The "filename" input to the ReadFcn will be the name of each file in LOCATION,
%       specified as a character vector. The "data" output returned by ReadFcn
%       must be vertically concatenable to avoid erroring during readall().
%
%   FDS = FileDatastore2(__, IncludeSubfolders=TF) includes files from every
%       subfolder in LOCATION if TF is set to true.
%
%       TF is set to false by default.
%
%   FDS = FileDatastore2(__, FileExtensions=EXTENSIONS) specifies the
%       extensions of files to be included. Values for EXTENSIONS can be:
%          - A string scalar or character vector, such as ".jpg" or ".png"
%            (empty quotes '' are allowed for files without extensions)
%          - A string vector or cell array of character vectors, such as [".jpg", ".mat"]
%
%   FDS = FileDatastore2(__, AlternateFileSystemRoots=ALTROOTS) specifies
%       alternate paths for the files provided in the LOCATION argument.
%
%       ALTROOTS must contain one or more rows, where each row specifies a set
%       of equivalent root paths. Values for ALTROOTS can be one of these:
%
%          - A string row vector of root paths, such as
%                     ["Z:\datasets", "/mynetwork/datasets"]
%
%          - A cell array of root paths, where each row of the cell array can be
%            specified as string row vector or a cell array of character vectors,
%            such as
%                     {["Z:\datasets", "/mynetwork/datasets"];...
%                      ["Y:\datasets", "/mynetwork2/datasets","S:\datasets"]}
%
%       The value of ALTROOTS must also satisfy these conditions:
%          - Each row of ALTROOTS must specify multiple root paths and each root
%            path must contain at least 2 characters.
%          - Root paths specified must be unique and should not be subfolders of
%            each other
%          - ALTROOTS must have at least one root path entry that points to the
%            location of files
%
%   Differences between FileDatastore and FileDatastore2:
%
%      - FileDatastore will perform ImageDatastore-like non-uniform reading
%        behavior, where individual reads are returned as normal types, but
%        multi-reads (like readall) are returned as cells.
%        FileDatastore2 does not do this by default, and always expects
%        concatenable results from the ReadFcn.
%      - FileDatastore will reset() during loadobj, while FileDatastore2
%        will maintain the current position during loadobj.
%      - FileDatastore has multiple ReadModes, while FileDatastore2 only
%        operates in the "file" ReadMode.
%      - FileDatastore stores Files and Folders as character vectors, while
%        FileDatastore2 stores them as strings.
%      - FileDatastore has a configurable PreviewFcn, while FileDatastore2
%        does not.
%
%   FileDatastore2 Properties:
%
%      Files                    - String vector containing file names.
%      Folders                  - The input folders used to construct this datastore.
%      AlternateFileSystemRoots - Alternate file system root paths for the files.
%      ReadFcn                  - Function handle used to read files.
%
%   FileDatastore2 Methods:
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
%      subset          - Return a new FileDatastore2 that contains only the
%                        files corresponding to the input indices.
%      shuffle         - Return a new FileDatastore2 that shuffles all the
%                        Files in the original FileDatastore2.
%
%   Example:
%   ----------
%      folder = fullfile(matlabroot, "toolbox", "matlab", "demos");
%
%      import matlab.io.datastore.internal.FileDatastore2
%      fds = FileDatastore2(folder, ReadFcn=@(f) {load(f)}, FileExtensions=".mat");
%
%      data1 = read(fds);                   % Read the first MAT-file
%      data2 = read(fds);                   % Read the next MAT-file
%      readall(fds)                         % Read all the MAT-files
%      dataArr = cell(numel(fds.Files),1);
%      i = 1;
%      reset(fds);                          % Reset to the beginning of data
%      while hasdata(fds)                   % Read files using a while-loop
%          dataArr{i} = read(fds);
%          i = i + 1;
%      end
%
%   See also datastore, mapreduce, load, fileDatastore.

%   Copyright 2021-2023 The MathWorks, Inc.

    properties (Dependent)
        Files
    end

    properties (Dependent, SetAccess='private')
        Folders
    end

    properties (Dependent)
        AlternateFileSystemRoots
    end

    properties
        ReadFcn (1, 1) {mustBeA(ReadFcn, "matlab.mixin.internal.FunctionObject")} = matlab.io.datastore.internal.functor.FunctionHandleFunctionObject(@(filename) filename)
        FileSet (1, 1) matlab.io.datastore.FileSet = matlab.io.datastore.FileSet({});
    end

    properties (Access = private, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of FileDatastore2 in R2022b.
        ClassVersion (1, 1) double = 1
    end

    methods
        function fds = FileDatastore2(location, args, fsArgs)
            arguments
                location

                % N-V pairs handled by FileDatastore2.
                args.ReadFcn

                % N-V pairs handled by FileSet.
                fsArgs.IncludeSubfolders
                fsArgs.FileExtensions
                fsArgs.AlternateFileSystemRoots
            end

            import matlab.io.datastore.internal.makeFileSet

            % ReadFcn must be supplied as input.
            if ~isfield(args, "ReadFcn")
                msgid = "MATLAB:datastoreio:filedatastore:readFcnNotProvided";
                error(message(msgid));
            end

            fsArgs = namedargs2cell(fsArgs);
            fds.FileSet = makeFileSet(location, fsArgs{:});
            fds.ReadFcn = convertFunctionHandleToObject(args.ReadFcn);
        end

        function files = get.Files(ds)
            files = ds.FileSet.FileInfo.Filename;
        end

        function set.Files(ds, files)
            % Just construct a new FileSet with the new list of Files as
            % input.
            ds.FileSet = matlab.io.datastore.FileSet(files, ...
                AlternateFileSystemRoots=ds.AlternateFileSystemRoots);

            % Folders property should be reset after manually setting
            % Files.
            ds.FileSet.updateFoldersProperty();
        end

        function folders = get.Folders(ds)
            folders = string(ds.FileSet.Folders);
        end

        function roots = get.AlternateFileSystemRoots(ds)
            roots = ds.FileSet.AlternateFileSystemRoots;
        end

        function set.AlternateFileSystemRoots(ds, roots)
            ds.FileSet.AlternateFileSystemRoots = roots;
        end

        function set.ReadFcn(ds, readFcn)
            % Convert to a FunctionObject before setting.
            ds.ReadFcn = convertFunctionHandleToObject(readFcn);
        end
    end

    methods (Access = protected)
        copyDs = copyElement(fds);
    end

    methods (Hidden)
        frac = progress(fds);

        S = saveobj(fds);
    end

    methods (Hidden, Static)
        fds = loadobj(S);
    end
end

function obj = convertFunctionHandleToObject(fcn)
    import matlab.io.datastore.internal.functor.makeFunctionObject
    obj = makeFunctionObject(fcn);
end
