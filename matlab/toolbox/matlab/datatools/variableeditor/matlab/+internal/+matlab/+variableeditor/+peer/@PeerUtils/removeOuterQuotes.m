% Removes the outer quotes

% Copyright 2014-2023 The MathWorks, Inc.

function newVal = removeOuterQuotes(inVal)
    newVal = inVal;
    newVal = regexprep(newVal,'^\s*''','');
    newVal = regexprep(newVal,'\s*''$','');
end
