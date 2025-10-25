function rowgroups = processSingleVariableRowFilter(~, filter, context)
%processSingleVariableRowFilter   Applies a SingleVariableRowFilter to a
%   matlab.io.parquet.internal.filter.ParquetFilterContext.

%   Copyright 2021 The MathWorks, Inc.

    arguments
        ~
        filter  (1, 1) matlab.io.internal.filter.SingleVariableRowFilter
        context (1, 1) matlab.io.parquet.internal.filter.ParquetFilterContext
    end

    import matlab.io.parquet.internal.filter.*;

    % Find the index of the variable name in the statistics struct.
    variableName = getProperties(filter).VariableName;
    variableIndex = find(context.Statistics.VariableNames == variableName, 1);

    % Start by assuming that all rowgroups will be read in.
    % "PartialInclusion" is considered a stronger inclusion criterion since
    % negation won't exclude it.
    rowgroups = repmat(RowGroupInclusionState.PartiallyIncluded, size(context.RowGroups));

    % The actual filtering is split into 4 stages:
    %  1. Removal of zero-height rowgroups.
    rowgroups = removeZeroHeightRowGroups(context, rowgroups);

    %  2. Removal of rowgroups where every value is null.
    rowgroups = removeAllNullRowGroups(filter, context, rowgroups, variableIndex);

    %  3. Categorization of FullyExcluded rowgroups. All rows in these
    %  rowgroups are excluded, which means that negation must read all the
    %  data in these rowgroups into memory.
    rowgroups = removeFullyExcludedRowGroups(filter, context, rowgroups, variableIndex);

    %  4. Categorization of FullyIncluded rowgroups. All rows in these
    %  rowgroups are included, which means that negation can skip the data
    %  in these rowgroups.
    rowgroups = categorizeFullyIncludedRowGroups(filter, context, rowgroups, variableIndex);
end
