classdef EventRecord < handle & matlab.mixin.Heterogeneous
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % EventRecord - Record of event which produced EventData instance
    
    % Copyright 2021-2023 The MathWorks, Inc.
    
    properties (SetAccess = immutable)
        EventName (1,1) string
        EventScope (1,1) matlab.buildtool.Scope
        EventLocation (1,1) string
    end
    
    methods (Abstract)
        str = getFormattedReport(record, formatter)
    end

    methods (Abstract, Static)
        record = fromEventData(eventData, eventScope, eventLocation)
    end
    
    methods (Hidden, Access = protected)
        function record = EventRecord(eventName, eventScope, eventLocation)
            record.EventName = eventName;
            record.EventScope = eventScope;
            record.EventLocation = eventLocation;
        end
    end
end

