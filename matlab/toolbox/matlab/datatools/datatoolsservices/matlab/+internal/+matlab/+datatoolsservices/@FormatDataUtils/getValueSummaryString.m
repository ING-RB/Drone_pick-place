% Returns the value summary string

% Copyright 2015-2023 The MathWorks, Inc.

function valuesummary = getValueSummaryString(currentVal, underlyingClass)
    import internal.matlab.datatoolsservices.FormatDataUtils;
    underlyingClass = convertStringsToChars(underlyingClass);
    % Current val could be ND array, concatenate size with times symbol
    szVal = strjoin(string(size(currentVal)), FormatDataUtils.TIMES_SYMBOL);
    if isempty(underlyingClass)
        valuesummary = strtrim([char(szVal) ' ' char(FormatDataUtils.getClassString(currentVal))]);
    else
        valuesummary = strtrim([char(szVal) ' ' char(FormatDataUtils.getClassString(currentVal)) ' ' underlyingClass]);
    end
end
