classdef (ConstructOnLoad) UpdateModelEventData < event.EventData
    % This class holds data for UpdateModelEvent
    
    % Copyright 2020 The MathWorks, Inc.
    properties
        UpdateType
        Metadata
    end
    
    methods
        function data = UpdateModelEventData(updateType, metadata)
            data.UpdateType = updateType;
            data.Metadata = metadata;
        end
    end
end

