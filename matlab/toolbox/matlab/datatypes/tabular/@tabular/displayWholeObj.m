function displayWholeObj(obj,tblName)
% Internal helper for displaying an entire table or timetable.
% This function is for internal use only and will change in a future
% release. Do not use this function. Use disp instead.

%   Copyright 2021-2022 The MathWorks, Inc. 

    import matlab.internal.display.lineSpacingCharacter;

    % displays a full tabular object without any chance for truncation
    if nargin == 1
        tblName = inputname(1);
    else
        tblName = convertStringsToChars(tblName);
    end
    namedCall = ~isempty(tblName);

    newline = "\n"+lineSpacingCharacter;

    % If display is directly called, no varname is supplied.
    varEquals = sprintf("%s =", tblName) + newline;
    
    %Ensure consistent formatting for special cases.
    if namedCall
        fprintf(lineSpacingCharacter);
    end
    
    %Build full printed header.
    fprintf(varEquals + getDisplayHeader(obj,tblName) + newline);
    disp(obj);
end