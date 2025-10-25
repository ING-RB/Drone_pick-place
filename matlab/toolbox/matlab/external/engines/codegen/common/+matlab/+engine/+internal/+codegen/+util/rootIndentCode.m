function codeOut = rootIndentCode(codeIn)
    %rootIndentCode Applies the root indent to the code using a token.
    %Futher indentation (e.g. additional indendation in if-statement branch)
    %is not applied.
    
    %   Copyright 2022-2023 The MathWorks, Inc.

    % indent first line
    codeOut = "[rootIndent]" + codeIn;

    % indent subsequent lines by replacing "newline"
    codeOut = replace(codeOut, newline, newline + "[rootIndent]");

end

