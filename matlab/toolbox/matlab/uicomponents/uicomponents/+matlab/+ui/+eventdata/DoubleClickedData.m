classdef DoubleClickedData < matlab.ui.eventdata.internal.AbstractEventData
    % This class is the event data class for 'DoubleClicked' events
    
    % Copyright 2022 The MathWorks, Inc.
    
    properties(SetAccess = 'private')
        InteractionInformation;
    end
    
    methods
        function obj = DoubleClickedData(interactionInformation)
            % The interaction information is a required input.
           
            narginchk(1,1);
            
            obj.InteractionInformation = interactionInformation;
            
        end
    end
end

