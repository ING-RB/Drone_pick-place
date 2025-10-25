% Resolves a requested start/end row/column range with the size of a data
% object.  Used to provide a standard response to requests which may be out of
% range.

% Copyright 2015-2023 The MathWorks, Inc.

function [startRow, endRow, startColumn, endColumn] = resolveRequestSizeWithObj(...
        startRow, endRow, startColumn, endColumn, sz)
    startRow = min(max(1, startRow), sz(1));
    endRow = min(max(1, endRow), sz(1));
    startColumn = min(max(1, startColumn), sz(2));
    endColumn = min(max(1, endColumn), sz(2));
end
