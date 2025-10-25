% Escapes a string for JSON

% Copyright 2014-2023 The MathWorks, Inc.

function jsonStr = escapeJSONValue(strValue)
    jsonStr = strrep(strValue,'\','\\');
    jsonStr = strrep(jsonStr,'"','\"');
    jsonStr = strrep(jsonStr,char(9),'\t');
end
