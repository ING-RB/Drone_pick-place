classdef (Hidden) ClickableComponentController < ...
        appdesservices.internal.interfaces.controller.AbstractControllerMixin
    
    % ClickableComponentController This is controller class that supports
    % Clicked events
    
    % Copyright 2021-2023 The MathWorks, Inc.
    
    methods(Abstract, Access = protected)
        infoObject = getComponentInteractionInformation(obj, event, info)
    end
    methods(Access = 'protected')
          
        function handleEvent(obj, src, event)
            
            if strcmp("Clicked", event.Data.Name)
                % Create event data
                info = struct();
                info.LocationOffset = event.Data.locationOffset;
                info.Source = obj.Model;

                infoObject = obj.getComponentInteractionInformation(event, info);
                eventData = matlab.ui.eventdata.ClickedData(infoObject);

                % Emit 'Clicked' which in turn will trigger the user callback
                obj.handleUserInteraction('Clicked', event.Data, {'Clicked', eventData}); 
            end
            
        end
    end
end

