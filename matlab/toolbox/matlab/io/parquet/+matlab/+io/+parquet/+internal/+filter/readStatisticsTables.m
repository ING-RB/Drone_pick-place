function statistics = readStatisticsTables(filename, selectedVariableIndices)
%readStatisticsTables   Reads NullCounts, MinValues, and MaxValues
%   from a Parquet file and converts them into tables for
%   easy consumption.
%
%   NOTE: The "statistics" output argument is a struct containing
%         fields called "HasNullCounts", "HasMinMaxValues", "NullCounts",
%         "MinValues", "MaxValues".
%         Each of those struct fields store an N-by-M table,
%         where N is the number of rowgroups in the Parquet file and M is
%         the number of selected variables in the Parquet file.

%   Copyright 2021-2024 The MathWorks, Inc.

    import matlab.io.arrow.arrow2matlab;

    % Convert selectedVariableIndices to 0-based for use with the C++
    % layer.
    selectedVariableIndices = int32(selectedVariableIndices - 1);

    try
        % Read the actual statistics from the Parquet file.
        filename = matlab.io.parquet.internal.makeParquetReadCacher(filename);
        % Refactored code path.
        statistics = filename.InternalReader.getStatistics(selectedVariableIndices);
    catch ME
        if ME.identifier == "MATLAB:parquetio:read:InternalUnsupportedParquetType"
            % One of the variables we requested statistics is not supported
            % for conversion to MATLAB. Throw the UnsupportedParquetType
            % error.
            ME = matlab.io.parquet.internal.makeParquetException(ME, filename, "read");
        end
        throw(ME);
    end

    % Convert min/max statistics properties to cells.
    % MinValues and MaxValues need to go through mlarrow to turn into
    % useable values in MATLAB.
    statistics.MinValues = cellfun(@arrow2matlab, statistics.MinValues, UniformOutput=false);
    statistics.MaxValues = cellfun(@arrow2matlab, statistics.MaxValues, UniformOutput=false);
end
