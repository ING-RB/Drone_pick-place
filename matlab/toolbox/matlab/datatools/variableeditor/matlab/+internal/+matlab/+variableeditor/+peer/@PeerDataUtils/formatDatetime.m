% Formats a datatime

% Copyright 2017-2023 The MathWorks, Inc.

function vals = formatDatetime(strColumnData)
    vals = internal.matlab.datatoolsservices.FormatDataUtils.replaceNewLineWithWhiteSpace(strColumnData);
end
