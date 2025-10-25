function rowgroups = categorizeFullyIncludedRowGroups(filter, context, rowgroups, variableIndex)
%categorizeFullyIncludedRowGroups   Mark FullyIncluded RowGroups so that 
%   the negation operator can choose to exclude them later.

%   Copyright 2021 The MathWorks, Inc.

    arguments
        filter        (1, 1) matlab.io.internal.filter.SingleVariableRowFilter
        context       (1, 1) matlab.io.parquet.internal.filter.ParquetFilterContext
        rowgroups     (:, 1) matlab.io.parquet.internal.filter.RowGroupInclusionState
        variableIndex (1, 1) double {mustBePositive}
    end

    import matlab.io.parquet.internal.filter.RowGroupInclusionState;

    % Grab min/max metadata for filtering. Remember to avoid trusting
    % MinValues and MaxValues until HasMinMaxValues has been
    % checked.
    stats = context.Statistics;
    hasMinMaxValues = stats.HasMinMaxValues(context.RowGroups, variableIndex);
    minValues       = stats.MinValues{1, variableIndex}(context.RowGroups);
    maxValues       = stats.MaxValues{1, variableIndex}(context.RowGroups);

    hasNullCounts   = stats.HasNullCounts(context.RowGroups, variableIndex);
    nullCounts      = stats.NullCounts(context.RowGroups, variableIndex);

    % Any rowgroup that has a null value cannot be fully included, since
    % the null value will be filtered out (rowfilter operand can't be
    % a missing/null value).
    shouldCheckInclusion = hasNullCounts & (nullCounts == 0);

    % Only do this check for rowgroups that are already marked as partially
    % included. No need to check this for fully included/excluded rowgroups.
    shouldCheckInclusion = shouldCheckInclusion ...
                         & hasMinMaxValues & (rowgroups == RowGroupInclusionState.PartiallyIncluded);

    % Only perform the min/max filter over rowgroups that have min/max metadata.
    isFullyIncluded = false(size(rowgroups));
    isFullyIncluded(shouldCheckInclusion) = checkFullInclusionUsingOperator(minValues(shouldCheckInclusion), ...
                                                                            maxValues(shouldCheckInclusion), ...
                                                                            filter);

    % Mark these rowgroups as "fully included". This means that a negation
    % operator could exclude this rowgroup entirely.
    rowgroups(isFullyIncluded) = RowGroupInclusionState.FullyIncluded;
end

%--------------------------------------------------------------------------
function isFullyIncluded = checkFullInclusionUsingOperator(minValue, maxValue, filter)
    import matlab.io.internal.filter.operator.RelationalOperator;

    operand = getProperties(filter).Operand;
    operator = getProperties(filter).Operator;

    % This is a much more strict check than the one for Full Exclusion.
    % Since every value in the rowgroup must satisfy the filter.

    switch operator
        case RelationalOperator.EqualTo
            % Fully included if both min and max exactly match the operand.
            isFullyIncluded = minValue == operand & maxValue == operand;
        case RelationalOperator.NotEqualTo
            % Fully included if the max value is strictly less than the
            % operand or the min value is strictly greater than the
            % operand.
            isFullyIncluded = minValue >  operand | maxValue <  operand;

        case RelationalOperator.GreaterThan
            % Fully included if the min value is greater than the operand.
            isFullyIncluded = minValue > operand;
        case RelationalOperator.GreaterThanOrEqualTo
            isFullyIncluded = minValue >= operand;

        case RelationalOperator.LessThan
            % Fully included if the max value is less than the operand.
            isFullyIncluded = maxValue < operand;
        case RelationalOperator.LessThanOrEqualTo
            isFullyIncluded = maxValue <= operand;

        otherwise
            error(message('MATLAB:io:filter:filter:OperatorNotSupported'));
    end
end
