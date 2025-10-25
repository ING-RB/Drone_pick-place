function indented = indentWithArrow(str)
% This function is undocumented.

% Copyright 2023 The MathWorks, Inc.

import matlab.automation.internal.diagnostics.indent;

indented = "-->" + extractAfter(indent(str), 3);
if ischar(str)
    indented = char(indented);
end
end
