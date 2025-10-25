classdef ContextMenuOpeningData < matlab.ui.eventdata.internal.AbstractEventData
    % This class is the event data class for 'ContextMenuOpening' events
    
    % Copyright 2023 The MathWorks, Inc.
    
    properties(SetAccess = 'private')
        ContextObject
        InteractionInformation;
    end
    
    methods
        function obj = ContextMenuOpeningData(contextObject, interactionInformation)
           
            narginchk(1,2);
            obj.ContextObject = contextObject;
            obj.InteractionInformation = interactionInformation;           
        end
    end
end

