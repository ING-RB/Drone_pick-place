classdef PopupMenuRedirectStrategy < matlab.ui.internal.controller.uicontrol.UicontrolRedirectStrategy
    %

    % Copyright 2019-2024 The MathWorks, Inc.

    methods
        function handleCallbackFired(obj, src, event)
            % If there is no clicked item, do not fire the callback.  The
            % Clicked event fires when the dropdown is opened which is not
            % the case for Java UIControl.
            if isempty(event.InteractionInformation.Item)
                return;
            end

            newEvent = obj.translateEvent(src, event);
            notify(obj, 'CallbackFired', newEvent);
            executeCallback(obj, src, event);
        end
    end

    methods (Access = protected)
        function component = postCreateUIComponent(obj, component, ~)
            % ClickedFcn behaves almost exactly like UIControl Callback for
            % UIDropDown.  It can be used in place of ValueChangedFcn.
            % For Dropdown, clicking on an item always implies that the
            % value will be set to exactly that item.
            component.ClickedFcn = @obj.handleCallbackFired;
            % ValueChangedFcn needs to be set to empty so that the callback
            % is not executed twice (g3363756).
            component.ValueChangedFcn = [];
        end
    end

    methods (Access = private)
        function newEvent = translateEvent(~, ~, event)
            uicontrolValue = event.InteractionInformation.Item;
            newEvent = matlab.ui.internal.controller.uicontrol.UicontrolCallbackEventData(event, 'Value', uicontrolValue);
        end
    end
end