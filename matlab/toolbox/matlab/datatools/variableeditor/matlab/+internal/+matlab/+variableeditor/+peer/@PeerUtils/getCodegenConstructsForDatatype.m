% Returns the codegen constructs for the data type

% Copyright 2014-2023 The MathWorks, Inc.

function [quotes, braces_o, braces_c] = getCodegenConstructsForDatatype(datatype)
    if strcmp(datatype, 'string')
        quotes = char(34);
        braces_o = char(91);
        braces_c = char(93);
    else
        quotes = char(39);
        braces_o = char(123);
        braces_c = char(125);
    end
end
