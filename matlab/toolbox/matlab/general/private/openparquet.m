function out = openparquet(filename)
%OPENPARQUET open handler for Parquet files
%   Imports a table from the Parquet file using variable name based on the
%   filename.
%
%   See also PARQUETREAD, OPEN

%   Copyright 2018-2021 The MathWorks, Inc.

out = parquetread(filename);
end