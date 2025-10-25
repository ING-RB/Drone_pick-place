function parquetwrite(filename, T, varargin)
%PARQUETWRITE Write columnar data to a Parquet file.
%   PARQUETWRITE(FILENAME, T) write the table or timetable T to a Parquet
%   file named FILENAME, where FILENAME is any of the following:
%       - For local files, FILENAME can be a full path that
%         contains a filename and file extension. FILENAME can
%         also be a relative path to the current directory.
%         For example, to export a table or timetable T to a
%         local file:
%             PARQUETWRITE('data.parquet', T);
%
%       - For remote files, FILENAME must be a full path using
%         a Uniform Resource Locator (URL).
%         For example, to export a table or timetable T to a
%         remote file on Amazon S3 cloud, specify the full
%         URL for the file:
%             FILENAME = "s3://bucketname/path_to_file/data.parquet";
%             PARQUETWRITE(FILENAME, T);
%         For more information on accessing remote data, see
%         'Work with Remote Data' in the documentation.
%
%   PARQUETWRITE(FILENAME, T, 'Name1', VALUE1, 'Name2', VALUE2, ...)
%   uses name-value pairs to control the writing behavior. Supported
%   name-value pairs are listed below:
%
%           Name                                Value
%   ---------------------  ------------------------------------------------
%   
% 'RowGroupHeights'        The number of rows in the input table T to write
%                          as a separate rowgroup in the output file.
%                          When unspecified, 'RowGroupHeights' will default
%                          to the full height of the input table, thus
%                          writing all of T as a single rowgroup.
%
%                          'RowGroupHeights' can be specified as either a
%                          numeric scalar or a vector of non-negative
%                          integer values:
%
%                          - When specified as a scalar, the scalar value
%                            will be used as the desired height of all
%                            rowgroups in the output Parquet file.
%                            Note that the last rowgroup may contain fewer
%                            rows if height(T) is not an exact multiple.
%
%                              data = parquetread("outages.parquet"); % 1468x6 table
%                              parquetwrite("A.parquet", data, "RowGroupHeights", 500);
%
%                          - When specified as a vector, each value in the
%                            vector will be used as the height of a
%                            corresponding rowgroup in the output Parquet
%                            file.
%                            The sum of all the values in the vector must
%                            match the height of the input table T.
%
%                              data = parquetread("outages.parquet"); % 1468x6 table
%                              parquetwrite("B.parquet", data, "RowGroupHeights", [300, 400, 500, 0, 268]);
%
%                          A rowgroup is the smallest subset of a Parquet
%                          file which can be read into memory at once.
%                          Reducing the rowgroup height can help ensure
%                          that data fits into memory when reading.
%                          Rowgroup height also affects the performance of
%                          filtering operations on a Parquet dataset, since
%                          a larger rowgroup height can be used to filter
%                          larger amounts of data when reading.
%
%   'VariableCompression'  Names of the compression algorithms to use when
%                          writing the variables of T to a Parquet file.
%                          Specify 'VariableCompression' as a character
%                          vector or string scalar to compress all
%                          variables using the same compression algorithm.
%                          To compress each variable with a different
%                          compression algorithm, specify
%                          'VariableCompression' as a cell array of
%                          character vectors or a string vector containing
%                          the names of the compression algorithms to use
%                          for each variable. Valid compression algorithm
%                          names are 'snappy', 'gzip', 'brotli', and
%                          'uncompressed'. By default, all variables are
%                          compressed using the 'snappy' compression
%                          algorithm. In general, 'snappy' compression has
%                          better performance when reading or writing.
%                          'gzip' has a higher compression ratio resulting
%                          in smaller file size, but requires more CPU
%                          processing time. 'brotli' typically produces the
%                          smallest file size, but compression speed may be
%                          slower.
%
%   'VariableEncoding'     Names of the encoding strategy to use when
%                          writing the variables of T to a Parquet file.
%                          Specify 'VariableEncoding' as a character vector
%                          or string scalar to encode all variables using
%                          the same encoding strategy. To encode each
%                          variable with a different encoding strategy,
%                          specify 'VariableEncoding' as a cell array of
%                          character vectors or a string vector containing
%                          the names of the encoding strategy to use for
%                          each variable. Valid encoding names are 'auto',
%                          'dictionary' or 'plain'. By default, all
%                          variables are encoded using the 'auto' encoding
%                          strategy which uses dictionary encoding for all
%                          variables, except any variables of type logical
%                          where plain encoding is used instead. In
%                          general, 'dictionary' encoding results in
%                          smaller file sizes, but 'plain' encoding can be
%                          faster for variables that do not contain many
%                          repeated values.
%
%  'VariableNames'         Variable names to use when writing the variables
%                          of T to a Parquet file. Can be used to write
%                          custom variable names.
%
%  'Version'               Parquet format version to write. Valid versions
%                          are '1.0' or '2.0' (default).  Select Parquet
%                          '1.0' for the broadest compatibility with
%                          external applications that support the Parquet
%                          format.
%
%   Examples:
%
%   % Read a subset of the variables in the Parquet file
%   % 'airlinesmall.parquet' into MATLAB as a timetable.
%   % Use the variable named 'ArrTime' in the Parquet file
%   % as the time vector of the output timetable.
%   data = parquetread('airlinesmall.parquet', ...
%       'SelectedVariableNames', ...
%       {'ArrTime', 'FlightNum', 'ArrDelay'}, ...
%       'RowTimes', 'ArrTime'); 
%
%   % Compute expected arrival time for flights.
%   data.ExpectedArrivalTime = data.ArrTime - data.ArrDelay;
%
%   % Write modified data to a Parquet file named
%   % 'airline_arrivaltimes.parquet' using default snappy compression
%   parquetwrite('airline_arrivaltimes.parquet', data);
%
%   % Write modified data to a Parquet file named
%   % 'airline_arrivaltimes_gzip.parquet' using gzip compression
%   parquetwrite('airline_arrivaltimes_gzip.parquet', data, ...
%       'VariableCompression', 'gzip');
%
%   There are some cases where the Parquet format cannot fully represent
%   the MATLAB table or timetable data types. If you use PARQUETREAD or
%   DATASTORE to read the files, then the result might not have the same
%   format or contents as the original table or timetable. For more
%   information about the Parquet format, see "Apache Parquet Data Type
%   Mappings" in the documentation.
%
%   See also PARQUETREAD, PARQUETINFO, PARQUETDATASTORE, ROWFILTER.

%   Copyright 2018-2024 The MathWorks, Inc.

import matlab.io.parquet.internal.createParquetWriter
import matlab.io.parquet.internal.validateParquetWriteFilename
import matlab.io.parquet.internal.validateTabularShape
import matlab.io.parquet.internal.makeParquetException
import matlab.io.parquet.internal.parseRowGroupHeights
import matlab.io.parquet.internal.parseVariableNames
import matlab.io.internal.arrow.schema.TableSchema;

narginchk(2,inf);
nargoutchk(0,0);

filename = validateParquetWriteFilename(filename);
validateTabularShape(T);

try
    [heights, suppliedHeights] = parseRowGroupHeights(varargin, height(T));
catch e
    throw(e);
end

try
    variableNames = parseVariableNames(varargin, T);
catch e
    throw(e);
end

try

    value = matlab.io.arrow.matlab2arrow(T);
    value.Names = cellstr(variableNames);
    tableSchema = TableSchema.buildTableSchema(value);
    w = createParquetWriter(filename, tableSchema, varargin{:});

    c = onCleanup(@() close(w));

    if suppliedHeights
        w.MaxRowGroupLength = intmax("int64");
    end

    if numel(heights) > 1
        write(w, value, heights);
    else
        write(w, value);
    end
catch e
    e = makeParquetException(e, filename, "write");
    throw(e);
end
end

