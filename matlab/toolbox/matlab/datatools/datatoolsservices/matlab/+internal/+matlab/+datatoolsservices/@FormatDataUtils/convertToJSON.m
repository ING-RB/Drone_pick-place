% Creates a complete json string from key value pairs or a structure

% Copyright 2015-2023 The MathWorks, Inc.

function jsonStr = convertToJSON(varargin)
    jsonStr = jsonencode(varargin);
    jsonStr = jsonStr(2:end-1);
end
