function executingCode = removeNonExecutingCode(code)
    %REMOVENONEXECUTINGCODE This function removes formatting and comments from
    %app code, leaving only the executing code
    
    %   Copyright 2021, MathWorks Inc.

    % remove all spaces and tab indentation
    executingCode = regexprep(code, "(?m)^[\s\t]+", "");

    % remove any line that starts with '%'
    executingCode = regexprep(executingCode, "%.*\n", "", "lineanchors", "dotexceptnewline");
end

