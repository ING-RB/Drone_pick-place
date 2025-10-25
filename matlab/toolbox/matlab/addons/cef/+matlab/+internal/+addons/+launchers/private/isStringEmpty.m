function val = isStringEmpty(x)
    % isStringEmpty: Function to check if a string is empty
    % isempty MATLAB function does not return true when a string is
    % assigned "" as value. This function works in the cases where a string
    % has been assigned string.empty or "" as its value
    
    %   Copyright: 2019 The MathWorks, Inc.
    val = isempty(x) || (isstring(x) && length(x) == 1 && strlength(x)==0);
end

