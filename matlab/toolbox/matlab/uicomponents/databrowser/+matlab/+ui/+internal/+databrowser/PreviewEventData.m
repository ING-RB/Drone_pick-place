classdef PreviewEventData < matlab.ui.eventdata.internal.AbstractEventData
    % This class is the event data class for all the data browser events
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties(SetAccess = 'private')
        Index;
    end
    
    methods

        function obj = PreviewEventData(index)
            % index is used by "getData" and "getName" to locate
            % information.
            obj = obj@matlab.ui.eventdata.internal.AbstractEventData();
            obj.Index = index;
        end
        
    end
    
end

