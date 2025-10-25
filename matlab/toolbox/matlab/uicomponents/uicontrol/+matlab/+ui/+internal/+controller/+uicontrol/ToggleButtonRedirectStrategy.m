classdef ToggleButtonRedirectStrategy < matlab.ui.internal.controller.uicontrol.UicontrolRedirectStrategy
    %
    
    % Copyright 2019-2023 The MathWorks, Inc.
    
    properties (Access = private)
        ValueChangedListener
    end
    
    methods
        function handleCallbackFired(obj, src, event)
            if event.isInteractive && event.Source.Value == 1
                % Only notify once, for the button that is selected.
                % The button group model will update the Value of the
                % radio button selected and deselected. Therefore we
                % don't need to send the property to update as part of
                % the event.
                notify(obj, 'CallbackFired', matlab.ui.internal.controller.uicontrol.UicontrolCallbackEventData(event));
                executeCallback(obj, src, event);
            end            
        end
        
        function componentCreationFcn = getComponentCreationFunction(obj, uicontrolModel)
            componentCreationFcn = @(varargin) uitogglebutton(varargin{2:end});
        end
    end
    
    methods (Access = protected)
        function uicomponent = postCreateUIComponent(obj, uicomponent, uicontrolModel)
            obj.ValueChangedListener = event.listener(uicomponent, 'ValuePostSet', @obj.handleCallbackFired);
        end
    end
end