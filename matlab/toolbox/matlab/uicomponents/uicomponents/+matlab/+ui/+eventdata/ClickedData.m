classdef ClickedData < matlab.ui.eventdata.internal.AbstractEventData
    % This class is the event data class for 'Clicked' events
    
    % Copyright 2022 The MathWorks, Inc.
    
    properties(SetAccess = 'private')
        InteractionInformation;
    end
    
    methods
        function obj = ClickedData(interactionInformation)
            % The interaction information is a required input.
           
            narginchk(1,1);
            obj.InteractionInformation = interactionInformation;           
        end
    end
end

