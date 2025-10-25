function P = parquetinfo(filename)
%PARQUETINFO Get information about a Parquet file
%   INFO = PARQUETINFO(FILENAME) returns a ParquetInfo object INFO whose
%   properties contain information about parquet file, where FILENAME is 
%   any of the following:
%
%     - For local files, a full path that contains a filename and file
%       extension. FILENAME can also be a relative path to the current 
%       directory, or to a directory on the MATLAB path. 
%       For example, for info on a file on the MATLAB path: 
%          INFO = PARQUETINFO("airlinesmall.parquet");
%
%     - For files from an Internet URL or stored at a remote location
%       FILENAME must be a full path using a Uniform Resource Locator
%       (URL). For example, for info on a remote file from Amazon S3 cloud
%       specify the full URL for the file:
%          INFO = PARQUETINFO("s3://bucketname/path_to_file/data.parquet");
%       For more information on accessing remote data, see 'Work with
%       Remote Data' in the documentation.
%
%   INFO is a ParquetInfo object with the following properties:
%
%
%        Property         Type               Description
%   -------------------  -------  ----------------------------------
%
%   Filename             string   The absolute path to the
%                                 Parquet file.
%
%   FileSize             double   The size of the Parquet
%                                 file in bytes.
%
%   NumRowGroups         double   The number of row groups
%                                 in the Parquet file.
%
%   RowGroupHeights      double   A 1xNumRowGroups vector where
%                                 each element in the vector
%                                 represents the height (the
%                                 number of records, or rows)
%                                 of each corresponding row group
%                                 in the Parquet file.
%
%   VariableNames        string   1xNumVariables string vector
%                                 where each element in the vector
%                                 represents the name of the
%                                 corresponding variable in the
%                                 Parquet file.
%
%   VariableTypes        string   1xNumVariables string vector
%                                 where each element in the
%                                 vector is the name of the
%                                 MATLAB datatype to which the
%                                 corresponding variable in the
%                                 Parquet file maps.
%
%   VariableCompression  string   1xNumVariables string vector
%                                 where each element in the
%                                 vector is the name of the
%                                 compression algorithm used
%                                 to compress the corresponding
%                                 variable in the Parquet file.
%
%   VariableEncoding     string   1xNumVariables string vector
%                                 where each element in the
%                                 vector is the name of the
%                                 encoding strategy used
%                                 to encode the corresponding
%                                 variable in the Parquet file.
%
%   Version              string   The Parquet format version of the file.
%
%   Example:
%
%       % Get information about a Parquet file
%       info = parquetinfo('airlinesmall.parquet');
%       
%       % Inspect the VariableNames in the Parquet file.
%       info.VariableNames
%
%   See also PARQUETREAD, PARQUETWRITE, PARQUETDATASTORE.

%   Copyright 2018-2020 The MathWorks, Inc.

P = matlab.io.parquet.ParquetInfo(filename);
end
