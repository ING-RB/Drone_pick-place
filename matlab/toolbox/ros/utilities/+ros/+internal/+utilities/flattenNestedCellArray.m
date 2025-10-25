function flatCellArray = flattenNestedCellArray(nestedCell)
% flattenNestedCellArray converts nested cell array to 1xn array

%   Copyright 2023 The MathWorks, Inc.

% Initialize an empty cell array to store the flattened elements
flatCellArray = {};

% Loop through the nested cell array and flatten it
for i = 1:numel(nestedCell)
    if ischar(nestedCell{i})
        flatCellArray{end+1} = nestedCell{i}; %#ok<AGROW>
    else
        flatCellArray = [flatCellArray, nestedCell{i}]; %#ok<AGROW>
    end
end

% Convert the cell array to a 1-by-N cell array of character vectors
flatCellArray = cellfun(@(x) char(x), flatCellArray, 'UniformOutput', false);
end

