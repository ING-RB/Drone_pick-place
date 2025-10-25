classdef UIControlPropertiesConverter < handle & matlab.mixin.SetGet ...
        & matlab.mixin.CustomDisplay ...
        & appdesigner.appmigration.internal.ErrorOverrideMixin
    %UICONTROLPROPERTIESCONVERTER A converter that has the same properties
    %   and acceptable values as a uicontrol but applies them to the
    %   associated App Designer component.
    %
    %   See also CONVERTTOGUIDECALLBACKARGUMENTS

    % Copyright 2019-2024 The MathWorks, Inc.

    % Properties existing on UIControl
    properties (Dependent)
        BackgroundColor
        BusyAction
        ButtonDownFcn
        Callback
        CData
        Children
        CreateFcn
        ContextMenu
        DeleteFcn
        Enable
        FontAngle
        FontName
        FontSize
        FontUnits
        FontWeight
        ForegroundColor
        HandleVisibility
        HitTest
        HorizontalAlignment
        InnerPosition
        Interruptible
        KeyPressFcn
        KeyReleaseFcn
        ListboxTop
        Max
        Min
        OuterPosition
        Parent
        Position
        Selected
        SelectionHighlight
        SliderStep
        String
        Tag
        Tooltip
        TooltipString
        Units
        UserData
        Value
        Visible
    end

    % Define these UICONTROL properties as read-only.
    properties (Dependent, SetAccess=immutable)
        BeingDeleted
        Extent
        Style
    end

    properties (Dependent, Hidden)
        UIContextMenu
    end

    properties (Access = private)
        % Objects handling the translation of properties

        % Handles translating UIControl properties to UIComponent
        % properties
        UIControlPropertyTranslator

        % Listener for when properties are changed on the UIComponent
        UIComponentPropertySetListener

        % Listener for when the UIComponent's callback is fired
        UIComponentCallbackListener

        % Tracks whether or not property sets should be synchronized over
        % to the UIControl or UIComponent.  When a set is currently in
        % progress this must be false to prevent recursion.
        ShouldSynchronizePropSet = true

        % Backing storage for the UIControl properties
        UIControl
    end

    properties (Access = {?appdesigner.appmigration.ButtonGroupPropertiesConverter})
        % The UIComponent synchronized to this adapter
        UIComponent
    end

    properties (Access = {?appdesservices.internal.interfaces.model.DirtyPropertyStrategyFactory})
        % The DirtyPropertyStrategy that forwards property sets from the
        % uicomponent, through events.
        DirtyPropertyStrategy
    end

    methods
        function obj = UIControlPropertiesConverter(component)
            % Store the component that's synchronized with this adapter
            obj.UIComponent = component;

            obj.DirtyPropertyStrategy = appdesservices.internal.interfaces.model.ObservableUpdateTimeDirtyPropertyStrategy(component);

            % Set the component's DirtyPropertyStrategy to the obervable
            % DirtyPropertyStrategy so this class is notified of sets
            obj.UIComponent.setDirtyPropertyStrategy(obj.DirtyPropertyStrategy);

            % Create a backing UIControl with properties translated from
            % the UIComponent
            obj.UIControl = appdesigner.appmigration.internal.UIComponentPropertyTranslationUtils.createUIControl(component);

            % Set up a translator from UIControl properties to UIComponent
            % properties
            obj.UIControlPropertyTranslator = obj.getUIControlPropertyTranslator();

            % Wire up listeners to connect the UIComponent's callback with
            % the callback on the UIControl. This code enables user
            % interaction with the view to trigger updates to the UIControl
            %
            % If this component is a RadioButton, don't wire up the
            % callbacks.  The UIControl functionality where both the
            % SelectionChangedFcn and Callback would run for a RadioButton
            % is not desired.
            if ~isa(obj.UIComponent, 'matlab.ui.control.RadioButton')
                obj.UIControlPropertyTranslator.associateComponentAndUIControl(obj.UIComponent, obj.UIControl);
                obj.UIComponentCallbackListener = addlistener(obj.UIControlPropertyTranslator, 'CallbackFired', @obj.handleCallbackFired);
            end

            % Listen to the DirtyPropertyStrategy's events to capture any
            % property sets made on the UI component.
            obj.UIComponentPropertySetListener = listener(obj.DirtyPropertyStrategy, 'PropertiesMarkedDirty', @obj.handleUIComponentPropertiesSet);

            % Delete the adapter when the corresponding UIComponent is
            % destroyed
            addlistener(obj.UIComponent, 'ObjectBeingDestroyed', @(~,~) delete(obj));

            % Tag the component with a property to keep the association
            % with its adapter.
            codeAdapterProp = addprop(obj.UIComponent, 'CodeAdapter');
            codeAdapterProp.Transient = true;
            codeAdapterProp.Hidden = true;
            obj.UIComponent.CodeAdapter = obj;
        end

        function delete(obj)
            % Remove the UI component from the view.
            delete(obj.UIComponent);
        end
    end

    methods (Hidden)
        function data = guidata(obj, varargin)
            % Override guidata.  Because this object isn't actually a
            % graphics object in a figure hierarchy, guidata doesn't work
            % as normal on it.  By overriding, it is possible to redirect
            % these calls to work on the figure hierarchy in which the
            % uicomponent is contained.
            try
                % Make sure we call with similar values for nargin &
                % nargout to provide the proper error message.
                if nargout == 0
                    % Make sure we assign ANS
                    if nargin == 1
                        data = guidata(obj.UIComponent, varargin{:});
                    else
                        guidata(obj.UIComponent, varargin{:});
                    end
                else
                    data = guidata(obj.UIComponent, varargin{:});
                end
            catch ME
                throw(appdesigner.internal.appalert.TrimmedException(ME));
            end
        end

        function uicontrol(~)
            % Assume the user is calling this function to set focus on the
            % control.  Since this isn't a true uicontrol object, and the
            % backing uicontrol isn't parented to a figure, do nothing.
        end

        function setappdata(obj, varargin)
            try
                setappdata(obj.UIComponent, varargin{:});
            catch ME
                throw(appdesigner.internal.appalert.TrimmedException(ME));
            end
        end

        function val = getappdata(obj, varargin)
            try
                val = getappdata(obj.UIComponent, varargin{:});
            catch ME
                throw(appdesigner.internal.appalert.TrimmedException(ME));
            end
        end

        function rmappdata(obj, varargin)
            try
                rmappdata(obj.UIComponent, varargin{:});
            catch ME
                throw(appdesigner.internal.appalert.TrimmedException(ME));
            end
        end

        function tf = isappdata(obj, varargin)
            try
                tf = isappdata(obj.UIComponent, varargin{:});
            catch ME
                throw(appdesigner.internal.appalert.TrimmedException(ME));
            end
        end
    end

    methods (Sealed, Hidden, Access = protected)
        % Methods for matlab.mixin.CustomDisplay
        % By inheriting from matlab.mixin.internal.CompactDisplay, objects
        % of this class do not show their fully qualified name when
        % displayed in containers.  Only the class name itself is shown.
        function groups = getPropertyGroups(obj)
            if isscalar(obj)
                % Mimic the properties shown by default for UIControl.
                names = {...
                    'Style',...
                    'String',...
                    'BackgroundColor',...
                    'Callback',...
                    'Value',...
                    'Position',...
                    'Units'
                    };
                groups = matlab.mixin.util.PropertyGroup(names);
            else
                groups = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            end
        end

        function footer = getFooter(obj)
            % Show one of the default graphics messages for displaying all
            % properties of the object.
            footer = '';
            if isscalar(obj)
                FOOTER_INDENT_SPACES = "  ";
                variableName = inputname(1);

                % If the display environment doesn't allow hyperlinks, fall
                % back to a plaintext message to explain how to show all
                % properties.
                useHotlinks = feature('hotlinks') && ~isdeployed();
                if ~useHotlinks || isempty(variableName)
                    footer = matlab.ui.control.internal.model.PropertyHandling.createMessageWithDocLink('', 'MATLAB:graphicsDisplayText:FooterTextNoArrayName', 'GET');
                else
                    className = class(obj);

                    linkToShowAllPropertiesIfVariableExists = ...
                        "<a href=""matlab:if exist('"...
                        + variableName...
                        + "', 'var'), matlab.graphics.internal.getForDisplay('"...
                        + variableName...
                        + "', "...
                        + variableName...
                        + ", '"...
                        + className...
                        +"'), else, matlab.graphics.internal.getForDisplay('"...
                        + variableName...
                        +"'), end"">"...
                        + getString(message('MATLAB:graphicsDisplayText:AllPropertiesText'))...
                        +"</a>";

                    % 'Show ' link text
                    footer = getString(message('MATLAB:graphicsDisplayText:FooterTextWithArrayName', linkToShowAllPropertiesIfVariableExists));
                end

                footer = sprintf('%s%s\n', FOOTER_INDENT_SPACES, footer);
            end
        end

    end

    methods (Access = private)
        function setPropertyOnUIControl(obj, propertyName)
            % Translate the properties coming from the UIComponent to
            % the UIControl properties, and set them on the UIControl.
            if ~obj.ShouldSynchronizePropSet
                return;
            end

            % Perform the translation
            pvPairs = appdesigner.appmigration.internal.UIComponentPropertyTranslationUtils.translatePropertiesToUIControlProperties(obj.UIComponent, propertyName);

            % If nothing is returned, this property set cannot be expressed
            % using the UIControl properties.  E.g. the Layout property.
            if isempty(pvPairs)
                return;
            end

            % Suspend property updates to prevent the sets from being
            % forwarded again
            cleanupObj = obj.suspendPropUpdates();

            % Sometimes components actually set multiple properties
            % internally when one is set by the user.  This can cause an
            % issue where strcmp() errors when comparing arrays of
            % different length.  To avoid the error, pass each property set
            % through strcmp() individually.
            containsCallbackPropFcn = @(propName) any(strcmp(propName, {'ValueChangedFcn', 'ButtonPushedFcn'}));

            if iscell(propertyName)
                containsCallbackProp = any(cellfun(containsCallbackPropFcn, propertyName));
            else
                containsCallbackProp = containsCallbackPropFcn(propertyName);
            end

            % Keep the component's callback set to notify this class of any
            % user interaction.
            if containsCallbackProp
                obj.UIControlPropertyTranslator.associateComponentAndUIControl(obj.UIComponent, obj.UIControl);
            end

            % Perform the set
            matlab.ui.internal.componentconversion.BasePropertyConversionUtil.applyPropertyValuePairs(obj.UIControl, pvPairs);

            obj.resumePropUpdates();
        end

        function setPropertyOnUIComponent(obj, propertyName)
            % Translate the properties coming from the UIControl to the
            % UIComponent properties, and set them on the UIComponent.
            if ~obj.ShouldSynchronizePropSet
                return;
            end

            % Perform the translation
            pvPairs = obj.UIControlPropertyTranslator.translateToUIComponentProperty(obj.UIControl, obj.UIComponent, propertyName);

            % If nothing is returned, this property set is not relevant for
            % the UI component and cannot be expressed for that class.
            % E.g. the Value property on a matlab.ui.control.Button.
            if isempty(pvPairs)
                return;
            end

            % Suspend property updates to prevent the sets from being
            % forwarded again
            cleanupObj = obj.suspendPropUpdates();

            % Perform the set
            matlab.ui.internal.componentconversion.BasePropertyConversionUtil.applyPropertyValuePairs(obj.UIComponent, pvPairs);
            obj.resumePropUpdates();
        end

        function propertyTranslator = getUIControlPropertyTranslator(obj)
            % Reuse the UIControlRedirectStrategy classes for translating
            % uicontrol properties to uicomponent properties.
            %
            % Retrieve the correct redirect strategy for this uicontrol
            % style and store it in this object.
            % Nothing needs to be done to wire callbacks, as the
            % UIComponent's callback is sufficient for App Designer usage.

            factory = matlab.ui.internal.controller.uicontrol.RedirectStrategyFactoryManager.Instance.RedirectStrategyFactory;
            propertyTranslator = factory.getRedirectStrategy(obj.UIControl);
        end

        function handleUIComponentPropertiesSet(obj, src, event)
            % Handle the property set event coming from the UIComponent:
            % Properties have been set on the UI component.  Synchronize
            % them to the UIControl.
            propertyNames = event.PropertyNames;
            obj.setPropertyOnUIControl(propertyNames);
        end

        function updateResumer = suspendPropUpdates(obj)
            % Returns an onCleanup object that calls resumePropUpdates.  Calling this method
            % blocks the setting of properties on the backing component when properties are
            % set on the uicontrol model.
            updateResumer = onCleanup(@() obj.resumePropUpdates());
            obj.ShouldSynchronizePropSet = false;
        end

        function resumePropUpdates(obj)
            % Calling this method resumes the setting of properties on the backing component
            % when properties are set on the uicontrol model.
            if isempty(obj) || ~isvalid(obj)
                return;
            end
            obj.ShouldSynchronizePropSet = true;
        end

        function handleCallbackFired(obj, ~, event)
            % Handle the CallbackFired event coming from the RedirectStrategy.  This event
            % This event signifies that we should run the uicontrol's callback and update any properties
            % that were modified by the user interaction.
            narginchk(2, 3);

            % Prevent callback from triggering property set code - since this comes from the backing component,
            % its model should already be up-to-date so we don't want to try to update it again.
            onCleanupObj = obj.suspendPropUpdates();

            if event.HasData
                % If the event is sending a property update, then decode the property and set
                % it on the uicontrol model.
                propertyName = event.PropertyName;
                obj.UIControl.(propertyName) = event.PropertyValue;
            end

            % Resume property updates so that the uicontrol's callback can update the backing
            % component if the callback changes any properties on the uicontrol model.
            obj.resumePropUpdates();
            % set callback function so it can be executed after notify
            % g2615631 do not execute callback here inside notify, MCOS would convert exception as warning.
            % this cause app designer not show it as live alert because exception already converted to warning.
            obj.setCallback();
        end

        function setCallback(obj)
            callback = obj.UIControl.Callback;
            if isempty(callback)
                return;
            end

            if isa(callback, 'function_handle')
                % Unify code path for cells and function_handles.
                callback = {callback};
            end
            obj.UIControlPropertyTranslator.Callback = callback;
        end
    end

    % Getters & setters for UIControl API.  They redirect to the backing
    % control in almost all cases.  Setters usually call the generic
    % setPropertyOnUIComponent method to trigger a redirect onto the uicomponent.

    % Getters - special cases.
    methods

        function value = get.BeingDeleted(obj)
            value = obj.UIComponent.BeingDeleted;
        end

        function value = get.ContextMenu(obj)
            value = obj.UIComponent.ContextMenu;
        end

        function value = get.Parent(obj)
            value = obj.UIComponent.Parent;
        end

        function value = get.UIContextMenu(obj)
            value = obj.UIComponent.UIContextMenu;
        end
    end

    % Setters - special cases.
    methods

        function set.Callback(obj, value)
            try
                obj.UIControl.Callback = value;
            catch ME
                throwAsCaller(ME);
            end
            % Do not translate the Callback property onto the component as
            % the component's callback is used internally.
        end

        function set.ContextMenu(obj, value)
            % Don't set on the UIControl as the two will not be in the same
            % figure hierarchy.
            try
                obj.UIComponent.ContextMenu = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.Parent(obj, value)
            % Don't change the UIControl's parent, it must remain headless.
            obj.UIComponent.Parent = value;
        end

        function set.UIContextMenu(obj, value)
            % Don't set on the UIControl as the two will not be in the same
            % figure hierarchy.
            try
                obj.UIComponent.ContextMenu = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.Units(obj, value)
            try
                obj.UIControl.Units = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('Units');
        end
    end

    % Getters - simple retrieval from the UIControl.
    methods

        function value = get.BackgroundColor(obj)
            value = obj.UIControl.BackgroundColor;
        end
        function value = get.BusyAction(obj)
            value = obj.UIControl.BusyAction;
        end
        function value = get.ButtonDownFcn(obj)
            value = obj.UIControl.ButtonDownFcn;
        end
        function value = get.Callback(obj)
            value = obj.UIControl.Callback;
        end
        function value = get.CData(obj)
            value = obj.UIControl.CData;
        end
        function value = get.Children(obj)
            value = obj.UIControl.Children;
        end
        function value = get.CreateFcn(obj)
            value = obj.UIControl.CreateFcn;
        end
        function value = get.DeleteFcn(obj)
            value = obj.UIControl.DeleteFcn;
        end
        function value = get.Enable(obj)
            value = obj.UIControl.Enable;
        end
        function value = get.Extent(obj)
            value = obj.UIControl.Extent;
        end
        function value = get.FontAngle(obj)
            value = obj.UIControl.FontAngle;
        end
        function value = get.FontName(obj)
            value = obj.UIControl.FontName;
        end
        function value = get.FontSize(obj)
            value = obj.UIControl.FontSize;
        end
        function value = get.FontUnits(obj)
            value = obj.UIControl.FontUnits;
        end
        function value = get.FontWeight(obj)
            value = obj.UIControl.FontWeight;
        end
        function value = get.ForegroundColor(obj)
            value = obj.UIControl.ForegroundColor;
        end
        function value = get.HandleVisibility(obj)
            value = obj.UIControl.HandleVisibility;
        end
        function value = get.HitTest(obj)
            value = obj.UIControl.HitTest;
        end
        function value = get.HorizontalAlignment(obj)
            value = obj.UIControl.HorizontalAlignment;
        end
        function value = get.InnerPosition(obj)
            value = obj.UIControl.InnerPosition;
        end
        function value = get.Interruptible(obj)
            value = obj.UIControl.Interruptible;
        end
        function value = get.KeyPressFcn(obj)
            value = obj.UIControl.KeyPressFcn;
        end
        function value = get.KeyReleaseFcn(obj)
            value = obj.UIControl.KeyReleaseFcn;
        end
        function value = get.ListboxTop(obj)
            value = obj.UIControl.ListboxTop;
        end
        function value = get.Max(obj)
            value = obj.UIControl.Max;
        end
        function value = get.Min(obj)
            value = obj.UIControl.Min;
        end
        function value = get.OuterPosition(obj)
            value = obj.UIControl.OuterPosition;
        end
        function value = get.Position(obj)
            value = obj.UIControl.Position;
        end
        function value = get.Selected(obj)
            value = obj.UIControl.Selected;
        end
        function value = get.SelectionHighlight(obj)
            value = obj.UIControl.SelectionHighlight;
        end
        function value = get.SliderStep(obj)
            value = obj.UIControl.SliderStep;
        end
        function value = get.String(obj)
            value = obj.UIControl.String;
        end
        function value = get.Style(obj)
            value = obj.UIControl.Style;
        end
        function value = get.Tag(obj)
            value = obj.UIControl.Tag;
        end
        function value = get.Tooltip(obj)
            value = obj.UIControl.Tooltip;
        end
        function value = get.TooltipString(obj)
            value = obj.UIControl.TooltipString;
        end
        function value = get.Units(obj)
            value = obj.UIControl.Units;
        end
        function value = get.UserData(obj)
            value = obj.UIControl.UserData;
        end
        function value = get.Value(obj)
            value = obj.UIControl.Value;
        end
        function value = get.Visible(obj)
            value = obj.UIControl.Visible;
        end
    end

    % Setters - set on the UIControl, then forward to the UIComponent.
    methods
        % Wrap property set code in try/catch to prevent exposing the
        % internal stack to customers.
        function set.BackgroundColor(obj, value)
            try
                obj.UIControl.BackgroundColor = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('BackgroundColor');
        end
        function set.BusyAction(obj, value)
            try
                obj.UIControl.BusyAction = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('BusyAction');
        end
        function set.ButtonDownFcn(obj, value)
            try
                obj.UIControl.ButtonDownFcn = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('ButtonDownFcn');
        end
        function set.CData(obj, value)
            try
                obj.UIControl.CData = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('CData');
        end
        function set.Children(obj, value)
            try
                obj.UIControl.Children = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('Children');
        end
        function set.CreateFcn(obj, value)
            try
                obj.UIControl.CreateFcn = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('CreateFcn');
        end
        function set.DeleteFcn(obj, value)
            try
                obj.UIControl.DeleteFcn = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('DeleteFcn');
        end
        function set.Enable(obj, value)
            try
                obj.UIControl.Enable = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('Enable');
        end
        function set.FontAngle(obj, value)
            try
                obj.UIControl.FontAngle = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('FontAngle');
        end
        function set.FontName(obj, value)
            try
                obj.UIControl.FontName = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('FontName');
        end
        function set.FontSize(obj, value)
            try
                obj.UIControl.FontSize = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('FontSize');
        end
        function set.FontUnits(obj, value)
            try
                obj.UIControl.FontUnits = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('FontUnits');
        end
        function set.FontWeight(obj, value)
            try
                obj.UIControl.FontWeight = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('FontWeight');
        end
        function set.ForegroundColor(obj, value)
            try
                obj.UIControl.ForegroundColor = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('ForegroundColor');
        end
        function set.HandleVisibility(obj, value)
            try
                obj.UIControl.HandleVisibility = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('HandleVisibility');
        end
        function set.HitTest(obj, value)
            try
                obj.UIControl.HitTest = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('HitTest');
        end
        function set.HorizontalAlignment(obj, value)
            try
                obj.UIControl.HorizontalAlignment = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('HorizontalAlignment');
        end
        function set.InnerPosition(obj, value)
            try
                obj.UIControl.InnerPosition = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('InnerPosition');
        end
        function set.Interruptible(obj, value)
            try
                obj.UIControl.Interruptible = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('Interruptible');
        end
        function set.KeyPressFcn(obj, value)
            try
                obj.UIControl.KeyPressFcn = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('KeyPressFcn');
        end
        function set.KeyReleaseFcn(obj, value)
            try
                obj.UIControl.KeyReleaseFcn = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('KeyReleaseFcn');
        end
        function set.ListboxTop(obj, value)
            try
                obj.UIControl.ListboxTop = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('ListboxTop');
        end
        function set.Max(obj, value)
            try
                obj.UIControl.Max = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('Max');
        end
        function set.Min(obj, value)
            try
                obj.UIControl.Min = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('Min');
        end
        function set.OuterPosition(obj, value)
            try
                obj.UIControl.OuterPosition = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('OuterPosition');
        end
        function set.Position(obj, value)
            try
                obj.UIControl.Position = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('Position');
        end
        function set.Selected(obj, value)
            try
                obj.UIControl.Selected = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('Selected');
        end
        function set.SelectionHighlight(obj, value)
            try
                obj.UIControl.SelectionHighlight = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('SelectionHighlight');
        end
        function set.SliderStep(obj, value)
            try
                obj.UIControl.SliderStep = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('SliderStep');
        end
        function set.String(obj, value)
            try
                obj.UIControl.String = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('String');
        end
        function set.Tag(obj, value)
            try
                obj.UIControl.Tag = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('Tag');
        end
        function set.Tooltip(obj, value)
            try
                obj.UIControl.Tooltip = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('Tooltip');
        end
        function set.TooltipString(obj, value)
            try
                obj.UIControl.TooltipString = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('TooltipString');
        end
        function set.UserData(obj, value)
            try
                obj.UIControl.UserData = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('UserData');
        end
        function set.Value(obj, value)
            try
                obj.UIControl.Value = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('Value');
        end
        function set.Visible(obj, value)
            try
                obj.UIControl.Visible = value;
            catch ME
                throwAsCaller(ME);
            end
            obj.setPropertyOnUIComponent('Visible');
        end
    end
end