classdef FrameworkDisplayManager < handle
    %FRAMEWORKDISPLAYMANAGER The FrameworkDisplayManager handles the
    %construction and management of the Framework Display Window. This
    %class evaluates all of the modules passed in as initialModules and
    %attempts to place their visualizations into the display.

    %   Copyright 2016-2021 The MathWorks, Inc.

    properties(SetAccess = private, GetAccess = public)
        %WINDOW - Handle to the HwmgrWindow class that wraps the
        %AppContainer
        Window
        %CONTEXT - The context in which Hardware Manager Framework is
        %running. The context can be Hardware Manager App or Client App
        %context.
        Context
    end

    methods

        function obj = FrameworkDisplayManager(mediator, context)
            % Initialize the correct window
            
            obj.Context = context;

            if context.IsClientApp
                obj.Window = matlab.hwmgr.internal.ClientAppWindow(mediator, context);                
            else
                obj.Window = matlab.hwmgr.internal.HwmgrAppWindow(mediator);
            end
            
        end

        function delete(obj)
            delete(obj.Window);
        end

    end

    methods (Static)
        % This is needed to prevent command window from gaining focus
        % through key press. This is set to uifigure's KeyPressFcn property
        function noOpFcnForKeyPress(~,~)
        end
    end
end

