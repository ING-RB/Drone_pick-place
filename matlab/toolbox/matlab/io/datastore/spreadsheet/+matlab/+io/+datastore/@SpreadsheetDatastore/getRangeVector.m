function rangeVec = getRangeVector(sheetObj, range)
%GETRANGEVECTOR Sets the Range Vector given a sheet object and a range
%   This function is responsible to set a range vector given a sheet object
%   and a range. This is useful during introspection.

%   Copyright 2015-2018 The MathWorks, Inc.

    % imports
    import matlab.io.internal.validators.isCharVector;
    import matlab.io.datastore.SpreadsheetDatastore;

    rangeStr = sheetObj.getDataSpan;
    % for empty sheets return an empty range vector
    if isempty(rangeStr)
        rangeVec = [];
        return;
    else
        % setup rangeStr as a vector
        rangeVec = sheetObj.getRange(rangeStr, false);
    end

    % early return for empty range, rangeVec must start from the beginning
    % of the sheet
    if isCharVector(range) && isempty(range)
        rangeVec = [1 1 rangeVec(3)+rangeVec(1)-1 rangeVec(4)+rangeVec(2)-1];
        return;
    end

    % handle column-only and absolute ranges separately.
    [numRange, rangetype] = sheetObj.getRange(range, false);
    if strcmp(rangetype, 'column-only')
        rangeVec = [1 numRange(2) numRange(3)+numRange(1)-1 numRange(4)];
    else
        rangeVec = numRange;
    end
end
