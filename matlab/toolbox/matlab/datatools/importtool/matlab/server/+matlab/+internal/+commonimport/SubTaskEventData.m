% This class is unsupported and might change or be removed without notice in a
% future version.

% This is the event data class used to notify the Import Task of changes in
% the subtask.

% Copyright 2023 The MathWorks, Inc.

classdef SubTaskEventData < event.EventData
    properties
        State
    end

    methods
        function this = SubTaskEventData(property, value)
            arguments
                % Property name to notify the ImportTask
                property (1,1) string;

                % Value of the property to notify the ImportTask
                value = [];
            end
            this.State = struct;
            this.State.(property) = value;
        end
    end
end
