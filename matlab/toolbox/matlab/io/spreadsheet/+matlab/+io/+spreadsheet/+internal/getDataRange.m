function dataRange = getDataRange(sheet,dataloc, numVars, usedRange, rowsToRequest)
%GETDATARANGE Returns the two-corner range from which to read data.
%
% Input Arguments:
% 
% sheet        - Excel sheet from which to read data
% dataloc      - unprocessed data range
% numVars      - number of columns the data range should span
% usedRange    - A two-corner range spanning all 
%                non-blank cells in the Excel sheet
% rowsToRequst - Minimum number of rows the output dataRange must span. 
%                If not supplied, it is set to 0.


% Copyright 2020 The MathWorks, Inc.

    if nargin < 5
        % set the minimum rows to read to zero if rowsToRequest is not
        % provided as an input argument to getDataRange
        rowsToRequest = 0;
    end

    % processes the dataloc and converts it into either a char vector of a
    % scalar numeric value
    dataloc = processDataLocation(dataloc, usedRange);
    
    if isempty(dataloc)
        % Return a default dataRange vector if dataloc is an empty vector
        dataRange = [1 1 0 0];
        return;
    end
    
    if isempty(usedRange)
        usedRange = [1 1 0 0];
    end

    if isnumeric(dataloc) && isscalar(dataloc)
        % dataloc = Row/Column number
        usedRange(1) = dataloc; % first row
        dataRange = matlab.io.spreadsheet.internal.subRange(usedRange,[1 numVars]);
    else 
        % dataloc is a char vector
        if usedRange(3) < rowsToRequest
            % get more rows
            usedRange(3) = usedRange(1) + rowsToRequest - 1;
        end
        [dataRange,type] = sheet.getRange(dataloc,false);
        switch (type)
        case "single-cell"
            % Start cell, read numVars columns, and all the rows until the end range.
            dataRange    = matlab.io.spreadsheet.internal.subRange(dataRange,[1 numVars]);
            % get last usedRange row number
            lastUsedRow  = usedRange(1) + usedRange(3) - 1;
            % set the number of rows
            dataRange(3) = lastUsedRow - dataRange(1) + 1;
            case "row-only"
            % Read numVars columns from the first column in the usedRange.
            dataRange(2) = usedRange(2);
            dataRange = matlab.io.spreadsheet.internal.subRange(dataRange,[1 numVars]);
        case "column-only"
            % Do nothing if dataRange's type is column-only
        case "named"
            if dataRange(4) ~= numVars
                % error the number of columns in dataRange does not match 
                % the number of variables expected.
                error(message("MATLAB:spreadsheet:importoptions:VarNumberMismatch","DataRange"));
            end
        end
    end
    % if the used range is empty, then we may end up with negative values for
    % the extents [1 1 -1 -1]. Since this is invalid, we replace them with
    % zero.
    dataRange(dataRange < 0) = 0;
end

function dataloc = processDataLocation(range, usedRange)
%   Examples:
%
%   processDataLocation("A1:B5", [1 1 20 2]) returns 'A1:B5'
%   processDataLocation([1 10], [1 1 20 2]) returns '1:10'
%   processDataLocation([1 inf], [1 1 20 2]) returns '1:20'
%   processDataLocation(4, [1 1 20 2]) returns 4

    range = convertStringsToChars(range);
    if iscell(range)
        dataloc = range{:};
    elseif ~isscalar(range) && isnumeric(range)
        % replace inf with the end of the usedRange
        if any(isinf(range))
            range(2) = usedRange(1) + usedRange(3) - 1;
        end
        dataloc = [num2str(range(1)),':',num2str(range(2))];
    else
        dataloc = range;
    end
end