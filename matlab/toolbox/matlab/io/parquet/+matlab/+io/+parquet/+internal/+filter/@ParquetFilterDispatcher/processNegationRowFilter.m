function rowgroups = processNegationRowFilter(dispatcher, filter, context)
%processNegationRowFilter   Applies a NegationRowFilter to a FilteringContext.

%   Copyright 2021 The MathWorks, Inc.

    arguments
        dispatcher (1, 1) matlab.io.parquet.internal.filter.ParquetFilterDispatcher
        filter     (1, 1) matlab.io.internal.filter.NegationRowFilter
        context    (1, 1) matlab.io.parquet.internal.filter.ParquetFilterContext
    end

    underlyingFilter = getProperties(filter).UnderlyingFilter;

    % Negate the inclusion state from the underlying filter tree.
    rowgroups = ~dispatcher.dispatch(underlyingFilter, context);
end
