function combined = combine(~, parameters)
%

% Copyright 2020 The MathWorks, Inc.

parameterSize = numel(parameters{1});
parameters = cellfun(@(p)reshape(p,[],1), parameters, "UniformOutput",false);
combined = rot90(mat2cell([parameters{:}], ones(1,parameterSize), numel(parameters)));
end

