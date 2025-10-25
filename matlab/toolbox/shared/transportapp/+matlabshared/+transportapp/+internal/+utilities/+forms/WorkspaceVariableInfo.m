classdef WorkspaceVariableInfo
    %WORKSPACEVARIABLEINFO contains information about the MATLAB workspace
    %variable name and the data type. This is used for passing Workspace
    %Variable parsing information from the WorkspaceHandler to other
    %sections.

    % Copyright 2021 The MathWorks, Inc.

    properties
        Name (1, 1) string
        Type (1, 1) matlabshared.transportapp.internal.utilities.forms.WorkspaceTypeEnum
    end

    methods
        function obj = WorkspaceVariableInfo(name, type)
            obj.Name = name;
            obj.Type = type;
        end
    end
end