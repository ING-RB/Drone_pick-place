% This class is unsupported and might change or be removed without
% notice in a future version.

% Copyright 2019 The MathWorks, Inc.
classdef BlankExclusionStrategy < internal.matlab.importtool.server.rules.ExclusionStrategy
    methods
        function exclusions = getExcludedCells(this, columnClasses, data, raw, ...
                dateData, trimNonNumericCols, decimalSeparator, thousandsSeparator)            
            % Called to get the blank cells in the data, based on the data, raw
            % values, date data, and the current column types.  Returns a
            % logical array the size of data, with true values as the blank
            % cells of the range.
            fcn = @cellBlank;
            exclusions = this.getCellExclusions(...
                columnClasses, data, raw, dateData, trimNonNumericCols, ...
                decimalSeparator, thousandsSeparator, fcn);
        end
    end
end

function b = cellBlank(rawVal, dateVal, columnClass, ~, ~, ~)
    % Local private function to look for blanks in the data.  Returns true if
    % the data is blank, false if not.  If the data is blank, all empty spaces
    % is considered blank as well.
    if columnClass == "datetime"
        b = isempty(dateVal);
    else
        if ischar(rawVal) || isstring(rawVal)
            b = isempty(strtrim(rawVal));
        else
            b = isempty(rawVal);
        end
    end
end
