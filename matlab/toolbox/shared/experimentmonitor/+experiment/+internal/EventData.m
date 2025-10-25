classdef(ConstructOnLoad) EventData < event.EventData
    % EventData  Event data with a generic Payload property
    %
    % The Payload property can be filled with whatever data is required for
    % a specific event, e.g. a struct with multiple fields if needed.
    
    %   Copyright 2022 The MathWorks, Inc.
    
    properties(SetAccess = private)
        % Payload  (anything)
        % Information this event carries.
        data
    end
    
    methods
        function this = EventData(data)
            this.data = data;
        end
    end
end