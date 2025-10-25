% This class is unsupported and might change or be removed without
% notice in a future version.

% Copyright 2019 The MathWorks, Inc.

classdef ExclusionStrategy < handle
    
    methods
        function exclusions = getCellExclusions(~, columnClasses, data, raw, ...
                dateData, trimNonNumericCols, decimalSeparator, thousandsSeparator, fcn)
            % Static function used to find the cell exclusions based on the
            % column types, and values of data, raw data, and date data.
            % Returns a logical array the size of data, with true for any values
            % matching the exclusions returned from the fcn function.
            
            % Only consider double, duration and datetime columns for
            % exclusions.  (For example, blanks in text columns don't effect the
            % excluded data)
            classesToCheck = contains(columnClasses, ...
                {'double', 'duration', 'datetime'});
            
            [numrows, numcols] = size(data);
            excludedCells = false(numrows, 0);
            exclusions = false(numrows, numcols);
            
            if any(classesToCheck)
                % Build out the array of exclusions, column by column, setting
                % false for any column types we're not checking
                for idx = 1:numcols
                    if any(idx == find(classesToCheck))
                        % For double, datetime and duration columns, call the
                        % provided function for the given cell data
                        f = cellfun(@(x, y) ...
                            fcn(x, y, columnClasses(idx), trimNonNumericCols(idx), decimalSeparator, thousandsSeparator), ...
                            raw(:, idx), dateData(:, idx));
                    else
                        f = false(numrows, 1);
                    end
                    
                    excludedCells = [excludedCells, f]; %#ok<*AGROW>
                end
                
                exclusions = excludedCells;
            end
        end
    end
end


