function T = parquetread(filename, varargin)
%PARQUETREAD Read columnar data from a Parquet file.
%   T = PARQUETREAD(FILENAME) returns a table or timetable from a Parquet
%   file, where FILENAME is any of the following:
%
%     - For local files, a full path that contains a filename and file
%       extension. FILENAME can also be a relative path to the current
%       directory, or to a directory on the MATLAB path.
%       For example, to import a file on the MATLAB path:
%          T = PARQUETREAD("airlinesmall.parquet");
%
%     - For files from an Internet URL or stored at a remote location
%       FILENAME must be a full path using an Uniform Resource Locator
%       (URL). For example, to import a remote file from Amazon S3 cloud
%       specify the full URL for the file:
%          T = PARQUETREAD("s3://bucketname/path_to_file/data.parquet");
%       For more information on accessing remote data, see 'Work with
%       Remote Data' in the documentation.
%
%   T = PARQUETREAD(FILENAME, 'Name1', VALUE1, 'Name2', VALUE2, ...)
%   uses name-value pairs to control the reading behavior. Supported
%   name-value pairs are listed below:
%
%            Name                             Value
%   -----------------------  --------------------------------------
%
%   'OutputType'             Name of the output datatype to be
%                            returned by PARQUETREAD. 'OutputType'
%                            can be either 'table', 'timetable',
%                            or 'auto'. If 'OutputType' is set to
%                            'auto', PARQUETREAD will infer the
%                            appropriate 'OutputType' according
%                            to whether any timetable-related
%                            name-value pairs have been provided.
%                            Specifically, if 'RowTimes',
%                            'StartTime', 'SampleRate', or
%                            'TimeStep' are provided, PARQUETREAD
%                            will return a timetable. Otherwise,
%                            it will return a table. By default,
%                            'OutputType' is set to 'auto'.
%
%   'SelectedVariableNames'  Names of the variables in the input
%                            Parquet file to be imported into the
%                            output table or timetable T.
%
%   'VariableNamingRule'     A character vector or a string scalar that
%                            specifies how the output variables are named.
%                            It can have either of the following values:
%
%                            'modify'   Modify variable names to make them
%                                       valid MATLAB Identifiers.
%                                       (default)
%                            'preserve' Preserve original variable names
%                                       allowing names with spaces and
%                                       non-ASCII characters.
%
%   'RowGroups'              Indices of rowgroups to read, specified
%                            as a double vector.
%
%   'RowFilter'              matlab.io.RowFilter instance used for filtering
%                            rows while reading parquet files.
%
%   'RowTimes'               Name of a variable in the input
%                            Parquet file containing datetime
%                            or duration values to use as the
%                            time vector of T, where T is a
%                            timetable. 'RowTimes' can also be
%                            specified as a datetime or duration
%                            vector which will be used as the
%                            time vector of T.
%
%   'StartTime'              A scalar datetime or duration
%                            specifying the start time of the
%                            time vector of T, where T is a
%                            timetable. The value of 'StartTime'
%                            determines whether T has row times
%                            which are absolute ('StartTime' is
%                            a datetime) or relative ('StartTime'
%                            is a duration). 'StartTime' must be
%                            used in conjunction with 'SampleRate'
%                            or 'TimeStep' to implicitly  define
%                            the time vector of T.
%
%   'SampleRate'             A positive numeric scalar specifying
%                            the number of samples per
%                            second (Hz) of the time vector of T,
%                            where T is a timetable. 'SampleRate'
%                            can be used in conjunction with
%                            'StartTime' to implicitly define the
%                            time vector of T.
%
%   'TimeStep'               A scalar duration or calendarDuration
%                            specifying the inter-sample time step
%                            of the time vector of T, where T is a
%                            timetable. 'TimeStep' can be used in
%                            conjunction with 'StartTime' to
%                            implicitly define the time vector
%                            of T.
%
%   Examples:
%
%       % Read a Parquet file
%       data = parquetread('airlinesmall.parquet');
%
%       % Read a subset of the variables in a Parquet file
%       % into MATLAB as a timetable. Use the variable named 'ArrTime'
%       % in the Parquet file as the time vector of the output timetable.
%       data = parquetread('airlinesmall.parquet', ...
%               'SelectedVariableNames', ...
%               {'ArrTime', 'FlightNum', 'ArrDelay'}, ...
%               'RowTimes', 'ArrTime');
%
%   See also ROWFILTER, PARQUETWRITE, PARQUETINFO, PARQUETDATASTORE, TABLE2TIMETABLE.

%   Copyright 2018-2024 The MathWorks, Inc.

import matlab.io.parquet.internal.parquetread2
import matlab.io.parquet.internal.makeParquetException

try
    T = parquetread2(filename, varargin{:});
catch ME
    throw(makeParquetException(ME, filename, "read"));
end
