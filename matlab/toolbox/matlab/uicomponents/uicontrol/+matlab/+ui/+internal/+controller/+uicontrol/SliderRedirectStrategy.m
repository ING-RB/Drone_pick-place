classdef SliderRedirectStrategy < matlab.ui.internal.controller.uicontrol.UicontrolRedirectStrategy
    %

    % Copyright 2019-2021 The MathWorks, Inc.

    methods
        function componentCreationFcn = getComponentCreationFunction(obj, uicontrolModel)
            componentCreationFcn = @matlab.ui.control.internal.ScrollbarSlider;
        end
        
        function handleCallbackFired(obj, src, event)
            newEvent = obj.translateEvent(src, event);
            notify(obj, 'CallbackFired', newEvent);
            executeCallback(obj, src, event);
        end

        function handleContinuousValueChange(obj, src, event)
            newEvent = obj.translateEvent(src, event);
            notify(obj, 'ContinuousValueChangeFired', newEvent);
            executeCallback(obj, src, event);
        end
    end

    methods (Access = protected)
        function component = postCreateUIComponent(obj, component, uicontrolModel)
            % Wire up functions to handle the interactions of slider thumb
            % released and slider thumb dragged.
            % On release, the Callback of the uicontrol should fire.  On
            % drag, the ContinuousValueChange event should fire.
            component.ValueChangedFcn = @obj.handleCallbackFired;
            component.ValueChangingFcn = @obj.handleContinuousValueChange;
        end
    end

    methods (Access = private)
        function newEvent = translateEvent(~, ~, event)
            newEvent = matlab.ui.internal.controller.uicontrol.UicontrolCallbackEventData(event, 'Value', event.Value);
        end
    end
end
