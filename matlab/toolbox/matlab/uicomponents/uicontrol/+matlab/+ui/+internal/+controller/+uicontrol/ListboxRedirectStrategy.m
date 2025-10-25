classdef ListboxRedirectStrategy < matlab.ui.internal.controller.uicontrol.UicontrolRedirectStrategy
    %LISTBOXREDIRECTSTRATEGY
    
    % Copyright 2019-2022 The MathWorks, Inc.
    
    methods
        function pvPairs = translateToUIComponentProperty(obj, uicontrolModel, uicomponent, propName)
            % Override in the case of ListboxTop as we should scroll the uicomponent in that case.
            if startsWith(propName, 'ListboxTop')
                % If the listbox top is out of range of the items, give up.
                % The java uicontrol doesn't guarantee anything in cases like this.
                idx = uicontrolModel.(propName);
                if idx < length(uicomponent.Items) && idx > 0
                    item = uicomponent.Items{idx};
                    uicomponent.scroll(item);
                end
                
                pvPairs = {};
            else
                pvPairs = translateToUIComponentProperty@matlab.ui.internal.controller.uicontrol.UicontrolRedirectStrategy(obj, uicontrolModel, uicomponent, propName);
            end
        end
        
        function handleCallbackFired(obj, src, event)
            newEvent = obj.translateEvent(src, event);
            notify(obj, 'CallbackFired', newEvent);
            executeCallback(obj, src, event);
        end

        function handleComponentClicked(obj, src, event, uicontrolModel)
            if event.InteractionInformation.Item == uicontrolModel.Value
                newEvent = obj.translateEvent(src, event);
                notify(obj, 'CallbackFired', newEvent);
                executeCallback(obj, src, event);
            end
        end
    end
    
    methods (Access = protected)
        function component = postCreateUIComponent(obj, component, uicontrolModel)
            % Clicked event fires before ValueChanged event, which means
            % that when a click changs the backing component value, that
            % value is not yet up to date during the ClickedFcn.  To
            % mitigate this wire up the ValueChangedFcn to handle the first
            % click, and only use the ClickedFcn to detect a click on an
            % item that is already selected.
            %
            % DoubleClickedFcn is not required here as UIControl has no
            % special event or behavior on a double click - it can be
            % emulated by the ClickedFcn.
            component.ValueChangedFcn = @obj.handleCallbackFired;
            component.ClickedFcn = @(src, evt) obj.handleComponentClicked(src, evt, uicontrolModel);
        end
    end
    
    methods (Access = private)
        function newEvent = translateEvent(~, ~, event)
            % If ItemsData exists, the Value property must be an element or 
            % elements of ItemsData.  If ItemsData doesn't exist, Value must 
            % be an element of Items.  Added as part of g2510117.
            % Note: isprop is needed here to enable easy testing.
            if isprop(event.Source,'ItemsData') && ~isempty(event.Source.ItemsData)
                data = event.Source.ItemsData;
            else 
                data = event.Source.Items;
            end

            % Determines the indices of each element of the Value property in
            % the 'data' cellstr.
            % Dig into Event.Source as the Clicked event data has no info
            % about the component value.
            [~, valueArray] = ismember(event.Source.Value, data);

            % g1975084: Return the values in sorted order, as they are in the Java world.
            valueArray = sort(valueArray);

            newEvent = matlab.ui.internal.controller.uicontrol.UicontrolCallbackEventData(event, 'Value', valueArray);
        end
    end
end