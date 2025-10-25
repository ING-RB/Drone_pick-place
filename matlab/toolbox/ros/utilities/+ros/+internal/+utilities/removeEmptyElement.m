function filteredCellArray = removeEmptyElement(cellArray)
% removeEmptyElement remove empty element 

%   Copyright 2023 The MathWorks, Inc.

% Use cellfun to check for empty elements
notEmptyIndexes = cellfun(@(x) ~isempty(x), cellArray);

% Use logical indexing to remove empty elements
filteredCellArray = cellArray(notEmptyIndexes);

end
