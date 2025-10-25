function combined = combineAccordingToIndices(parameters, indices)
% combineAccordingToIndices - Combine parameters given an array of indices

% Copyright 2020 The MathWorks, Inc.

numParameters = numel(parameters);
numCombinations = size(indices,1);
combined = cell(1, numCombinations);

for combIdx = 1:numCombinations
    thisCombination = cell(1, numParameters);
    for paramIdx = 1:numParameters
        thisCombination{paramIdx} = parameters{paramIdx}(indices(combIdx, paramIdx));
    end
    combined{combIdx} = [thisCombination{:}];
end
end

