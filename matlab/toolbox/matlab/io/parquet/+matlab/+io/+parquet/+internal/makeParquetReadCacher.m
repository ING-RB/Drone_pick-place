function filename = makeParquetReadCacher(filename)
%makeParquetReadCacher   Converts the input filename to a
%   ParquetReadCacher if its a valid Parquet file.

%   Copyright 2022-2023 The MathWorks, Inc

    if ~isa(filename, "matlab.io.parquet.internal.ParquetReadCacher")
        % Convert to ParquetReadCacher.
        filename = matlab.io.parquet.internal.ParquetReadCacher(filename);
    end
end