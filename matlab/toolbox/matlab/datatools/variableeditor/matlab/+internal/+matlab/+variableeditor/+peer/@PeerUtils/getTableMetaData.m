% This function computes the grouped column information for tables

% Copyright 2014-2023 The MathWorks, Inc.

function tableMetaData = getTableMetaData(variableValue)
    % Indexing will not work for types like curve-fitting objects that cannot be
    % concatenated. Fallback to fetch everything (g2032641).
    try
        tableSubsetValue = variableValue(1,1:min(end,50));
    catch
        tableSubsetValue = variableValue;
    end
    tableMetaData = internal.matlab.datatoolsservices.VariableUtils.getColumnStartIndicies(tableSubsetValue);
end
