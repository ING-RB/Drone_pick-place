% Returns the char cell value

% Copyright 2015-2023 The MathWorks, Inc.

function cellVal = getCharCellVal(currentVal) %#ok<INUSD>
    cellVal = string(evalc('disp(currentVal)'));

    % ignore line feeds ,carriage returns, tab
    % escape '"' and '\' since the data will be
    % sent as json string to client
    cellVal = replace(replace(cellVal, {newline, sprintf('\r')}, ''), char(9), '\t');
    cellVal = char(cellVal);
end
