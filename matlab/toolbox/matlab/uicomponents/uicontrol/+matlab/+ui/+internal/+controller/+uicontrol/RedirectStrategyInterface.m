classdef (Abstract) RedirectStrategyInterface < handle
    %REDIRECTSTRATEGYINTERFACE The interface that all redirect strategies
    % and redirect strategy decorators must implement for use with the
    % UIControl Redirect API.
    % See matlab.ui.internal.controller.uicontrol.UicontrolRedirectStrategy
    % for further details on the methods defined by this interface.

    % Copyright 2021 The MathWorks, Inc.

    properties (Access = public, Abstract)
        % g2615631 for uicontrol converted component, need set callback 
        % and execute callback in Strategy in order to show live alert
        Callback
    end

    % External Interface - these functions should not be overridden
    % except in very specific cases.
    methods (Abstract)

        % Retrieve PV pairs that are equivalent to the passed property and
        % its value on the uicontrol model.  These PV pairs represent the
        % configuration of a uicomponent such that its view represents the
        % configuration of the uicontrol model.
        %
        % This function should not be overridden unless a method must be
        % called on the uicomponent model to effect the original property
        % change on the uicontrol, e.g. calling 'scroll' on a listbox when
        % ListboxTop is set.
        pvPairs = translateToUIComponentProperty(obj, uicontrolModel, uicomponent, propName)

        % Create the appropriate type of uicomponent based on the uicontrol
        % model that is passed. The uicomponent will be configured
        % correctly according to translation logic that sets properties on
        % the uicomponent based on the uicontrol model's property values.
        % When complete, this method calls postCreateComponent to allow
        % subclasses to do additional work once the uicomponent is
        % constructed and configured.
        %
        % This method should only be overridden if a fundamental change in
        % how a uicomponent is created or configured.  Any changes to which
        % properties are applied or how the properties are translated
        % should be made in the componentconversion utilities.  The only
        % current override of this method is to create no uicomponent in
        % the case of a uicontrol with style frame.
        uicomponent = createUIComponent(obj, uicontrolModel)

        % Determine if the property being set is one of the UIControl's
        % callback properties.
        isCallback = isCallbackProperty(obj, propertyName)

        % A public method to allow a UIComponent's callback to be
        % linked to a UIControl, so that interacting with the component
        % can be detected & used to update the UIControl.  Allows the
        % subclasses of this class to do what's needed to link up these
        % callbacks and anything beyond that.
        associateComponentAndUIControl(obj, varargin)

        % Retrieve the Units in which the position values are stored 
        % on the backing component. 
        % This is needed to update the uicontrol position after the
        % position has been updated on the backing component.
        units = getUnitsOnBackingComponent(obj, uicontrolModel, backingUIComponent)
    end
    % End External Interface

    % Internal Interface
    % These methods can be overridden by subclasses,
    % to customize property translation, uicomponent creation, when the
    % uicomponent is replaced with a new one, and when the uicontrol
    % should not be represented in the view.
    methods
        % Used for testing - this function should be assigned to the
        % uicomponent's primary callback. It is called from tests to verify
        % the proper events are fired when the uicomponent's callback is
        % fired.
        handleCallbackFired(obj, src, event)

        % Return the function that will be called to initialize the
        % backing UI component.  Can be overridden by subclasses to
        % customize the backing component in certain situations and provides
        % a way to decouple this class from the migration tool's logic for
        % creating components from uicontrols.
        creationFcn = getComponentCreationFunction(obj, uicontrolModel)

        % Check if a new uicomponent is needed to represent the uicontrol,
        % e.g. if the style of the uicontrol is changing from pushbutton to
        % slider, the uibutton should be deleted and replaced with a
        % slider. Can be overridden if additional logic must be written for
        % individual styles.
        shouldChange = isNewUIComponentNeeded(obj, uicontrolModel, propName, uicomponent)

        % Check if the current uicontrol configuration should be allowed to
        % exist in the view.
        isAllowed = isControlConfigurationAllowed(obj, uicontrolModel)

        % Perform an operation to push updates from the UIComponent
        % model up to its view.  This method is called when updates to
        % the UIControl would normally be pushed to the view, for
        % instance during drawnow.
        % The standard components require a call to
        % flushDirtyProperties, whereas Panel (used for frames) does
        % not need this manual step to push its properties to the view.
        updateBackingComponentView(obj, uicomponent)

        % Create the controller for the backing UI component.  This step is
        % what causes the headless components to appear in the view.
        % Returns the controller that was created.  Decorators can override
        % this method to create additional components in the view.
        controller = createBackingController(obj, uicontrolModel, uicomponent, parentController)

        % Sets the visibility of the backing UI component to match that of
        % the UIControl model.  Decorators can use this as a hook to modify
        % the visibility of their additional components.
        showBackingUIComponent(obj, backingUIComponent, uicontrolModel)

        % Sets the visibility of the backing UI component to 'off'.
        % Decorators can use this as a hook to modify the visibility of
        % their additional components.
        hideBackingUIComponent(obj, backingUIComponent)
    end

    methods (Abstract, Access = protected)
        % Called once the uicomponent is created.  Allows subclasses to do
        % additional work with the uicomponent, e.g. wiring up the
        % uicomponent's callback to the fire events from the strategy.
        % This method should not be called from outside subclasses of this
        % class.
        postCreateUIComponent(obj, uicomponent, uicontrolModel)
    end

    methods (Static)
        function publicName = convertInternalNameToPublicName(propertyName)
            if endsWith(propertyName, '_I')
                publicName = propertyName(1:end - 2);
            else
                publicName = propertyName;
            end
        end
    end
end
