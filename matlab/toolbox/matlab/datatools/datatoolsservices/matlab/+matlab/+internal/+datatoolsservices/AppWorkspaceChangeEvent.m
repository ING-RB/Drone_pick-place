classdef AppWorkspaceChangeEvent < event.EventData
    % Event Data Class used when data changes on app workspace

    % Copyright 2020-2021 The MathWorks, Inc.
    properties
        Type
        Workspace
        Variables
    end
end
