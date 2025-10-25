function names = getPerVarPropNames(tp)
%getPerVarPropNames - get names of per-variable CustomProperties.

% Copyright 2019 The MathWorks, Inc.

% Use a heuristic to detect per-variable CustomProperties - any CustomProperty
% that does not have the correct number of elements must be per-table.
numTableVariables = numel(tp.VariableNames);
names = fieldnames(tp.CustomProperties);
wrongSize = cellfun(@(n) ~isequal(numel(tp.CustomProperties.(n)), ...
                                  numTableVariables), names);
names(wrongSize) = [];
end
