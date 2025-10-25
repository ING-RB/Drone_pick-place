function b = cellstr(a) %#codegen
%CELLSTR Convert categorical array to cell array of character vectors.

%   Copyright 2018-2020 The MathWorks, Inc.

sz = numel(a.categoryNames)+1;
names = coder.nullcopy(cell(sz,1)); % else coder thinks not all of names is assigned
names{1} = categorical.undefLabel;
for i = 2:sz
    names{i} = a.categoryNames{i-1};
end

tempnames = matlab.internal.coder.datatypes.cellstr_parenReference(names, a.codes(:) + 1);
b = reshape(tempnames,size(a.codes));
