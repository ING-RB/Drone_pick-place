classdef LimitsEventData < event.EventData
    %

    %   Copyright 2018 The MathWorks, Inc.
    
    properties (SetAccess = private)
        StartingXLimits
        StartingYLimits
    end
    
    methods
        function eventData = LimitsEventData(xLimits, yLimits)
            eventData.StartingXLimits = xLimits;
            eventData.StartingYLimits = yLimits;
        end
    end
end
