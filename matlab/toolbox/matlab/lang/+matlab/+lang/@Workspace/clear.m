function clear(obj,varNames)
arguments
    obj
end
arguments (Repeating)
    varNames {mustBeTextScalar}
end
obj.m_workspace.clearVariables(varNames{:});
end
%   Copyright 2024 The MathWorks, Inc.