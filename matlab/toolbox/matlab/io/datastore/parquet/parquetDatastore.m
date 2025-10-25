function pds = parquetDatastore(location, varargin)
%parquetDatastore   Create a datastore for a collection of Parquet files.
%
%   PDS = parquetDatastore(LOCATION) creates a ParquetDatastore based on a
%       Parquet file or a collection of Parquet files in LOCATION.
%
%       LOCATION can be:                   Allowed datatypes:
%        - A file or folder name            - string scalar or character vector
%        - Multiple file or folder names    - string vector or cell array of character vectors
%        - A wildcard ("*") path            - string scalar or character vector
%        - A collection of files            - matlab.io.datastore.FileSet
%
%       LOCATION can contain both local files and remote URLs.
%       For more information on accessing remote data, see "Read Remote Data"
%       in the documentation.
%
%       All of the files in LOCATION must have the extension ".parquet" or
%       ".parq". Use the "FileExtensions" parameter to allow other extensions.
%
%   PDS = parquetDatastore(__, IncludeSubfolders=TF) includes Parquet files
%       recursively from each folder in LOCATION and its subfolders.
%
%       TF must be specified as a logical scalar. TF defaults to FALSE.
%
%   PDS = parquetDatastore(__, FileExtensions=EXTENSIONS) specifies custom file
%       extensions to be included in ParquetDatastore.
%
%       EXTENSIONS defaults to [".parquet" ".parq"].
%
%       EXTENSIONS must be specified as a string vector or a cell array
%       of character vectors, such as [".myFileExt" ".parq" ".parquet"]
%
%   PDS = parquetDatastore(__, AlternateFileSystemRoots=ALTROOTS) specifies
%       alternate file system root paths for files provided in the LOCATION argument.
%
%   PDS = parquetDatastore(__, Name1=Value1, Name2=Value2, ...) specifies the
%       properties of PDS using optional name-value pairs.
%
%   ParquetDatastore Methods:
%
%     preview         -    Read 8 rows from the start of the datastore.
%     read            -    Read subset of data from the datastore.
%     readall         -    Read all of the data from the datastore.
%     hasdata         -    Returns true if there is more data in the datastore.
%     reset           -    Reset the datastore to the start of the data.
%     partition       -    Return a new datastore that represents a single
%                          partitioned part of the original datastore.
%     numpartitions   -    Return an estimate for a reasonable number of
%                          partitions to use with the partition function for
%                          the given information.
%     isPartitionable -    Returns true if this datastore is partitionable.
%                          ParquetDatastore is always partitionable.
%     isShuffleable   -    Returns true if this datastore is shuffleable.
%                          ParquetDatastore is not shuffleable.
%     transform       -    Create an altered form of the current datastore by
%                          specifying a function handle that will execute
%                          after read on the current datastore.
%     combine         -    Create a new datastore that horizontally
%                          concatenates the result of read from two or more
%                          input datastores.
%     writeall        -    Writes all the data in the datastore to a
%                          new output location.
%
%   ParquetDatastore Properties:
%
%     Files                    - Files included in datastore.
%     Folders                  - The input folders used to construct
%                                this datastore. Specifies the folders
%                                to be duplicated during writeall.
%     RowFilter                - matlab.io.RowFilter instance used for filtering
%                                rows while reading Parquet files.
%     AlternateFileSystemRoots - Alternate file system root paths for the Files.
%     VariableNames            - Names of variables.
%     SelectedVariableNames    - Variables to read.
%     VariableNamingRule       - Rule for convering variable names to valid
%                                MATLAB identifiers. It can be specified as
%                                "modify" (default) or "preserve".
%     ReadSize                 - Upper limit on the size of the data returned
%                                by the read method.
%     PartitionMethod          - Specifies how the datastore should be
%                                partitioned.
%     BlockSize                - Number of bytes to read with every read operation,
%                                specified as a positive integer.
%                                To specify or to change the value of BlockSize,
%                                PartitionMethod must be set to "bytes".
%     OutputType               - Selects the data type returned from the
%                                preview, read, and readall functions.
%     RowTimes                 - Name of the time variable for OutputType "timetable".
%     SupportedOutputFormats   - List of formats supported for writing
%                                by this datastore.
%     DefaultOutputFormat      - The default format chosen for writing.
%
%   Example:
%   --------
%      pds = parquetDatastore("airlinesmall.parquet");
%
%      while hasdata(pds)        % Read each rowgroup from the Parquet file in a loop
%          data = read(pds);
%      end
%      reset(pds);               % Reset to the beginning of the datastore
%      data = read(pds)          % Read from the beginning
%
%   See also datastore, matlab.io.datastore.ParquetDatastore, rowfilter.

%   Copyright 2018-2023 The MathWorks, Inc.

    try
        % Use the new code path if the ParquetRefactor feature flag is set.
        pds = matlab.io.datastore.ParquetDatastore(location, varargin{:});
    catch ME
        handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
        handler(ME);
    end
end
