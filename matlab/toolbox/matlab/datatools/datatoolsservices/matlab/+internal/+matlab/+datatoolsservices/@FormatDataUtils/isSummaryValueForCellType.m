% isSummary tells us if there is a summaryvalue displayed, valuesToexpand gives
% us a list of summaryValue indices that would be expanded out in a column

% Copyright 2015-2024 The MathWorks, Inc.

function [isSummary, valuesToExpand] = isSummaryValueForCellType(data)
    isSummary = false(length(data),1);
    valuesToExpand = false(length(data), 1);
    for i=1:length(data)
        x = data{i};
        isSummaryOfCell = internal.matlab.datatoolsservices.FormatDataUtils.isSummaryValue(x);
        isSummary(i)=  ~(ischar(x) || (isscalar(x) && (isstring(x) || (isnumeric(x) && ~isobject(x)) || islogical(x) ...
            || iscategorical(x) || isdatetime(x) || isduration(x) || iscalendarduration(x))))  ...
            || isSummaryOfCell;
        % Check to see if any of the data is array data that needs to be
        % expanded because it's within the display criteria Disp always shows
        % arrays as MxN doule but we want to display smallish arrays like [1,2]
        valuesToExpand(i) = ischar(x)|| (~ischar(x) && ~isscalar(x) && ~isSummaryOfCell);
    end
end
