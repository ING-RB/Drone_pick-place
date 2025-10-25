classdef ParquetFilterContext
%ParquetFilterContext   Stores the rowfilter, ParquetInfo, and rowgroups
%   needed for a filtering operation.
%
%   Mainly used by internal functions in the filterRowGroups function and
%   ParquetFilterDispatcher class.

%   Copyright 2021 The MathWorks, Inc.

    properties
        Filter      (1, 1) matlab.io.internal.AbstractRowFilter = rowfilter(missing)
        RowGroups   (:, 1) double {mustBePositive}
        Statistics  (1, 1) struct
        ParquetInfo
    end

    methods
        function ctx = ParquetFilterContext(filter, rowgroups, statistics, info)
            arguments
                filter     (1, 1) matlab.io.internal.AbstractRowFilter
                rowgroups  (:, 1) double
                statistics (1, 1) struct
                info % Is a ParquetInfo in the legacy code, but is a ParquetReader in the refactored code.
            end

            ctx.Filter = filter;
            ctx.RowGroups = rowgroups;
            ctx.Statistics = statistics;
            ctx.ParquetInfo = info;
        end
    end

    methods (Static)
        function ctx = construct(filename, filter, rowgroups, info)
            arguments
                filename
                filter    (1, 1) matlab.io.RowFilter
                rowgroups (:, 1) double
                info
            end

            import matlab.io.parquet.internal.filter.*;
            import matlab.io.internal.filter.validators.validateVariableNames;

            % Find the indices of the constrained variables amongst the info
            % variable names.
            selectedVariableIndices = validateVariableNames(filter, info.VariableNames);

            % Get statistics metadata from the file for these variables.
            statistics = readStatisticsTables(filename, selectedVariableIndices);

            % Also store the original filter names on the statistics struct since it
            % needs to be used later.
            statistics.VariableNames = constrainedVariableNames(filter);

            % Now construct a ParquetfilterContext object with the inputs to
            % group all this metadata together.
            ctx = ParquetFilterContext(filter, rowgroups, statistics, info);
        end
    end
end
