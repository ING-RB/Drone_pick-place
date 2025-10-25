classdef (Abstract) UicontrolRedirectStrategy < matlab.ui.internal.controller.uicontrol.RedirectStrategyInterface
    %UICONTROLREDIRECTSTRATEGY The base class of all redirect strategies for
    %  the uicontrol redirect API.  This class implements the base functionality
    %  of property translation and uicomponent creation for the redirect.  It
    %  also deals with morphing the parent figure when needed.

    % Copyright 2019-2022 The MathWorks, Inc.

    properties
        Callback
    end

    events
        % Used to notify listeners when the uicomponent's callback has been fired.
        CallbackFired
        % Used to notify listeners when the uicomponent's value is changing (only used by Slider).
        ContinuousValueChangeFired
    end

    % External Interface - these functions should not be overridden except in very specific cases.
    methods
        function pvPairs = translateToUIComponentProperty(obj, uicontrolModel, uicomponent, propName) %#ok<INUSL>
            % Retrieve PV pairs that are equivalent to the passed property and its value
            % on the uicontrol model.  These PV pairs represent the configuration of
            % a uicomponent such that its view represents the configuration of the uicontrol model.
            %
            % This function should not be overridden unless a method must be called on the
            % uicomponent model to effect the original property change on the uicontrol, e.g.
            % calling 'scroll' on a listbox when ListboxTop is set.
            import matlab.ui.internal.componentconversion.UicontrolConversionUtils;
            publicPropName = obj.convertInternalNameToPublicName(propName);
            pvPairs = UicontrolConversionUtils.convertProperty(uicontrolModel, publicPropName);
        end

        function uicomponent = createUIComponent(obj, uicontrolModel)
            % Create the appropriate type of uicomponent based on the uicontrol model that is passed.
            % The uicomponent will be configured correctly according to translation logic that sets
            % properties on the uicomponent based on the uicontrol model's property values.
            % When complete, this method calls postCreateComponent to allow subclasses to do additional
            % work once the uicomponent is constructed and configured.
            %
            % This method should only be overridden if a fundamental change in how a uicomponent is created
            % or configured.  Any changes to which properties are applied or how the properties are translated
            % should be made in the componentconversion utilities.  The only current override of this method
            % is to create no uicomponent in the case of a uicontrol with style frame.

            import matlab.ui.internal.componentconversion.UicontrolConversionUtils;
            import matlab.ui.internal.componentconversion.BasePropertyConversionUtil;
            import matlab.ui.internal.controller.uicontrol.UicontrolRedirectStrategy;

            % Set uicontrol's units to pixels so that the pixel value is retrieved and sent to the uicomponent.
            [oldUnits, oldFontUnits] = obj.updateToSupportedUnits(uicontrolModel);

            propertyConversionFuncs = UicontrolConversionUtils.getPropertyConversionFunctions();

            % Get the generic constructor and PV pairs to set up the appearance of the uicomponent.  None of the
            % property translation from the uicontrol model has happened yet.
            proxyConstructor = obj.getComponentCreationFunction(uicontrolModel);
            pvPairs = UicontrolConversionUtils.getPVPairsToMimicLookAndFeel(uicontrolModel);

            % Translate the uicontrol's properties to values that the uicomponent can understand.
            propertyPVPairs = BasePropertyConversionUtil.convertProperties(uicontrolModel, propertyConversionFuncs);

            % Create the uicomponent and apply the translated PV pairs.
            uicomponent = proxyConstructor(pvPairs{:}, 'Parent', [], 'Serializable', 'off');
            
            try
            uicomponent.setUIControlModel(uicontrolModel); 
            catch ME %#ok<NASGU>
            end
            
            BasePropertyConversionUtil.applyPropertyValuePairs(uicomponent, propertyPVPairs);

            % Set the uicontrol's units back to whatever they were before.
            BasePropertyConversionUtil.resetUnits(uicontrolModel, oldUnits, oldFontUnits);

            % Run custom code once the uicomponent is created.
            obj.postCreateUIComponent(uicomponent, uicontrolModel);
        end

        function isCallback = isCallbackProperty(obj, propertyName)
            % Determine if the property being set is one of the UIControl's
            % callback properties.
            import matlab.ui.internal.componentconversion.UicontrolConversionUtils;

            publicPropName = obj.convertInternalNameToPublicName(propertyName);

            % Pass propertyName as the first argument so we get a scalar back.
            isCallback = contains(publicPropName, UicontrolConversionUtils.CallbackPropertyNames, 'IgnoreCase', true);
        end

        function associateComponentAndUIControl(obj, uicomponent, uicontrolModel)
            % A public method to allow a UIComponent's callback to be
            % linked to a UIControl, so that interacting with the component
            % can be detected & used to update the UIControl.  Allows the
            % subclasses of this class to do what's needed to link up these
            % callbacks and anything beyond that.
            obj.postCreateUIComponent(uicomponent, uicontrolModel);
        end

        function units = getUnitsOnBackingComponent(obj, uicontrolModel, backingUIComponent)
            import matlab.ui.control.internal.controller.mixin.PositionableComponentController

            units = PositionableComponentController.getPositionUnits(uicontrolModel);
        end
    end

    % End External Interface

    % Internal Interface
    methods (Abstract)
        % Used for testing - this function should be assigned to the uicomponent's primary callback.
        % It is called from tests to verify the proper events are fired when the uicomponent's callback
        % is fired.
        handleCallbackFired(obj, src, event)
    end

    methods
        % These methods can be overridden by subclasses, to customize property translation, uicomponent creation,
        % when the uicomponent is replaced with a new one, and when the uicontrol should not be represented in
        % the view.

        function creationFcn = getComponentCreationFunction(obj, uicontrolModel)
            % Return the function that will be called to initialize the
            % backing UI component.  Can be overridden by subclasses to
            % customize the backing component in certain situations and provides
            % a way to decouple this class from the migration tool's logic for
            % creating components from uicontrols.
            import matlab.ui.internal.componentconversion.UicontrolConversionUtils;
            creationFcn = UicontrolConversionUtils.getComponentCreationFunction(uicontrolModel);
        end

        function shouldChange = isNewUIComponentNeeded(obj, uicontrolModel, propName, uicomponent) %#ok<INUSD,INUSL>
            % Check if a new uicomponent is needed to represent the uicontrol, e.g. if the style of the uicontrol
            % is changing from pushbutton to slider, the uibutton should be deleted and replaced with a slider.
            % Can be overridden if additional logic must be written for individual styles.
            shouldChange = strcmp(propName, 'Style') || strcmp(propName, 'Style_I');
        end

        function isAllowed = isControlConfigurationAllowed(obj, uicontrolModel) %#ok<INUSD>
            % Check if the current uicontrol configuration should be allowed to exist in the view.
            isAllowed = true;
        end

        function updateBackingComponentView(obj, uicomponent)
            % Perform an operation to push updates from the UIComponent
            % model up to its view.  This method is called when updates to
            % the UIControl would normally be pushed to the view, for
            % instance during drawnow.

            % The standard components require a call to
            % flushDirtyProperties, whereas Panel (used for frames) does
            % not need this manual step to push its properties to the view.
            uicomponent.flushDirtyProperties();
        end

        % Create the controller for the backing UI component.  This step is
        % what causes the headless components to appear in the view.
        % Returns the controller that was created.  Decorators can override
        % this method to create additional components in the view.
        function controller = createBackingController(obj, uicontrolModel, uicomponent, parentController)
            controllerFactory = matlab.ui.control.internal.controller.ComponentControllerFactoryManager.Instance.ControllerFactory;
            controller = controllerFactory.createController(uicomponent, parentController);
        end

        % Sets the visibility of the backing UI component to match that of
        % the UIControl model.  Decorators can use this as a hook to modify
        % the visibility of their additional components.
        function showBackingUIComponent(obj, backingUIComponent, uicontrolModel)
            backingUIComponent.Visible = uicontrolModel.Visible;
        end

        % Sets the visibility of the backing UI component to 'off'.
        % Decorators can use this as a hook to modify the visibility of
        % their additional components.
        function hideBackingUIComponent(obj, backingUIComponent)
            backingUIComponent.Visible = 'off';
        end
    end

    methods (Access = protected)
        function postCreateUIComponent(obj, uicomponent, uicontrolModel) %#ok<INUSD>
            % Called once the uicomponent is created.  Allows subclasses to do additional
            % work with the uicomponent, e.g. wiring up the uicomponent's callback to the
            % fire events from the strategy.  This method should not be called from outside
            % subclasses of this class.
        end
        
        function [oldUnits, oldFontUnits] = updateToSupportedUnits(obj, uicontrolModel)
            % Set the Units and FontUnits on the UIControl to
            % pixels so that the UIComponent always uses
            % pixels for these properties.  Other units are
            % not supported on thse models
            import matlab.ui.internal.componentconversion.BasePropertyConversionUtil;
            [oldUnits, oldFontUnits] = BasePropertyConversionUtil.forceUnitsToPixels(uicontrolModel);
        end

        function executeCallback(obj, src, event)
            callback = obj.Callback;
            if ~isempty(callback)
                cellFunction = iscell(callback);
                if cellFunction
                    feval(callback{1}, src, event, callback{2:end});
                else
                    evalin('base', callback);
                end
            end
        end
    end

    % End Internal Interface
end
