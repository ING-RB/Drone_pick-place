% String Array Parsing for datasets

% Copyright 2023-2025 The MathWorks, Inc.

function cellValueStr = strArrayParsing(d,dSize)
    %% parsing string arrays for a cell in a table
    % Let's say you have a string array as follows
    % 1×3 string array
    %   "hi"    "hello"    "how are you"
    
    % This will be parsed to:
    % '"hi", "hello", "how are you"'

    % Missing values will be replaced by the string <missing>
    
    arguments
        d string
        dSize double
    end
    
    if isempty(d)
        cellValueStr = "<missing>";
        return;
    end

    d(ismissing(d)) = "<missing>";

    if dSize(1) > 1 && dSize(2) == 1
        cellValueStr = join(d, '"; "');
    elseif dSize(1) == 1 && dSize(2) > 1
        cellValueStr = join(d, '", "');
    else
        cellValueStr = join(join(d, '", "'), '"; "');
    end
end