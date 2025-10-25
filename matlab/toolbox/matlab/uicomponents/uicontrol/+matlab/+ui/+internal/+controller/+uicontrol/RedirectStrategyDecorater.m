classdef (Abstract) RedirectStrategyDecorater < matlab.ui.internal.controller.uicontrol.RedirectStrategyInterface
    %REDIRECTSTRATEGYDECORATOR An abstract class implementing the default
    % behavior for classes that decorate redirect strategies.

    % Copyright 2021 The MathWorks, Inc.

    properties (Access = protected)
        DecoratedStrategy
    end

    properties (Dependent)
        Callback
    end

    methods
        function obj = RedirectStrategyDecorater(strategy)
            obj.DecoratedStrategy = strategy;
        end
    end

    methods
        % For all - defer to the decorated strategy for implementation.

        function listener = addlistener(obj, varargin)
            % Default behavior for addlistener should be to defer to the
            % decorated strategy.  If strategy decorators define their own
            % events, they should override this method.
            listener = obj.DecoratedStrategy.addlistener(varargin{:});
        end

        function pvPairs = translateToUIComponentProperty(obj, uicontrolModel, uicomponent, propName)
            pvPairs = obj.DecoratedStrategy.translateToUIComponentProperty(uicontrolModel, uicomponent, propName);
        end

        function uicomponent = createUIComponent(obj, uicontrolModel)
            uicomponent = obj.DecoratedStrategy.createUIComponent(uicontrolModel);
        end

        function isCallback = isCallbackProperty(obj, propertyName)
            isCallback = obj.DecoratedStrategy.isCallbackProperty(propertyName);
        end

        function associateComponentAndUIControl(obj, varargin)
            obj.DecoratedStrategy.associateComponentAndUIControl(varargin{:});
        end

        function units = getUnitsOnBackingComponent(obj, uicontrolModel, backingUIComponent)
            units = obj.DecoratedStrategy.getUnitsOnBackingComponent(uicontrolModel, backingUIComponent);
        end

        function handleCallbackFired(obj, src, event)
            obj.DecoratedStrategy.handleCallbackFired(src, event);
        end

        function creationFcn = getComponentCreationFunction(obj, uicontrolModel)
            creationFcn = obj.DecoratedStrategy.getComponentCreationFunction(uicontrolModel);
        end

        function shouldChange = isNewUIComponentNeeded(obj, uicontrolModel, propName, uicomponent)
            shouldChange = obj.DecoratedStrategy.isNewUIComponentNeeded(uicontrolModel, propName, uicomponent);
        end

        function isAllowed = isControlConfigurationAllowed(obj, uicontrolModel)
            isAllowed = obj.DecoratedStrategy.isControlConfigurationAllowed(uicontrolModel);
        end

        function updateBackingComponentView(obj, uicomponent)
            obj.DecoratedStrategy.updateBackingComponentView(uicomponent);
        end

        function controller = createBackingController(obj, uicontrolModel, uicomponent, parentController)
            controller = obj.DecoratedStrategy.createBackingController(uicontrolModel, uicomponent, parentController);
        end

        function showBackingUIComponent(obj, backingUIComponent, uicontrolModel)
            obj.DecoratedStrategy.showBackingUIComponent(backingUIComponent, uicontrolModel);
        end

        function hideBackingUIComponent(obj, backingUIComponent)
            obj.DecoratedStrategy.hideBackingUIComponent(backingUIComponent);
        end

        % Make sure the base strategy stores any exceptions
        function val = get.Callback(obj)
            val = obj.DecoratedStrategy.Callback;
        end

        function set.Callback(obj, val)
            obj.DecoratedStrategy.Callback = val;
        end
    end

    methods (Access = protected)
        function postCreateUIComponent(obj, uicomponent, uicontrolModel)
            obj.DecoratedStrategy.postCreateUIComponent(uicomponent, uicontrolModel);
        end
    end
end
