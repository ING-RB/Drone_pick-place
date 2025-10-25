function rowgroups = processMultipleVariableRowFilter(dispatcher, filter, context)
%processMultipleVariableRowFilter   Applies a MultipleVariableRowFilter to a matlab.io.parquet.internal.filter.ParquetFilterContext.

%   Copyright 2021 The MathWorks, Inc.

    arguments
        dispatcher (1, 1) matlab.io.parquet.internal.filter.ParquetFilterDispatcher
        filter     (1, 1) matlab.io.internal.filter.MultipleVariableRowFilter
        context    (1, 1) matlab.io.parquet.internal.filter.ParquetFilterContext
    end

    % This is fairly straightforward since it just dispatches to the
    % underlying filters.
    import matlab.io.internal.filter.operator.BinaryOperator;

    lhs = getProperties(filter).LHS;
    rhs = getProperties(filter).RHS;
    op  = getProperties(filter).Operator;

    switch op
        case BinaryOperator.And
            rowgroups = dispatcher.dispatch(lhs, context) ...
                      & dispatcher.dispatch(rhs, context);
        case BinaryOperator.Or
            rowgroups = dispatcher.dispatch(lhs, context) ...
                      | dispatcher.dispatch(rhs, context);
        otherwise
            error(message('MATLAB:io:filter:filter:OperatorNotSupported'));
    end
end
