function indices = mapByteOffsetToRowGroupIndices(filename, offset, size)
%mapByteOffsetToRowGroupIndices   Maps an offset and size to a list of
%   rowgroup indices in a Parquet file.

%   Copyright 2022-2023 The MathWorks, Inc.

    arguments
        filename (1, 1) string {mustBeNonzeroLengthText, mustBeNonmissing}
        offset (1, 1) double {mustBeInteger, mustBeNonnegative}
        size (1, 1) double {mustBeInteger, mustBeNonnegative}
    end

    % For now, just construct a RowGroupParquetReader object with offset
    % and size and return the list of RowGroups that are populated on it.
    % TODO: Cache the ParquetReader to avoid having to repeatedly
    % re-opening the file.

    import matlab.io.parquet.internal.RowGroupParquetReader

    reader = RowGroupParquetReader(filename, offset, size);

    indices = reader.RowGroups;
    indices = reshape(indices, [], 1);
end