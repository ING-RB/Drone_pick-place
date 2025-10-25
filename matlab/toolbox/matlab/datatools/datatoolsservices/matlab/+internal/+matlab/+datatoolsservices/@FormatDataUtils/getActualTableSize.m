% If tables have grouped columns then it returns the column number as the total
% columns including the sub columns (inside grouped columns) Ex: if table has 1
% grouped column with 5 sub columns within then returns [1 5]

% Copyright 2015-2023 The MathWorks, Inc.

function tableSize = getActualTableSize(value)
    tableSize = [size(value,1) sum(varfun(@(x) size(x,2),value, 'OutputFormat', 'uniform'))];
end
