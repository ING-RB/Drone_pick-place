% Escape \ and " as they do not go via peerUtils.toJSON for cellarrays and
% structarrays. Escape \n and \t to \\n and \\t respectively for String
% datatypes alone

% Copyright 2014-2023 The MathWorks, Inc.

function data = formatGetJSONforCell(rawVal, val)
    data = val;
    if internal.matlab.datatoolsservices.FormatDataUtils.checkIsString(rawVal) && isscalar(rawVal)
        data = regexprep(data,'\n','\\n');
        data = regexprep(data,'\t','\\t');
    end
end
