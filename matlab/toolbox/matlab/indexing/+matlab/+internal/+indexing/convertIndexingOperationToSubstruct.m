function out = convertIndexingOperationToSubstruct(indexingOperation)
% convertIndexingOperationToSubstruct transform indexing operation
%   This function is for internal use only and might change or be removed
%   without notice in a future version. Do not use this function.

%   Copyright 2020-2021 The MathWorks, Inc.

arguments
    indexingOperation matlab.indexing.IndexingOperation
end

tempCell = cell(size(indexingOperation));
out = struct("type", tempCell, "subs", tempCell);
for j = 1:numel(out)
    [out(j).type, out(j).subs] = convertIndexingOperation(indexingOperation(j));
end

end

function [type, subs] = convertIndexingOperation(indexingOperation)
switch indexingOperation.Type
    case {matlab.indexing.IndexingOperationType.Paren, matlab.indexing.IndexingOperationType.ParenDelete}
        type = '()';
        subs = indexingOperation.Indices;
    case matlab.indexing.IndexingOperationType.Brace
        type = '{}';
        subs = indexingOperation.Indices;
    case matlab.indexing.IndexingOperationType.Dot
        type = '.';
        subs = convertStringsToChars(indexingOperation.Name);
end
end
