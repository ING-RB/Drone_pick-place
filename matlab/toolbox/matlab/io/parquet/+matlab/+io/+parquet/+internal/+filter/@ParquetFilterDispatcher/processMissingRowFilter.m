function rowgroups = processMissingRowFilter(dispatcher, filter, context)
%processMissingRowFilter   Applies a MissingRowFilter to a FilteringContext.

%   Copyright 2021 The MathWorks, Inc.

    arguments
        dispatcher (1, 1) matlab.io.parquet.internal.filter.ParquetFilterDispatcher
        filter     (1, 1) matlab.io.internal.filter.MissingRowFilter
        context    (1, 1) matlab.io.parquet.internal.filter.ParquetFilterContext
    end

    import matlab.io.parquet.internal.filter.*;

    % No constraints defined. Just read everything in.
    rowgroups = repmat(RowGroupInclusionState.FullyIncluded, size(context.RowGroups));
end
