% This function is undocumented.

%  Copyright 2022 The MathWorks, Inc.

function strOut = indent(str, indention)
if nargin == 1
    indention = "    ";
end
strOut = sprintf('%s%s', indention, regexprep(str, "\n", "\n" + indention));
if isstring(str)
    strOut = string(strOut);
end
end
