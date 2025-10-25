function rowgroups = removeFullyExcludedRowGroups(filter, context, rowgroups, variableIndex)
%removeFullyExcludedRowGroups   Remove RowGroups that are fully excluded by
%   the input SingleVariableRowFilter.

%   Copyright 2021-2022 The MathWorks, Inc.

    arguments
        filter  (1, 1) matlab.io.internal.filter.SingleVariableRowFilter
        context (1, 1) matlab.io.parquet.internal.filter.ParquetFilterContext
        rowgroups (:, 1) matlab.io.parquet.internal.filter.RowGroupInclusionState
        variableIndex (1, 1) double {mustBePositive}
    end

    import matlab.io.parquet.internal.filter.RowGroupInclusionState;

    % This is the core of the Parquet filtering codebase.
    % The Min/Max metadata in a rowgroup is "interpreted" with the input
    % SingleVariableRowFilter. We then decide whether to read the data into
    % memory or skip it.

    % Grab min/max metadata for filtering. Remember to avoid trusting
    % MinValues and MaxValues until HasMinMaxValues has been
    % checked.
    stats = context.Statistics;
    hasMinMaxValues = stats.HasMinMaxValues(context.RowGroups, variableIndex);
    minValues       = stats.MinValues{1, variableIndex}(context.RowGroups);
    maxValues       = stats.MaxValues{1, variableIndex}(context.RowGroups);

    % Only perform the min/max filter over rowgroups that have min/max metadata.
    shouldRemove = false(size(rowgroups));
    shouldRemove(hasMinMaxValues) = applyIndividualOperatorWithThrow(minValues(hasMinMaxValues), ...
                                                                     maxValues(hasMinMaxValues), filter);

    % Keep the rowgroups that we don't have min/max metadata for.
    rowgroups(shouldRemove) = RowGroupInclusionState.FullyExcluded;
end

%--------------------------------------------------------------------------
function shouldRemove = applyIndividualOperatorWithThrow(minValue, maxValue, filter)

    import matlab.io.internal.filter.util.handleRelationalOperatorError;

    try
        shouldRemove = applyIndividualOperator(minValue, maxValue, filter);
    catch ME
        operand = getProperties(filter).Operand;
        operator = getProperties(filter).Operator;
        variableName = getProperties(filter).VariableName;
        handleRelationalOperatorError(variableName, class(minValue), operator, operand, ME)
    end
end

%--------------------------------------------------------------------------
function shouldRemove = applyIndividualOperator(minValue, maxValue, filter)
    import matlab.io.internal.filter.operator.RelationalOperator;

    operand = getProperties(filter).Operand;
    operator = getProperties(filter).Operator;

    switch operator
        case RelationalOperator.EqualTo
            % Remove this column chunk if the operand doesn't fall in
            % between the min and max value in the rowgroup.
            shouldRemove = minValue > operand | maxValue < operand;
        case RelationalOperator.NotEqualTo
            % Can only safely remove this column chunk if ALL values in the
            % column chunk are equal to the operand.
            shouldRemove = minValue == operand & maxValue == operand;

        case RelationalOperator.GreaterThan
            % If all data in the column chunk is less than the operand,
            % then the constraint cannot be satisfied.
            shouldRemove = maxValue <= operand;
        case RelationalOperator.GreaterThanOrEqualTo
            shouldRemove = maxValue < operand;

        case RelationalOperator.LessThan
            % If all data in the column chunk is greater than the
            % operand, then the constraint cannot be satisfied.
            shouldRemove = minValue >= operand;
        case RelationalOperator.LessThanOrEqualTo
            shouldRemove = minValue > operand;

        otherwise
            error(message('MATLAB:io:filter:filter:OperatorNotSupported'));
    end
end
