% Expandable Array Parsing for datasets

% Copyright 2023 The MathWorks, Inc.

function cellValue = expandableArrayParsing(d,dSize)
    %% parsing any expandable datatype arrays for a table cell
    % These include "categorical", "nominal", "ordinal", "datetime", "duration"
    % and "calendarDuration"
    % Let's say you have a categorical array as follows
    % 2×1 categorical array
    %   mathworks at its best
    %   mathworks is a great company
    
    % This will be parsed to:
    % 'mathworks at its best; mathworks is a great company'
    
    arguments
        d
        dSize double
    end
    dStr = cellstr(d);
    if dSize(1) > 1 && dSize(2) == 1
        strCellArray = join(dStr, '; ');
    elseif dSize(1) == 1 && dSize(2) > 1
        strCellArray = join(dStr, ', ');
    else
        strCellArray = join(join(dStr, ', '), ' ; ');
    end
    cellValue = strCellArray{1};
end