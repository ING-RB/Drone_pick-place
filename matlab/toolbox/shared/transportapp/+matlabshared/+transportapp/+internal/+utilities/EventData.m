classdef EventData < event.EventData
    %EVENTDATA class is used for passing event data from the view to the
    %controllers.

    % Copyright 2021 The MathWorks, Inc.

    properties
        Data
    end

    methods
        function obj = EventData(input)
            obj.Data = input;
        end
    end
end