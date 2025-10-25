function obj = currentWorkspace()
obj = matlab.lang.Workspace;
obj.m_workspace.copyVariables("current");
end
%   Copyright 2024 The MathWorks, Inc.