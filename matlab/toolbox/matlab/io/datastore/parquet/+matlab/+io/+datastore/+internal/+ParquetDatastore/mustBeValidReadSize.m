function [readMode, readSize] = mustBeValidReadSize(readSize)
%mustBeValidReadSize   Validates the input ReadSize value.

%   Copyright 2018-2023 The MathWorks, Inc.

readSize = convertCharsToStrings(readSize);
isNumeric = isnumeric(readSize);


if isNumeric
    classes = {'numeric'};
    attrs = {'scalar', 'positive', 'integer', 'nonsparse'};
    validateattributes(readSize, classes, attrs, "parquetDatastore", "ReadSize");
    readSize = double(readSize);
    readMode = "numeric";
    return;
end

readSize = validatestring(readSize, ["rowgroup" "file"], "parquetDatastore", "ReadSize");
readSize = string(readSize);
readMode = readSize;


end
