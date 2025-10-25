classdef PushButtonRedirectStrategy < matlab.ui.internal.controller.uicontrol.UicontrolRedirectStrategy
    %
    
    % Copyright 2019 The MathWorks, Inc.
    
    methods
        function handleCallbackFired(obj, src, event)
            % Empty event data for ButtonPushed
            notify(obj, 'CallbackFired', matlab.ui.internal.controller.uicontrol.UicontrolCallbackEventData(event));
            % If Callback is set on Strategy, execute callback here,
            % need to executecallback outside above notify
            % in order to show live alert for uicontrol converted component g2615631
            executeCallback(obj, src, event);
        end
    end
    
    methods (Access = protected)
        function postCreateUIComponent(obj, component, ~)
            component.ButtonPushedFcn = @obj.handleCallbackFired;
        end
    end
end