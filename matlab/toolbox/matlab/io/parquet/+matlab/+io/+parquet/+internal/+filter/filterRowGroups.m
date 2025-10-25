function rowgroups = filterRowGroups(filename, filter, rowgroups, info)
%filterRowGroups   filters out any non-matching rowgroups from the input
%   filename.
%
%   You can optionally provide a custom list of rowgroups or SelectedVariableNames
%   to sub-select from.

%   Copyright 2021-2023 The MathWorks, Inc.

    arguments
        filename
        filter    (1, 1) matlab.io.RowFilter
        rowgroups (:, 1) double {mustBePositive}
        info = []
    end

    filename = matlab.io.parquet.internal.makeParquetReadCacher(filename);

    if isempty(info)
        info = filename.InternalReader;
    end
   
    import matlab.io.parquet.internal.filter.*;

    % Generate a "Filtering Context" object to be used by the rest of the
    % filter functions. Read statistics metadata for the variables being
    % constrained in the filter.
    ctx = ParquetFilterContext.construct(filename, filter, rowgroups, info);

    % Traverse the filter tree and use statistics metadata to include/exclude
    % rowgroups.
    rowgroupInclusionMask = ParquetFilterDispatcher().dispatch(filter, ctx);

    % Remove all rowgroups which can be fully excluded. Keep rowgroups that
    % are fully included or partially included.
    rowgroups = rowgroups(rowgroupInclusionMask ~= RowGroupInclusionState.FullyExcluded);

    % Reshape to a column vector.
    rowgroups = reshape(rowgroups, [], 1);
end
