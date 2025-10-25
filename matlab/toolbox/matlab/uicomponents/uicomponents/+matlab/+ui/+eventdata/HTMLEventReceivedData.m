classdef HTMLEventReceivedData < matlab.ui.eventdata.internal.AbstractEventData
    % This class is the event data class for 'EventDispatched' events
    
    % Copyright 2019-2020 The MathWorks, Inc.
    
    properties(SetAccess = 'private')
        HTMLEventName;
        
        HTMLEventData;
    end
    
    methods
        function obj = HTMLEventReceivedData(name, data)
            % name and data are required, even if data is empty
            narginchk(2,2);
            
            % Call super which will take care of the additional inputs
            obj = obj@matlab.ui.eventdata.internal.AbstractEventData();
            
            obj.HTMLEventName = name;
            obj.HTMLEventData = data;
        end
    end
end
