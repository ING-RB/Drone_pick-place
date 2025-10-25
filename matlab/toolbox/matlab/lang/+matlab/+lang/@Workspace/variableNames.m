function out = variableNames(obj,varNames)
arguments
    obj
end
arguments (Repeating)
    varNames {mustBeTextScalar}
end
out = obj.m_workspace.listVariables(varNames{:});
end
%   Copyright 2024 The MathWorks, Inc.