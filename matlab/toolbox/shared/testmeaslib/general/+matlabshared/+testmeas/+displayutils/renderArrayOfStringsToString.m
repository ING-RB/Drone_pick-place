function result = renderArrayOfStringsToString(array, separator)
% RENDERARRAYOFSTRINGSTOSTRING convert cell array to string
% renderArrayOfStringsToString(CELLARRAY,SEPARATOR) takes
% vector CELLARRAY of strings and turns it into a string, with
% each item in CELLARRAY separated by SEPARATOR.

%   Copyright 2020-2024 The MathWorks, Inc.

arguments
    array string
    separator (1, 1) string =  ", "
end

if isempty(array) || isequal(array, "")
    result = "-none-";
    return
end

result = join(array, separator);
end