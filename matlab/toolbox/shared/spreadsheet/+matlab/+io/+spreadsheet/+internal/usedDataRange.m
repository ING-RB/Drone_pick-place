function [range, types, numRange] = usedDataRange(sheet, getTypesOnly, range, types)
%USEDDATARANGE Get the data range for a sheet

% Copyright 2015-2024 The MathWorks, Inc.
arguments
    sheet (1, 1) matlab.io.spreadsheet.internal.Sheet
    getTypesOnly (1, 1) logical = false;
    range (:, :) = []; % can be 4-element double, or char of type 'A1' or 'A1:C1'
    types (:, :) double = []; % double matrix
end

if nargin <= 2
    % range was not passed in as input
    range = sheet.usedRange();
end

if isempty(range)
    types = uint8([]);
    numRange = [];
    return;
end

numRange = sheet.getRange(range, false);
if nargin <= 3
    if getTypesOnly
        % Use prefetch method to get only types, no data caching
        types = sheet.prefetch(range);
    else
        % data will also be cached for Google Sheets
        types = sheet.types(range);
    end
end

blanks = (types == sheet.BLANK | types == sheet.EMPTY | types == sheet.ERROR);

allblankrows = all(blanks, 2);
allblankcols = all(blanks, 1);

if all(allblankrows) && all(allblankcols)
    types = uint8([]);
    numRange = [];
    return
end

head_row = find(~allblankrows,1,'first');
tail_row = find(~allblankrows,1,'last');
head_col = find(~allblankcols,1,'first');
tail_col = find(~allblankcols,1,'last');

numRange = [numRange(1) + max([0,head_row])-1,...
            numRange(2) + max([0,head_col])-1,...
            max([0,tail_row])-max([0,head_row-1]),...
            max([0,tail_col])-max([0,head_col-1])];

range = sheet.getRange(numRange);
types = types(head_row:tail_row, head_col:tail_col);

end
