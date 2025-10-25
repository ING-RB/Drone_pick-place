function obj = globalWorkspace()
obj = matlab.lang.Workspace;
obj.m_workspace.copyVariables("global");
end
%   Copyright 2024 The MathWorks, Inc.