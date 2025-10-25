% Returns true if this is a numeric type

% Copyright 2015-2023 The MathWorks, Inc.

function numType = isNumericType(type)
    numType = any(strcmp(type,{'double','single','int8','int16','int32','int64','uint8','uint16','uint32','uint64','half'}));
end
