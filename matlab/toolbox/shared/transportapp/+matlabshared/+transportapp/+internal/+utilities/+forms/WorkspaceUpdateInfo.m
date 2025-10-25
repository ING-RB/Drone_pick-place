classdef WorkspaceUpdateInfo
    %WORKSPACEUPDATEINFO form class contains MATLAB base workspace update
    %information, like the names of the changed variables, and the type of
    %event associated with the change.

    % Copyright 2021 The MathWorks, Inc.

    properties
        ChangedVariableNames (1, :) string
        EventType (1, 1) string
    end

    methods
        function obj = WorkspaceUpdateInfo(name,eventName)
            obj.ChangedVariableNames = name;
            obj.EventType = eventName;
        end
    end
end