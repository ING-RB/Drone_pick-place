classdef RadioButtonRedirectStrategy < matlab.ui.internal.controller.uicontrol.UicontrolRedirectStrategy
    %

    % Copyright 2019-2023 The MathWorks, Inc.

    properties (Access = private)
        ValueChangedListener
        UIControlModel
    end

    methods
        function handleCallbackFired(obj, src, event)

            if isa(obj.UIControlModel.Parent, 'matlab.ui.container.ButtonGroup')
                % When parented to a button group, the button group manages
                % the UIControl's Value.  We just need to trigger the
                % callback here when the UIControl becomes the selected
                % object.
                if event.isInteractive && event.Source.Value == 1
                    % Only notify once, for the button that is selected.
                    % The button group model will update the Value of the
                    % radio button selected and deselected. Therefore we
                    % don't need to send the property to update as part of
                    % the event.
                    notify(obj, 'CallbackFired', matlab.ui.internal.controller.uicontrol.UicontrolCallbackEventData(event));
                    executeCallback(obj, src, event);
                end
            else
                % Not in button group.  In this case we need to update the
                % value manually.
                if event.isInteractive
                    % Update the Value property and execute the callback
                    newEvent = obj.translateEvent(src, event);
                    notify(obj, 'CallbackFired', newEvent);
                    executeCallback(obj, src, event);
                end
            end            
        end

        function shouldChange = isNewUIComponentNeeded(obj, uicontrolModel, propName, uicomponent)
            shouldChange = isNewUIComponentNeeded@matlab.ui.internal.controller.uicontrol.UicontrolRedirectStrategy(obj, uicontrolModel, propName, uicomponent);

            % If CData is not empty, then the component needs to be
            % recreated as an Image component.
            shouldChange = shouldChange || ~isempty(uicontrolModel.CData);
        end
    end

    methods (Access = protected)
        function postCreateUIComponent(obj, component, uicontrolModel)
            obj.ValueChangedListener = event.listener(component, 'ValuePostSet', @obj.handleCallbackFired);
            obj.UIControlModel = uicontrolModel;
        end
    end

    methods (Access = private)
        function newEvent = translateEvent(obj, ~, event)
            if event.Source.Value == 1
                value = obj.UIControlModel.Max;
            else
                value = obj.UIControlModel.Min;
            end

            newEvent = matlab.ui.internal.controller.uicontrol.UicontrolCallbackEventData(event, 'Value', value);
        end
    end
end
