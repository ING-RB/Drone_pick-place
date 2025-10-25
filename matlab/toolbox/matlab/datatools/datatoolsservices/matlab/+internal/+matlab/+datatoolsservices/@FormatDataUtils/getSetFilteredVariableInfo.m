% Get/Set the filtered variable information

% Copyright 2015-2023 The MathWorks, Inc.

function [isFiltered, filteredRowCount] = getSetFilteredVariableInfo(varName, filteredRowCount, isFiltered)
    arguments
        varName
        filteredRowCount = [];
        isFiltered = false;
    end
    mlock; % Keep persistent variables until MATLAB exits
    persistent FilteredIDMap;
    if isempty(FilteredIDMap)
        FilteredIDMap = dictionary(string.empty, []);
    end
    if nargin == 3
        if isFiltered
            FilteredIDMap(varName) = filteredRowCount;
        else
            FilteredIDMap(varName) = [];
        end
    end
    if isKey(FilteredIDMap, varName)
        isFiltered = true;
        filteredRowCount = FilteredIDMap(varName);
    end
end
