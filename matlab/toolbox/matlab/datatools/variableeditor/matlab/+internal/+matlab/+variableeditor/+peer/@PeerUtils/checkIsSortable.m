% Check if a variable is sortable

% Copyright 2014-2023 The MathWorks, Inc.

function isSortable = checkIsSortable(variableValue, isPreview)
    f = @(val) (~isPreview && ~(((iscell(val) && ~iscellstr(val)) || isstruct(val) || isinteger(val) && ~isreal(val) || ...
        (isobject(val) && ~iscategorical(val) && ~isstring(val) && ~isdatetime(val) && ~isduration(val)) ...
        || length(size(val)) > 2)));
    if isa(variableValue, 'dataset')
        isSortable = datasetfun(f, variableValue, 'UniformOutput', true);
    else
        isSortable = varfun(f, variableValue, 'OutputFormat', 'uniform');
    end
end
