function cacherCopy = copyElement(cacher)
%copyElement   Make a deep copy of a ParquetReadCacher.
%
%   Makes sure that the handle to a ParquetReader doesn't accidentally get
%   shared between two different cacher objects.

%   Copyright 2022 The MathWorks, Inc.

    % Call the default copyElement (which will make shallow copies of handle and value objects).
    cacherCopy = copyElement@matlab.mixin.Copyable(cacher);

    % Just construct a new ParquetReadCacher using the same Filename.
    import matlab.io.parquet.internal.RowGroupParquetReader
    cacherCopy.InternalReader = RowGroupParquetReader(cacher.Filename, []);
end