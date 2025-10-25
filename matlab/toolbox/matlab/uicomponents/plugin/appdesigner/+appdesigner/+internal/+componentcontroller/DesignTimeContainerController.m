classdef DesignTimeContainerController < ...
        matlab.ui.control.internal.controller.ContainerController & ...
        appdesigner.internal.componentcontroller.DesignTimeVisualComponentsController
    %DESIGNTIMECONTAINERCONTROLLER - This class contains design time logic
    %specific to Containers
    
    % Copyright 2020 The MathWorks, Inc.
    
    
    methods
        function obj = DesignTimeContainerController(component, parentController, proxyView, adapter)                       
            obj = obj@matlab.ui.control.internal.controller.ContainerController(component, parentController, proxyView);
            obj = obj@appdesigner.internal.componentcontroller.DesignTimeVisualComponentsController(component, proxyView, adapter);            
        end
        
        function populateView(obj, proxyView)
            populateView@matlab.ui.control.internal.controller.ContainerController(obj, proxyView);
 
            % Destroy the visual comopnent's runtime listeners.  We will
            % not be needing these during design time.
            delete(obj.Listeners);
            obj.Listeners = [];
            
            % Create controllers and design time listeners
            populateView@appdesigner.internal.componentcontroller.DesignTimeVisualComponentsController(obj, proxyView);
        end
    end
    
    methods (Access = 'protected')

       function handleDesignTimePropertiesChanged(obj, src, changedPropertiesStruct)
           % HANDLEDESIGNTIMEPROPERTIESCHANGED - Delegates the logic of 
           % handling the event to the runtime controllers via the
           % handlePropertiesChanged method
           handlePropertiesChanged(obj, changedPropertiesStruct);
       end
       
       function handleDesignTimeEvent(obj, src, event)
           % HANDLEDESIGNTIMEEVENT - Delegates the logic of handling the
           % event to the runtime controllers via the handleEvent method
           handleEvent(obj, src, event);
       end
    end
end

