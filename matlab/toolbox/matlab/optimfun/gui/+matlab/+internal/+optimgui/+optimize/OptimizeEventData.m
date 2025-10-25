classdef (ConstructOnLoad = true) OptimizeEventData < event.EventData
    
    % The OptimizeEventData class is a way to pass data to notified listener
    % callback functions. When notifying listeners of events, construct a new
    % instance of OptimizeEventData and pass it the data. This class is very generic.
    % If multiple pieces of data are required, a cell array or struct could be passed.
    % Listener callback functions know if they are expecting event data and how
    % to deal with it.
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties
        Data
    end
    methods
        function eventData = OptimizeEventData(data)
        eventData.Data = data;
        end
    end
end
