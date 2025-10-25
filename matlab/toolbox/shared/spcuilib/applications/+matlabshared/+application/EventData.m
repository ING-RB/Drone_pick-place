classdef EventData < event.EventData
    %EVENTDATA - Customizable event data
    
    %   Copyright 2020 The MathWorks, Inc.
    properties
        Data
    end
    
    methods
        function this = EventData(data)
            this.Data = data;
        end
    end
end

% [EOF]
