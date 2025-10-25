classdef EditFieldRedirectStrategy < matlab.ui.internal.controller.uicontrol.UicontrolRedirectStrategy
    %
    
    % Copyright 2019 The MathWorks, Inc.
    
    methods
        function handleCallbackFired(obj, src, event)
            newEvent = obj.translateEvent(src, event);
            notify(obj, 'CallbackFired', newEvent);
            executeCallback(obj, src, event);
        end
        
        function newUIComponentNeeded = isNewUIComponentNeeded(obj, uicontrolModel, propName, backingComponent)
            newUIComponentNeeded = isNewUIComponentNeeded@matlab.ui.internal.controller.uicontrol.UicontrolRedirectStrategy( ...
                obj, uicontrolModel, propName, backingComponent);
            
            if newUIComponentNeeded
                return;
            end

            % If the Max or Min is changing, we might need to flip to or from multiline.  This involves
            % a change in the backing component.  Determine if we should be multiline, and if we are
            % currently multiline.  Change to or from multiline if necessary.
            isMaxOrMinChanging = any(startsWith(propName, {'Min', 'Max'}));

            if isMaxOrMinChanging
                shouldBeMultiline = uicontrolModel.Max - uicontrolModel.Min > 1;
                isMultiline = isa(backingComponent, 'matlab.ui.control.TextArea');
                newUIComponentNeeded = xor(isMultiline, shouldBeMultiline);
            else
                newUIComponentNeeded = false;
            end
        end
    end
    
    methods (Access = protected)
        function component = postCreateUIComponent(obj, component, ~)
            component.ValueChangedFcn = @obj.handleCallbackFired;
        end
    end
    
    methods (Access = private)
        function newEvent = translateEvent(~, ~, event)
            newEvent = matlab.ui.internal.controller.uicontrol.UicontrolCallbackEventData(event, 'String', event.Value);
        end
    end
end