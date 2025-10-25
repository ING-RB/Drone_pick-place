function ds = fileDatastore(location, varargin)
%FILEDATASTORE Create a datastore for a collection of files with custom data format.
%   FDS = fileDatastore(LOCATION,'ReadFcn',@MYCUSTOMREADER) creates a
%   FileDatastore if a file or a collection of files are present in LOCATION.
%   LOCATION has the following properties:
%      - Can be a filename or a folder name
%      - Can be a cell array or string array of multiple file or folder names
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
%      - A cell array of character vectors or a string array, such as {'.jpg', '.mat'}
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
%   FDS = fileDatastore(__,'ReadMode',MODE) specifies the behavior of the read
%   and preview operations. You can choose to read the full file with every read
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
%   FileDatastore Properties:
%
%      Files                    - Cell array of character vectors of file names. You
%                                 can also set this property using a string array.
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
%      read            - Read subset of data from the datastore
%      reset           - Resets the datastore to the start of the data
%      preview         - Reads the first file from the datastore for preview
%      readall         - Reads all of the files from the datastore
%      partition       - Returns a new datastore that represents a single
%                        partitioned portion of the original datastore
%      numpartitions   - Returns an estimate for a reasonable number of
%                        partitions according to the total data size to use
%                        with the partition function.
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
%      subset          - Return a new FileDatastore that contains only the
%                        files corresponding to the input indices. Only
%                        available when the FileDatastore is in the "file"
%                        ReadMode.
%      shuffle         - Return a new FileDatastore that shuffles all the
%                        Files in the original FileDatastore. Only available
%                        when the FileDatastore is in the "file" ReadMode.
%
%   Example 1:
%   --------
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
%                          'BlockSize', 1024*1024);   % 1 MB block size.
%      disp(numpartitions(ds1));                      % 12 partitions are generated
%
%      ds2 = fileDatastore(filename,'ReadFcn',@readtable,'ReadMode','file');
%      disp(numpartitions(ds2));                      % Entire file is in one partition
%
%      ds3 = fileDatastore(filename,'ReadFcn',@(f,g)deal(readtable(f),[],true),...
%                          'ReadMode','partialfile');
%      disp(numpartitions(ds3));                      % Entire file is in one partition
%
%   See also datastore, mapreduce, load, matlab.io.datastore.FileDatastore.

%   Copyright 2017-2018 The MathWorks, Inc.
    ds = matlab.io.datastore.FileDatastore(location, varargin{:});
end
