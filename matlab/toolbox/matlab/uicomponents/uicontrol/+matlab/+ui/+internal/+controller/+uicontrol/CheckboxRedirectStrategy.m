classdef CheckboxRedirectStrategy < matlab.ui.internal.controller.uicontrol.UicontrolRedirectStrategy
    %

    % Copyright 2019-2020 The MathWorks, Inc.

    properties (Access = private)
        UicontrolModel
    end

    methods
        function handleCallbackFired(obj, src, event)
            newEvent = obj.translateEvent(src, event);
            notify(obj, 'CallbackFired', newEvent);
            executeCallback(obj, src, event);
        end

        function shouldChange = isNewUIComponentNeeded(obj, uicontrolModel, propName, uicomponent)
            shouldChange = isNewUIComponentNeeded@matlab.ui.internal.controller.uicontrol.UicontrolRedirectStrategy(obj, uicontrolModel, propName, uicomponent);

            % If CData is not empty, then the component needs to be
            % recreated as an Image component.
            shouldChange = shouldChange || ~isempty(uicontrolModel.CData);
        end
    end

    methods (Access = protected)
        function component = postCreateUIComponent(obj, component, uicontrolModel)
            obj.UicontrolModel = uicontrolModel;
            component.ValueChangedFcn = @obj.handleCallbackFired;
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