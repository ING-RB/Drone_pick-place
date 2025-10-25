function rowgroups = removeZeroHeightRowGroups(context, rowgroups)
%removeZeroHeightRowGroups   Returns a list of rowgroups that excludes rowgroups
%   with a height = 0.

%   Copyright 2021 The MathWorks, Inc.

    arguments
        context (1, 1) matlab.io.parquet.internal.filter.ParquetFilterContext
        rowgroups (:, 1) matlab.io.parquet.internal.filter.RowGroupInclusionState
    end

    import matlab.io.parquet.internal.filter.RowGroupInclusionState;

    % Index into the RowGroupHeights metadata using the selected rowgroup
    % indices.
    rowGroupHeights = context.ParquetInfo.RowGroupHeights(context.RowGroups);

    % Fully exclude rowgroups that have a known height of 0.
    rowgroups(rowGroupHeights == 0) = RowGroupInclusionState.FullyExcluded;
end