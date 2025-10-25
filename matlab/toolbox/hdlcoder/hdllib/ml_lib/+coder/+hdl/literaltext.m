%#codegen

%   Copyright 2023-2024 The MathWorks, Inc.
function literaltext(text)
%LITERALTEXT Summary of this function goes here
%   Detailed explanation goes here
    arguments
        text (1,:) char    
    end
    coder.columnMajor;
    if coder.target('hdl')
        coder.ceval('-preservearraydims', '__hdl_literaltext', text);
    end
end
