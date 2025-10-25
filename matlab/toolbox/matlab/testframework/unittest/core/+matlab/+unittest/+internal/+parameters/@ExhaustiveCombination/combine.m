function combined = combine(~, parameters)
%

% Copyright 2020 The MathWorks, Inc.

import matlab.unittest.internal.parameters.combineAccordingToIndices;

parameterSizes = cellfun(@numel, parameters);
numParameters = numel(parameters);

% Define grids for indexing into the Parameters to create all combinations.
% Use FLIPLR twice to get canonical ordering.
indices = fliplr(arrayfun(@(sz)1:sz, parameterSizes, "UniformOutput",false));
[grids{1:numParameters}] = ndgrid(indices{:});
grids = fliplr(grids);

% Covert to an array of indices
grids = cellfun(@(g)g(:), grids, "UniformOutput",false);
allCombIdx = [grids{:}];

combined = combineAccordingToIndices(parameters, allCombIdx);
end

