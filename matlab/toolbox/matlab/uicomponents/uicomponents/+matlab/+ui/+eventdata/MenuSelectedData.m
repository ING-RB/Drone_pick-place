classdef MenuSelectedData < matlab.ui.eventdata.internal.AbstractEventData
    % This class is the event data class for 'MenuSelected' events in
    % menus within context menus

    % Copyright 2023 The MathWorks, Inc.

    properties(SetAccess = 'private')
        ContextObject
        InteractionInformation;
    end

    methods
        function obj = MenuSelectedData(contextObject, interactionInformation)

            narginchk(2,2);
            obj.ContextObject = contextObject;
            obj.InteractionInformation = interactionInformation;
        end
    end
end
