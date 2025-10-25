function rowgroups = removeAllNullRowGroups(filter, context, rowgroups, variableIndex)
%removeAllNullRowGroups   Returns a list of rowgroups which excludes
%   rowgroups in which the values are all null (i.e. NullCounts[index] == RowGroupHeights[index]).

%   Copyright 2021 The MathWorks, Inc.

    arguments
        filter  (1, 1) matlab.io.internal.filter.SingleVariableRowFilter
        context (1, 1) matlab.io.parquet.internal.filter.ParquetFilterContext
        rowgroups (:, 1) matlab.io.parquet.internal.filter.RowGroupInclusionState
        variableIndex (1, 1) double {mustBePositive}
    end

    import matlab.io.parquet.internal.filter.RowGroupInclusionState;
    import matlab.io.internal.filter.operator.RelationalOperator;

    % This optimization needs to be carefully applied for two reasons:
    %  1. NullCounts might be invalid, so we need to check HasNullCounts.
    %  2. The NotEquals operator *should* read Null data in, so this
    %     optimization cannot apply if that operator is used.

    % Grab the stats metadata needed for this analysis. Slice into all the
    % metadata using context.RowGroups so that we're only looking at the
    % rowgroups that are necessary for this.
    stats = context.Statistics;
    hasNullCounts   = stats.HasNullCounts(context.RowGroups, variableIndex);
    nullCounts      = stats.NullCounts(context.RowGroups, variableIndex);
    rowGroupHeights = context.ParquetInfo.RowGroupHeights(context.RowGroups);

    % Reshape rowgroup heights to be the same dimensions as null counts.
    rowGroupHeights = reshape(rowGroupHeights, size(nullCounts));

    % Do the actual HasNullCounts/NullCounts check and exclude the
    % rowgroups that are fully null.
    allNullRowGroups = hasNullCounts & (nullCounts == rowGroupHeights);

    % If the operator is NotEqualTo, then all null rowgroups are actually
    % fully included instead of excluded.
    operator = getProperties(filter).Operator;
    if operator == RelationalOperator.NotEqualTo
        rowgroups(allNullRowGroups) = RowGroupInclusionState.FullyIncluded;
    else
        % All null RowGroup is fully excluded.
        rowgroups(allNullRowGroups) = RowGroupInclusionState.FullyExcluded;
    end
end