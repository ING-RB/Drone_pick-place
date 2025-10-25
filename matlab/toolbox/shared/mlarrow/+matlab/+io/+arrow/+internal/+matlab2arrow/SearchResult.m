classdef SearchResult
    %SEARCHRESULT A simple wrapper class for
    %             expressing the result of a search
    %             for valid (non-missing) data values
    %             in a cell array.
    
    properties
        FirstValidValueIndex(1,1) double = -1
        CellArrayType(1,1) matlab.io.arrow.internal.matlab2arrow.CellArrayType = matlab.io.arrow.internal.matlab2arrow.CellArrayType.AllMissing
    end

end

