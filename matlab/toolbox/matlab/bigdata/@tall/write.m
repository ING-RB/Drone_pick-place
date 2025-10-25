function write(location, ta, varargin)
%WRITE  Write tall data to an output location.
%   WRITE(LOCATION,T) calculates the values in the tall array T and writes
%   them to files in the folder LOCATION. The data is stored in a binary
%   format suitable for reading back using DATASTORE(LOCATION).
%
%   WRITE(FILEPATTERN,T) uses the file extension from the file pattern to
%   determine the output format. FILEPATTERN must include a folder to write
%   the files into followed by a filename that includes a wildcard *. The
%   wildcard represents incremental numbers for generating unique file
%   names. 
%   For example: folder/myfile_*.csv
%
%   WRITE(LOCATION,T,'FileType',TYPE) specifies the file type, where TYPE
%   is one of 'mat', 'sequence', 'text', or 'spreadsheet'. WRITE formats
%   the data in the files as follows:
%
%             'mat' -  Multiple MATLAB data files.
%         'parquet' -  Multiple Parquet data files.
%             'seq' -  Multiple Hadoop sequence files.
%            'text' -  Multiple comma-delimited text files. T must contain
%                      table data. The text files are column-oriented such
%                      that each column of each variable in T is written
%                      out as a column in each file. The variable names in
%                      T are written out as column headings in the first
%                      line of the file.
%     'spreadsheet' -  Multiple spreadsheet files. T must contain table
%                      data. The spreadsheet files are column-oriented such
%                      that each variable in T is written out as a column
%                      in each file. The variable names in T are written
%                      out as column headings in the first line of the
%                      file.
%            'auto' -  (default) Automatically choose the most efficient
%                      format based on the target filesystem.
%
%   WRITE(...,PARAM1,VALUE1,PARAM2,VALUE2,...) specifies one or more
%   options for controlling the output format. The supported options depend
%   on the file type. No options are supported for .mat or .seq files.
%
%   Parquet files (.parquet, .parq) support these options:
%
%    'VariableCompression'  Names of the compression algorithms to use when
%                           writing the variables of T to a Parquet file.
%                           Specify 'VariableCompression' as a character
%                           vector or string scalar to compress all
%                           variables using the same compression algorithm.
%                           To compress each variable with a different
%                           compression algorithm, specify
%                           'VariableCompression' as a cell array of
%                           character vectors or a string vector containing
%                           the names of the compression algorithms to use
%                           for each variable. Valid compression algorithm
%                           names are 'snappy', 'gzip', 'brotli', and
%                           'uncompressed'. By default, all variables are
%                           compressed using the 'snappy' compression
%                           algorithm. In general, 'snappy' compression
%                           has better performance when reading or
%                           writing. 'gzip' has a higher compression ratio
%                           resulting in smaller file size, but requires
%                           more CPU processing time. 'brotli' typically
%                           produces the smallest file size, but
%                           compression speed may be slower.
%
%    'VariableEncoding'     Names of the encoding strategy to use when
%                           writing the variables of T to a Parquet file.
%                           Specify 'VariableEncoding' as a character
%                           vector or string scalar to encode all variables
%                           using the same encoding strategy. To encode
%                           each variable with a different encoding
%                           strategy, specify 'VariableEncoding' as a cell
%                           array of character vectors or a string vector
%                           containing the names of the encoding strategy
%                           to use for each variable. Valid encoding names
%                           are 'auto', 'dictionary' or 'plain'. By
%                           default, all variables are encoded using the
%                           'auto' encoding strategy which uses dictionary
%                           encoding for all variables, except any
%                           variables of type logical where plain encoding
%                           is used instead. In general, 'dictionary'
%                           encoding results in smaller file sizes, but
%                           'plain' encoding can be faster for variables
%                           that do not contain many repeated values.
%
%    'Version'              Parquet format version to write. Valid versions
%                           are '1.0' or '2.0' (default).  Select Parquet
%                           '1.0' for the broadest compatiblity with
%                           external applications that support the Parquet
%                           format.
%
%   Text files (.txt, .dat, .csv) support these options:
%
%              'Delimiter'  The delimiter used in the file. Can be any of:
%                           ' ', '\t', ',', ';', '|' or their corresponding
%                           names: 'space', 'tab', 'comma', 'semi', or
%                           'bar'.
%                           Default: ','
%
%     'WriteVariableNames'  A logical value that specifies whether to use
%                           the variable names in T as column headings.
%                           Default: true
%
%           'QuoteStrings'  A logical value that specifies whether to write
%                           text out enclosed in double quotes ('...'). If
%                           'QuoteStrings' is true, then any double quote
%                           characters that appear as part of a text
%                           variable are replaced by two double quote
%                           characters.
%
%             'DateLocale'  The locale that WRITE uses to create month and 
%                           day names when writing datetimes to the file.
%                           The value must be a character vector or scalar
%                           string in the form xx_YY. See the documentation
%                           for DATETIME for more information.
%
%               'Encoding'  The encoding to use when creating the file.
%                           Default: 'UTF-8'
%
%   Spreadsheet files (.xls, .xlsx, .xlsb, .xlsm, .xltx, .xltm) support these options:
%
%     'WriteVariableNames'  A logical value that specifies whether to use
%                           the variable names in T as column headings.
%                           Default: true
%
%             'DateLocale'  The locale that WRITE uses to create month and
%                           day names when writing datetimes to the file.
%                           The value must be a character vector or scalar
%                           string in the form xx_YY. 
%
%                           NOTE: The value of 'DateLocale' is ignored whenever 
%                           dates can be written as Excel-formatted dates.
%
%                  'Sheet'  The sheet to write to, specified as the worksheet name, 
%                           or a positive integer indicating the worksheet index.
%
%   WRITE(LOCATION,T,'WriteFcn',@FCN) specifies a custom write function
%   FCN. The function receives blocks of data from T to be written to a
%   temporary location and is responsible for creating the output files.
%
%   FCN must accept two input arguments: INFO and DATA. 
%   *  DATA contains the block of data from T to be written. 
%   *  INFO is a struct giving a suggested filename to use, as well as
%      additional information about the block of data that is sufficient to
%      build a new filename. Filenames must be globally unique within the
%      final location.
%
%   The INFO struct contains these fields:
%
%         RequiredLocation: Fully qualified path to a temporary output folder.
%                           All output files must be written to this folder.
%      RequiredFilePattern: The file pattern required for output filenames.
%        SuggestedFilename: A fully qualified, globally unique filename that 
%                           meets the location and naming requirements.
%           PartitionIndex: Index of the tall array partition being written.
%            NumPartitions: Total number of partitions in the tall array.
%    BlockIndexInPartition: Position of current data block within the partition.
%             IsFinalBlock: True if current block is the final block of the
%                           partition.
%
%
%   Example 1:
%      % Create tall array and write it to an output folder in a format
%      % suitable for efficient re-reading into MATLAB
%      tt = tall(rand(5000,1));
%      location = "hdfs://myHadoopCluster/some/output/folder";
%      write(location, tt);
%
%      % Recreate the tall array from the written files
%      ds = datastore(location);
%      tt1 = tall(ds);
%
%   Example 2:
%      % Create tall array and write it to a simple text-based format that
%      % many applications can read.
%      tt = tall(array2table(rand(5000,3)));
%      location = "/tmp/CSVData/tt_*.csv";
%      write(location, tt);
%
%      % Recreate the tall array from the written files
%      ds = datastore(location);
%      tt1 = tall(ds);
%
%   Example 3:
%      % Create tall array and write it to disk using a custom function
%      tt = tall(array2table(rand(5000,3)));
%      location = "/tmp/MyData/tt_*.xlsx";
%      write(location, tt, "WriteFcn", @dataWriter);
%
%      function dataWriter(info, data)
%          filename = info.SuggestedFilename ;
%          writetable(data, filename, "FileType", "spreadsheet")
%
%   Limitation:
%
%   In some cases, WRITE(LOCATION, T, 'FileType', TYPE) creates checkpoint
%   files that do not represent the original array T exactly. If you use
%   DATASTORE(LOCATION) to read the checkpoint files, then the result might
%   not have the same format or contents as the original tall table.
% 
%   1) For the 'text' and 'spreadsheet' file types, WRITE uses these rules:
% 
%      *  WRITE outputs numeric variables using longg format, and
%         categorical character, or string variables as unquoted text.
%      *  For non-text variables that have more than one column, WRITE
%         outputs multiple delimiter-separated fields on each line, and
%         constructs suitable column headings for the first line of the
%         file.
%      *  WRITE outputs variables with more than two dimensions as
%         two-dimensional variables, with trailing dimensions collapsed.
%      *  For cell-valued variables containing numeric, logical, character,
%         or categorical data, WRITE outputs the contents of each cell as a
%         single row, in multiple delimiter-separated fields. For other
%         cell-valued variables, WRITE outputs a single empty field.
%
%      Do not use the 'text' or 'spreadsheet' file types if you need to
%      write an exact checkpoint of the tall array.
%
%   2) For the 'parquet' file type, there are some cases where the Parquet
%      format cannot fully represent the MATLAB table or timetable data
%      types. If you use parquetread or datastore to read the files, then
%      the result might not have the same format or contents as the
%      original tall table. For more information about the Parquet format,
%      see "Apache Parquet Data Type Mappings" in the documentation.
%
%   See also: TALL, DATASTORE.

%   Copyright 2016-2020 The MathWorks, Inc.

narginchk(2,inf);

try
    [location, filePattern] = matlab.bigdata.internal.util.splitWriteLocation(location);
    [location, isIri, isHdfs] = matlab.bigdata.internal.util.validateLocationString(location);

    % Build a sample to allow FileType specific validation on the client
    taAdaptor = ta.Adaptor;
    defaultType = 'double';
    defaultSize = [1 1];
    prototype = buildSample(taAdaptor, defaultType, defaultSize);
    
    % Get the writer object that knows how to write the format specified.
    writeFunction = matlab.bigdata.internal.util.parseWriteArguments( ...
        location, filePattern, isIri, isHdfs, prototype, varargin);
catch e
    % Remove stack trace
    throw(e)
end

iDoWrite(location, ta, writeFunction);
end

%--------------------------------------------------------------------------
function iDoWrite(location, ta, writeFunction)
frameMarker = matlab.bigdata.internal.InternalStackFrame; %#ok
taAdaptor = ta.Adaptor;

% Thread-based parallel pools do not support tall/write. We error upfront
% as soon as we detect this combination of feature and environment.
executor = getExecutor(hGetValueImpl(ta));
try
    executor.checkDatastoreSupport(matlab.io.datastore.TallDatastore({}));
catch err
    assert(err.identifier == "parallel:lang:pool:DisallowedParallelFeature", ...
        "Assertion failed: Unexpected error issued when checking support: %s", ...
        err.identifier);
    matlab.bigdata.internal.throw(message("parallel:lang:pool:UnsupportedFeature"));
end

% Request that a worker check if it can write to the output folder. This
% will be done at the earliest possible opportunity in the subsequent
% gather. This is done by a worker as the client might not have direct
% access to the folder.
tlocation = tall.createGathered(location, executor);
tlocation = repartition(matlab.bigdata.internal.PartitionMetadata(1), 1, tlocation);
tlocation = slicefun(@matlab.bigdata.internal.util.validateLocation, tlocation);
ta = elementfun(@(x, ~) x, ta, matlab.bigdata.internal.broadcast(tlocation));
ta.Adaptor = taAdaptor;

% Remove empty chunks and coalesce small chunks.
ta = tall(resizechunks(hGetValueImpl(ta)));
ta.Adaptor = taAdaptor;

tEmpty = partitionfun(matlab.bigdata.internal.FunctionHandle(writeFunction), ta);

disp(getString(message("MATLAB:bigdata:write:WritingInfo", class(ta), location)));

try
    % Gather on partitioned array instance so that we only show errors
    % caused by write failures, without reference to tall/gather.
    gather(hGetValueImpl(tEmpty));
catch err
    matlab.bigdata.internal.util.assertNotInternal(err);
    if strcmpi(err.identifier, "MATLAB:virtualfileio:stream:permissionDenied")
        baseException = MException('MATLAB:bigdata:write:InvalidWriteLocation', ...
            message('MATLAB:bigdata:write:InvalidWriteLocation', location));
        baseException = matlab.bigdata.BigDataException.build(baseException);
        causeException = MException(err.identifier, err.message);
        err = addCause(baseException, causeException);
    end
    updateAndRethrow(err);
end
end
