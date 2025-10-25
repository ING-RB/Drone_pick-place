function mask = findStatementsOnExecutableLinesMask(executableLines,sourcePositionDataForStatement)
% This helper is undocumented and may change in a future release.

% Copyright 2021 The MathWorks, Inc.

% This returns is a MxN matrix of boolean values where M is the number
% of statements and N is the number of  executable lines.
mask = false(1,numel(executableLines));
maskMatrix = executableLines == sourcePositionDataForStatement(:,1);

% For statements spanning multiple lines, snap the number of rows into one
% per statement
for rowIdx = 1:height(maskMatrix)
    mask = bitor(mask,maskMatrix(rowIdx,:));
end
end