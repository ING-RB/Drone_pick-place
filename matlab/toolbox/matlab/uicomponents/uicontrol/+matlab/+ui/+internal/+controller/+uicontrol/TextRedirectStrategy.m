classdef TextRedirectStrategy < matlab.ui.internal.controller.uicontrol.UicontrolRedirectStrategy
    %
    
    % Copyright 2019 The MathWorks, Inc.

    methods
        function obj = TextRedirectStrategy(~)
            obj@matlab.ui.internal.controller.uicontrol.UicontrolRedirectStrategy();
        end
        
        function handleCallbackFired(obj, src, event)
            % no-op.
        end
    end
end