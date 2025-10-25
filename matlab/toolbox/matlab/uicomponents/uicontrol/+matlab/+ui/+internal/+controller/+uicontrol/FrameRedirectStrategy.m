classdef FrameRedirectStrategy < matlab.ui.internal.controller.uicontrol.UicontrolRedirectStrategy ...
        & matlab.ui.internal.componentframework.services.optional.ControllerInterface
    %

    % Copyright 2019-2021 The MathWorks, Inc.

    methods
        % There is no callback associated with a frame.
        function handleCallbackFired(~, ~, ~)
            % no-op.
        end

        function updateBackingComponentView(~,~)
            % no-op.  The Panel is actually in the figure, so it can manage
            % its own properties correctly during drawnow.
        end

        function componentCreationFcn = getComponentCreationFunction(obj, uicontrolModel)
            % Pass two extra arguments to the uipanel function:
            % - The UIControl's parent to actually enable the UIControl
            % redirect.  If the Panel isn't in the figure, its controller
            % cannot be created in the same way as
            % - Internal = 'true' to keep the panel
            componentCreationFcn = @(varargin) uipanel(varargin{:}, 'Internal', true, 'Parent', uicontrolModel.Parent);
        end

        function controller = createBackingController(obj, uicontrolModel, uicomponent, parentController)
            % The Panel doesn't follow the standard MATLAB controller
            % convention - its controller creation is tightly coupled to
            % the execution of drawnow.  The 'manuallyCreateController'
            % method is a backdoor to create the controller before waiting
            % for the next drawnow.
            if isempty(uicomponent.getControllerHandle())
                % Call into C++ to create the controller.
                uicomponent.manuallyCreateController();
            end
            controller = uicomponent.getControllerHandle();
        end

        function units = getUnitsOnBackingComponent(obj, uicontrolModel, backingUIComponent)
            units = backingUIComponent.Units; 
        end
    end
    
    methods (Access = protected)
        function [oldUnits, oldFontUnits] = updateToSupportedUnits(obj, uicontrolModel)
            % Because we use Panel for Frame, we can keep the units the
            % same as Panel supports the same set of units as UIControl.
            oldUnits = uicontrolModel.Units;
            oldFontUnits = uicontrolModel.FontUnits;
        end
    end
end
