function varTable = variables(obj,varNames)
arguments
    obj
end
arguments (Repeating)
    varNames {mustBeTextScalar}
end
varStruct = obj.m_workspace.variables(varNames{:});
varTable = struct2table(varStruct);
varTable.Name = string(varTable.Name);
varTable.Class = string(varTable.Class);
end
%   Copyright 2024 The MathWorks, Inc.