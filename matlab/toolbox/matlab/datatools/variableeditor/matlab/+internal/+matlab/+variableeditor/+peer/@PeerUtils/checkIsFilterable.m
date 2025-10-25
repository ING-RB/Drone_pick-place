% Check if variable is filterable

% Copyright 2014-2023 The MathWorks, Inc.

function isFilterable = checkIsFilterable(variableValue, isPreview)
    if isa(variableValue, 'dataset')
        isValidName = isvarname(variableValue.Properties.VarNames{:});
    else
        isValidName = isvarname(variableValue.Properties.VariableNames{:});
    end
    f = @(val) (isValidName && ~isPreview && ~(((iscell(val) && ~iscellstr(val)) || isstruct(val) || ...
        (isobject(val) && ~iscategorical(val) && ~isstring(val) && ~isdatetime(val) && ~isduration(val)) ...
        || (isnumeric(val) && ~isreal(val)) || length(size(val)) > 2 || size(val,2) > 1)));
    if isa(variableValue, "dataset")
        isFilterable = datasetfun(f, variableValue, 'UniformOutput', true);
    else
        isFilterable = varfun(f, variableValue, 'OutputFormat', 'uniform');
    end
end
