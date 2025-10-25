function [ output ] = str2char( input )
%STR2CHAR takes input parameter and convert it to char if it is
%   string.

%   Copyright 2016 The MathWorks, Inc.
switch class(input)
    case 'string'
        if (length(input) == 1)
            % Convert to char in case of string.
            input = char(input);
        else
            % Convert to cell array in case of string array.
            input = cellstr(input);
        end
    case 'cell'
        % Convert each element in case of cell array.
        input = cellfun(@instrument.internal.stringConversionHelpers.str2char,input,'UniformOutput',false);
    case 'struct'
        if (length(input) == 1)
            % Convert value of each field in case of structure.
            input = structfun(@instrument.internal.stringConversionHelpers.str2char,input,'UniformOutput',false);
        else
            % Convert each element in case of structure array
            input = arrayfun(@instrument.internal.stringConversionHelpers.str2char,input,'UniformOutput',false);
            input = cell2mat(input);
        end
end
output = input;
end