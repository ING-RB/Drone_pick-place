function obj = baseWorkspace()
obj = matlab.lang.Workspace;
obj.m_workspace.copyVariables("base");
end
%   Copyright 2024 The MathWorks, Inc.