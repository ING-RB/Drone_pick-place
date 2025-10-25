classdef StateButtonRedirectStrategy < matlab.ui.internal.controller.uicontrol.UicontrolRedirectStrategy
    %
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties (Access = private)
        UicontrolModel
    end
    
    methods
        function handleCallbackFired(obj, src, event)
            newEvent = obj.translateEvent(src, event);
            notify(obj, 'CallbackFired', newEvent);
            executeCallback(obj, src, event);
        end
    end
    
    methods (Access = protected)
        function uicomponent = postCreateUIComponent(obj, uicomponent, uicontrolModel)
            uicomponent.ValueChangedFcn = @obj.handleCallbackFired;
            obj.UicontrolModel = uicontrolModel;
        end
    end
    
    methods (Access = private)
        function newEvent = translateEvent(obj, ~, event)
            if event.Value == 1
                value = obj.UicontrolModel.Max;
            else
                value = obj.UicontrolModel.Min;
            end
            
            newEvent = matlab.ui.internal.controller.uicontrol.UicontrolCallbackEventData(event, 'Value', value);
        end
    end
end