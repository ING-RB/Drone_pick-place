% This class is unsupported and might change or be removed without
% notice in a future version.

% Copyright 2019-2020 The MathWorks, Inc.

classdef UnimportableExclusionStrategy < internal.matlab.importtool.server.rules.ExclusionStrategy
    
    methods
        function exclusions = getExcludedCells(this, columnClasses, data, raw, ...
                dateData, trimNonNumericCols, decimalSeparator, thousandsSeparator)
            % Called to get the unimportable cells in the data, based on the
            % data, raw values, date data, and the current column types.
            % Returns a logical array the size of data, with true values as the
            % unimportable cells of the range.
            fcn = @cellUnimportable;
            exclusions = this.getCellExclusions(...
                columnClasses, data, raw, dateData, trimNonNumericCols, ...
                decimalSeparator, thousandsSeparator, fcn);
        end
    end
end

function b = cellUnimportable(rawVal, dateVal, columnClass, trimNonNumericCols, ...
        decimalSeparator, thousandsSeparator)
    % Local private function to look for unimportable cells in the data.
    % Returns true if the data is unimportable based on the type, and false if
    % not.
    if columnClass == "datetime"
        b = isempty(dateVal);
    elseif columnClass == "duration"
        b = isempty(rawVal);
    elseif trimNonNumericCols
        b = isempty(rawVal);
        if isnumeric(rawVal)
            b = false;
        elseif ~b
            extractedVal = internal.matlab.datatoolsservices.preprocessing.VariableTypeDetectionService.extractNumberFromText(...
                rawVal, decimalSeparator, thousandsSeparator);
            b = isempty(extractedVal);
        end
    else
        b = isempty(rawVal); %#ok<*NASGU>
        if isnumeric(rawVal)
            b = isnan(rawVal);
        else
            % Extra checks for numeric values.  In the case above for
            % trimNonNumericCols, the VariableTypeDetectionService does this.
            % But when we aren't trimming, we need to add explicit checks for
            % values which convert to numeric:
            
            % 1) Numbers with commas in them.  str2double handles conversion of
            % numbers with commas in it.  This may not be interpreted correctly
            % if the thousandsSeparator isn't comma (for example, in Europe a
            % number may be '1.000,23') -- but that's ok, we're just testing for
            % a numeric value here in a performant manner, not necessarily the
            % correct value.
            dblVal = str2double(rawVal);
            if ~isnan(dblVal)
                b = false;
            else
                % 2) Cells are not unimportable if they contain the text "nan",
                % or if they contain a number followed by 'i' or 'j', like "23i"
                % or "5j"
                b = ~strcmpi(rawVal, "nan") && ~((endsWith(rawVal, "i") || endsWith(rawVal, "j")) && ...
                    (any(regexp(rawVal, "^\d*i")) || any(regexp(rawVal, "^\d*j"))));
            end
        end
    end
end
