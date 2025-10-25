classdef (Hidden) DoubleClickableComponentController < ...
        appdesservices.internal.interfaces.controller.AbstractControllerMixin
    
    % DoubleClickableComponentController This is controller class that supports
    % DoubleClicked events
    
    % Copyright 2021-2023 The MathWorks, Inc.
    
    methods(Abstract, Access = protected)
        infoObject = getComponentInteractionInformation(obj, event, info)
    end
    methods(Access = 'protected')
          
        function handleEvent(obj, src, event)
            
            if strcmp("DoubleClicked", event.Data.Name)               

                % Create event data
                info = struct();
                info.LocationOffset = event.Data.locationOffset;
                info.Source = obj.Model;

                infoObject = obj.getComponentInteractionInformation(event, info);
                eventData = matlab.ui.eventdata.DoubleClickedData(infoObject);

                % Emit 'DoubleClicked' which in turn will trigger the user callback
                obj.handleUserInteraction('DoubleClicked', event.Data, {'DoubleClicked', eventData}); 
            end
            
        end
    end
end

