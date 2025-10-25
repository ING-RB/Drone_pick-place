classdef (Hidden) AccordionPanelController < matlab.ui.control.internal.controller.ComponentController
    %
    
    % Copyright 2019-2020 The MathWorks, Inc.
    
    methods(Access = 'protected')
        
        function handleEvent(obj, src, event)
            % Allow super classes to handle their events
            handleEvent@matlab.ui.control.internal.controller.ComponentController(obj, src, event);
            
            if(strcmp(event.Data.Name, 'CollapsedChanged'))
                % Handles when the user expands / collapsed the panel.
                
                % Currently, there is no corresponding callback for it.
                % Only update the model
                obj.Model.Collapsed = event.Data.Collapsed;
                
                % Trigger user callback
                eventData = matlab.ui.eventdata.CollapsedChangedData(obj.Model, event.Data.Collapsed);
                eventName = event.Data.Name; 
                obj.handleUserInteraction(eventName, event.Data, {eventName, eventData}); 
            end

            if(strcmp(event.Data.Name, 'positionChangedEvent'))
                outerValUnits = event.Data.valuesInUnits.OuterPosition;

                newPos = outerValUnits.Value;

                % Convert from (0,0) to (1,1) origin
                newPos = matlab.ui.control.internal.controller.PositionUtils.convertFromZeroToOneOrigin(newPos);

                obj.Model.setPositionFromClient(newPos);
            end
        end
    end
    
    
end
