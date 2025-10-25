% nD data in a table is accessed using parentheses and an appropriate number of
% colons.
%
% For example, a 4-by-2-by-7 cell array would have a name of
% <table>.<cellName>(<row>, :, :).
%
% A 4-by-2-by-7-by-3 struct array would have a name of
% <table>.<structArrayName>(<row>, :, :, :).

% Copyright 2017-2023 The MathWorks, Inc.

function editorValue = getNDEditorValue(name, varName, row, sz)
    editorValue = sprintf('%s.%s(%d', name, varName, row);
    for idx = 2:numel(sz)
        editorValue = [editorValue, ',:']; %#ok<AGROW>
    end
    editorValue = [editorValue, ')'];
end
