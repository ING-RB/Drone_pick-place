classdef ParquetDatastore < matlab.io.Datastore ...
        & matlab.io.datastore.internal.ComposedDatastore ...
        & matlab.io.datastore.HadoopFileBased ...
        & matlab.io.datastore.FileWritable ...
        & matlab.mixin.CustomDisplay

%matlab.io.datastore.ParquetDatastore   Datastore for a collection of Parquet files.
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
%     isShuffleable   -    Returns true if this datastore is shuffleable.
%     isSubsettable   -    Returns true if this datastore is subsettable.
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

    properties (Access = protected)
        % This is the source of truth for ImportOptions and ReadSize.
        % Gets overwritten on construction, but default this to a placeholder value
        % that is compatible with the default ParquetImportOptions.
        UnderlyingDatastore = makeDefaultUnderlyingDatastore()
    end

    properties (Dependent, Hidden)
        % The actual storage for OutputType, RowTimes, VariableNames, SelectedVariableNames,
        % VariableNamingRule, PreserveVariableNames, and RowFilter.
        % ParquetImportOptions also provides cross-validation behavior if a user tries to change
        % one of these properties.
        % This is actually stored in the UnderlyingDatastore stack, but it is
        % a dependent property accessible here for convenience.
        ImportOptions (1, 1) matlab.io.parquet.internal.ParquetImportOptions
    end

    properties (Dependent)
        %ReadSize    Specifies how much data is returned during READ.
        %
        %   ReadSize can be specified as scalar text or a numeric value:
        %
        %    - "rowgroup": Return data from one rowgroup in each Parquet file
        %                  during each READ.
        %
        %    - "file": Return all the data from each Parquet file during
        %              each READ.
        %
        %    - numeric scalar value: Return at most N rows during each READ.
        %
        %   Example
        %    >> pds = parquetDatastore("airlinesmall.parquet", ReadSize="rowgroup")
        %    >> T1 = pds.read(); % One rowgroup returned (12500 rows)
        %
        %    >> pds = parquetDatastore("airlinesmall.parquet", ReadSize="file")
        %    >> T2 = pds.read(); % Full file returned    (123523 rows)
        %
        %    >> pds = parquetDatastore("airlinesmall.parquet", ReadSize=10)
        %    >> T3 = pds.read(); % 10 rows returned      (10 rows)
        %
        %   See also: parquetDatastore, parquetinfo, parquetread
        ReadSize {matlab.io.datastore.internal.ParquetDatastore.mustBeValidReadSize}
    end

    properties (Dependent)
        %PartitionMethod    Specifies how the datastore should be
        %partitioned
        %
        %   PartitionMethod should be specified as a scalar text
        %
        %
        %    - "rowgroup": Uses Parquet metadata to find the total number
        %                  of rowgroups in all the files of the datastore,
        %                  and partitions based on that information.
        %    - "bytes"   : Calculates the total size (in bytes)
        %                  for all the files in the datastore,
        %                  and partitions based on that information.
        %    - "file"    : Partitions based on the number of files
        %    - "auto"    : Automatically chooses one of the ParitionMethod from
        %                  {"rowgroup", "bytes", "file"} based on context
        PartitionMethod {matlab.io.datastore.internal.ParquetDatastore.mustBeValidPartitionMethod}
    end

    properties (Hidden, SetAccess='private')
        PartitionMethodDerivedFromAuto = false;
    end

    properties (Dependent)
        %BlockSize   Number of bytes to read with every read operation,
        %specified as a positive integer.
        %
        %   To specify or to change the value of BlockSize,
        %   you must first set PartitionMethod to "bytes".
        %   Since, a Parquet file consists of one or more Rowgroups of possibly varying size;
        %   the BlockSize tries to match the closest Rowgroup(s) that falls within a BlockSize range.
        %   If PartitionMethod is "bytes", then the default BlockSize is 128 megabytes.
        BlockSize {mustBePositive}
    end

    % FileSet-based properties.
    properties (Dependent)
        %Files   Parquet files included in the datastore, listed as a cell
        %   array of character vectors.
        %
        %   Files can be set using a string array.
        %
        %   The first file specified by the Files property determines the
        %   variable names and format information for all files in the datastore.
        Files
    end

    properties (Dependent, SetAccess='private')
        %Folders   Lists the folders provided in the LOCATION argument
        %   during ParquetDatastore construction.
        %
        %   The Folders property must contain a non-empty value in order
        %   to use the WRITEALL method on file-based datastores.
        %
        %   See also matlab.io.datastore.ParquetDatastore.writeall
        Folders
    end

    properties (Dependent)
        %AlternateFileSystemRoots   Alternate file system root paths for Files.
        AlternateFileSystemRoots
    end

    % ParquetImportOptions-based properties.
    properties (Dependent)
        %VariableNames   Names of variables in the TABLE or TIMETABLE returned
        %   by the READ method.
        %
        %   Set VariableNames using a string array or cell array of character
        %   vectors to customize the variable names in the generated table or
        %   timetable. The number of new variable names must match the
        %   number of original variable names.
        %
        %   If unspecified, VariableNames is detected from the first Parquet
        %   file in the datastore.
        VariableNames

        %SelectedVariableNames   Subset of variables to return during READ.
        %
        %   Variables to read from the file, specified as a character
        %   vector, cell array of character vectors, or a string vector.
        %
        %   SelectedVariableNames must be a subset of VariableNames.
        SelectedVariableNames

        %VariableNamingRule   Control the normalization of variable names.
        %
        %   VariableNamingRule must be specified as a string scalar or a
        %   character vector matching one of the following values:
        %
        %     "modify"   - Converts variable names to unique nonempty valid MATLAB
        %                  identifiers.
        %
        %     "preserve" - Preserves variable names when importing. Will still
        %                  make variable names unique and nonempty.
        %
        %   See also READTABLE, PARQUETREAD
        VariableNamingRule

        %OutputType   Output data type to use when reading from the datastore,
        %   specified as either "table" (default), or "timetable".
        %
        %   OutputType selects the data type returned from the PREVIEW,
        %   READ, and READALL functions.
        OutputType

        %RowTimes   Name of the RowTimes variable used to generate a
        %   timetable on READ.
        %
        %   OutputType must be set to "timetable" to configure RowTimes.
        %
        %   If OutputType is set to "timetable" but RowTimes is unspecified,
        %   the first selected datetime or duration variable in the first
        %   file is used as the RowTimes variable.
        RowTimes

        %RowFilter   Specify a constraint used to filter rows before
        %   reading Parquet files.
        %
        %   Example:
        %
        %     % Make a ParquetDatastore on the airlinesmall dataset:
        %     pds = parquetDatastore("airlinesmall.parquet");
        %
        %     % Select all rows with a "Date" greater than June 2, 2007.
        %     pds.RowFilter = pds.RowFilter.Date > datetime("2007-06-02");
        %
        %     % Read the rows in the Parquet file matching the filter
        %     % condition.
        %     data = readall(pds);
        %
        %   See also parquetread, rowfilter
        RowFilter
    end

    properties (Dependent, Hidden)
        PreserveVariableNames
    end

    methods
        function pds2 = ParquetDatastore(location, fsArgs, pioArgs, dsArgs)
            arguments
                location
                fsArgs.Folders
                fsArgs.FileExtensions = [".parquet" ".parq"]
                fsArgs.IncludeSubfolders
                fsArgs.AlternateFileSystemRoots
                pioArgs.?matlab.io.parquet.internal.ParquetImportOptions
                dsArgs.ReadSize = "rowgroup";
                dsArgs.PartitionMethod = "auto";
                dsArgs.BlockSize;
            end

            import matlab.io.datastore.internal.makeFileSet
            import matlab.io.datastore.internal.ParquetDatastore.introspectFile
            import matlab.io.datastore.internal.ParquetDatastore.makeDatastoreFromReadSize

            try
                fsArgs = namedargs2cell(fsArgs);
                fs = makeFileSet(location, fsArgs{:});

                pioArgs = namedargs2cell(pioArgs);
                pio = introspectFile(fs, pioArgs{:});

                if (dsArgs.PartitionMethod == "auto")
                    pds2.PartitionMethodDerivedFromAuto = true;
                end

                if (isfield(dsArgs, 'BlockSize'))
                    if (dsArgs.PartitionMethod ~= "bytes") &&  ~isempty(dsArgs.BlockSize)
                        error(message("MATLAB:parquetdatastore:properties:BlockSizeOnlySupportedForPartitionMethodBytes"));
                    end
                else
                    dsArgs.BlockSize = 128*1000*1000;
                end


                % Construct ParquetDatastore from FileSet and ImportOptions.
                pds2.UnderlyingDatastore = makeDatastoreFromReadSize(fs, pio, dsArgs.ReadSize, dsArgs.BlockSize, dsArgs.PartitionMethod);

            catch ME
                % Throw an exception without the full stack trace. If the
                % MW_DATASTORE_DEBUG environment variable is set to 'on',
                % the full stacktrace is shown.
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end
        end

        % Getters
        function value = get.ReadSize(obj)
            value = convertStringsToChars(obj.UnderlyingDatastore.ReadSize);
        end

        function value = get.Files(obj)
            value = cellstr(obj.getUnderlyingFileDatastore().Files);
        end

        function value = get.Folders(obj)
            value = cellstr(obj.getUnderlyingFileDatastore().Folders);
        end

        function value = get.VariableNames(obj)
            value = cellstr(obj.ImportOptions.VariableNames);
        end

        function value = get.SelectedVariableNames(obj)
            value = cellstr(obj.ImportOptions.SelectedVariableNames);
        end

        function value = get.OutputType(obj)
            value = char(obj.ImportOptions.OutputType);
        end

        function value = get.RowTimes(obj)
            value = obj.ImportOptions.RowTimes;

            % PDS uses [] instead of missing for the OutputType="table" case.
            if ismissing(value)
                value = [];
            else
                value = char(value);
            end
        end

        function value = get.RowFilter(obj)
            value = obj.ImportOptions.RowFilter;
        end

        function value = get.VariableNamingRule(obj)
            value = char(obj.ImportOptions.VariableNamingRule);
        end

        function value = get.PreserveVariableNames(obj)
            value = obj.ImportOptions.PreserveVariableNames;
        end

        function value = get.AlternateFileSystemRoots(obj)
            value = obj.getUnderlyingFileDatastore().AlternateFileSystemRoots;
        end

        function value = get.ImportOptions(obj)
            value = obj.UnderlyingDatastore.ImportOptions;
        end

        function value = get.BlockSize(obj)
            cls = "matlab.io.datastore.internal.ParquetDatastore.UnderlyingDatastore.BlockedRowGroupDatastore";
            uds = obj.getUnderlyingDatastore(cls);

            if isempty(uds)
                % A non-blocked ReadSize is operating. Just return the
                % default BlockSize used by PartitionMethod="bytes"
                value = 128*1000*1000;
            else
                % Get the value from the UnderlyingDatastore.
                value = uds.BlockSize;
            end
        end


        function value = get.PartitionMethod(obj)
            value = convertStringsToChars(obj.UnderlyingDatastore.PartitionMethod);
        end


        % Setters
        function set.VariableNames(obj, value)
            obj.reconstructAfterSettingImportOptions("VariableNames", value);
        end

        function set.SelectedVariableNames(obj, value)
            obj.reconstructAfterSettingImportOptions("SelectedVariableNames", value);
        end

        function set.OutputType(obj, value)
            obj.reconstructAfterSettingImportOptions("OutputType", value);
        end

        function set.RowTimes(obj, value)
            obj.reconstructAfterSettingImportOptions("RowTimes", value);
        end

        function set.RowFilter(obj, value)
            obj.reconstructAfterSettingImportOptions("RowFilter", value);
        end

        function set.VariableNamingRule(obj, value)
            obj.reconstructAfterSettingImportOptions("VariableNamingRule", value);
        end

        function set.PreserveVariableNames(obj, value)
            obj.reconstructAfterSettingImportOptions("PreserveVariableNames", value);
        end

        function set.ReadSize(obj, readSize)
            import matlab.io.datastore.internal.ParquetDatastore.changeReadSize
            import matlab.io.datastore.internal.ParquetDatastore.mustBeValidReadSize

            % Validate the new ReadSize value.
            [~, readSize] = mustBeValidReadSize(readSize);

            % Map the old UnderlyingDatastore to the new one for this
            % ReadSize.
            obj.UnderlyingDatastore = changeReadSize(obj.UnderlyingDatastore, readSize, obj.PartitionMethod, obj.PartitionMethodDerivedFromAuto);
        end

        function set.PartitionMethod(obj, partitionMethod)
            import matlab.io.datastore.internal.ParquetDatastore.mustBeValidPartitionMethod
            import matlab.io.datastore.internal.ParquetDatastore.makeDatastoreFromReadSize

            partitionMethod = mustBeValidPartitionMethod(partitionMethod);

            oldAndNewPartitionMethodAreBothAuto = (partitionMethod == "auto" && obj.PartitionMethodDerivedFromAuto);

            if (oldAndNewPartitionMethodAreBothAuto)
                return;
            end

            if (obj.PartitionMethod == partitionMethod)
                % user is explicitly setting PartitionMethod, so change
                % obj.PartitionMethodDerivedFromAuto
                obj.PartitionMethodDerivedFromAuto = false;
                return;
            end

            try
                obj.UnderlyingDatastore = makeDatastoreFromReadSize(obj.UnderlyingDatastore.FileSet,...
                                                                    obj.ImportOptions, obj.ReadSize, obj.BlockSize, partitionMethod);
            catch ME
                % Throw an exception without the full stack trace. If the
                % MW_DATASTORE_DEBUG environment variable is set to 'on',
                % the full stacktrace is shown.
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end

            % only change PartitionMethodDerivedFromAuto, after we have
            % gone through makeDatastoreFromReadSize.
            % Note : obj.PartitionMethod might have changed by the time, we
            % get here through determineConcretePartitionMethodForAutoPartition
            % being called inside makeDatastoreFromReadSize
            if (partitionMethod == "auto")
                obj.PartitionMethodDerivedFromAuto = true;
            else
                obj.PartitionMethodDerivedFromAuto = false;
            end

        end

        function set.Files(obj, files)
            try
                obj.reconstructAfterSettingFiles(files);
            catch ME
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end
        end

        function set.AlternateFileSystemRoots(obj, afsr)
        % Set the property on the underlying FileDatastore2's FileSet.
            obj.getUnderlyingFileDatastore().AlternateFileSystemRoots = afsr;
        end

        function set.ImportOptions(obj, opts)
            obj.UnderlyingDatastore.ImportOptions = opts;
        end

        function set.BlockSize(obj, blockSize)
        % Reconstruct with the new BlockSize.
            import matlab.io.datastore.internal.ParquetDatastore.makeDatastoreFromReadSize
            if (obj.PartitionMethod ~= "bytes")
                error(message("MATLAB:parquetdatastore:properties:BlockSizeOnlySupportedForPartitionMethodBytes"));
            end
            fs = obj.UnderlyingDatastore.FileSet;
            try
                obj.UnderlyingDatastore = makeDatastoreFromReadSize(fs, obj.ImportOptions, obj.ReadSize, blockSize, obj.PartitionMethod);
            catch ME
                % Throw an exception without the full stack trace. If the
                % MW_DATASTORE_DEBUG environment variable is set to 'on',
                % the full stacktrace is shown.
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end
        end
    end

    % Save-load logic.
    properties (Access = private, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of ParquetDatastore2 in R2022b.
        ClassVersion(1, 1) double = 1;
    end

    methods (Hidden)
        S = saveobj(obj);
    end

    methods (Hidden, Static)
        obj = loadobj(S);
    end

    % HadoopLocationBased requirements.
    methods (Hidden)
        location = getLocation(obj);
        tf = isfullfile(obj);
        initializeDatastore(obj, hadoopInfo);
    end

    % FileWritable requirements.
    properties (Constant)
        %SupportedOutputFormats   List of formats supported by WRITEALL on ParquetDatastore.
        SupportedOutputFormats = matlab.io.datastore.internal.FileWritableSupportedOutputFormats.TabularDatastoreSupportedOuptutFormats;

        %DefaultOutputFormat   Default output format for ParquetDatastore.
        DefaultOutputFormat = "parquet";
    end

    methods (Access = 'protected')
        tf = currentFileIndexComparator(obj, index);
    end

    % CustomDisplay requirements.
    methods (Access = 'protected')
        displayScalarObject(obj);
    end

    % Needed by the datastore() gateway function
    methods (Hidden, Static)
        function varargout = supportsLocation(loc, nvStruct)
        % This function is responsible for determining whether a given
        % location is supported by ParquetDatastore.
            import matlab.io.datastore.FileBasedDatastore;
            defaultExtensions = {'.parq', '.parquet'};
            [varargout{1:nargout}] = FileBasedDatastore.supportsLocation(loc, nvStruct, defaultExtensions);
        end
    end
end

function uds = makeDefaultUnderlyingDatastore()
    import matlab.io.datastore.FileSet
    import matlab.io.datastore.internal.ParquetDatastore.makeDatastoreFromReadSize

    fs = matlab.io.datastore.FileSet({});
    pio = matlab.io.parquet.internal.ParquetImportOptions();

    % Only gets used in some extreme cases when save-load goes wrong.
    uds = makeDatastoreFromReadSize(fs, pio, "rowgroup", 128*1000*1000, "rowgroup");
end
