classdef ButtonGroupPropertiesConverter < handle & matlab.mixin.SetGet ...
        & matlab.mixin.CustomDisplay ...
        & appdesigner.appmigration.internal.ErrorOverrideMixin
    %BUTTONGROUPPROPERTIESCONVERTER A converter that has the same
    %   properties and acceptable values as button group but enables
    %   the button group to work with objects created from
    %   convertToGUIDECallbackArguments.
    %
    %   See also CONVERTTOGUIDECALLBACKARGUMENTS

    % Copyright 2019-2024 The MathWorks, Inc.

    % Properties existing on ButtonGroup
    properties (Dependent)
        BackgroundColor
        BorderType
        BorderWidth
        BusyAction
        ButtonDownFcn
        Children
        Clipping
        ContextMenu
        CreateFcn
        DeleteFcn
        FontAngle
        FontName
        FontSize
        FontUnits
        FontWeight
        ForegroundColor
        HandleVisibility
        HighlightColor
        InnerPosition
        Interruptible
        Layout
        OuterPosition
        Parent
        Position
        Scrollable
        SelectedObject
        SelectionChangedFcn
        ShadowColor
        SizeChangedFcn
        Tag
        Title
        TitlePosition
        Tooltip
        Units
        UserData
        Visible
    end

    properties (Dependent, Hidden)
        UIContextMenu
    end

    % Read-only properties
    properties (Dependent, SetAccess = immutable)
        BeingDeleted
        Buttons
        Type
    end

    properties (Access = private)
        % The ButtonGroup synchronized to this adapter
        ButtonGroup
    end

    methods

        function obj = ButtonGroupPropertiesConverter(buttonGroup)
            % Store the ButtonGroup that's synchronized with this adapter
            obj.ButtonGroup = buttonGroup;

            % Tag the button group with a property to keep the association
            % with its adapter.
            codeAdapterProp = addprop(buttonGroup, 'CodeAdapter');
            codeAdapterProp.Transient = true;
            codeAdapterProp.Hidden = true;
            buttonGroup.CodeAdapter = obj;
        end

    end

    methods (Sealed, Hidden, Access = protected)
        % Methods for matlab.mixin.CustomDisplay
        function groups = getPropertyGroups(obj)
            % Mimic the properties shown by default for UIControl.
            names = {...
                'Title'...
                'BackgroundColor'...
                'SelectedObject'...
                'SelectionChangedFcn'...
                'Position'...
                'Units'...
                };
            groups = matlab.mixin.util.PropertyGroup(names);
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

    % Getter & setter for SelectedObject - only special case.
    methods
        function value = get.SelectedObject(obj)
            % When retrieving the SelectedObject, return an object that's a
            % UIControlPropertiesConverter if possible.
            value = obj.ButtonGroup.SelectedObject;
            if isprop(value, 'CodeAdapter')
                value = value.CodeAdapter;
            end
        end

        function set.SelectedObject(obj, value)
            % When setting the SelectedObject, allow UIControlPropertiesConverter
            % objects to be used in place of UI components.
            try
                if isa(value, 'appdesigner.appmigration.UIControlPropertiesConverter')
                    value = value.UIComponent;
                end

                obj.ButtonGroup.SelectedObject = value;
            catch ME
                throwAsCaller(ME);
            end
        end
    end

    % Other setters & getters.  These simply redirect to the ButtonGroup.
    methods
        function set.BackgroundColor(obj, value)
            try
                obj.ButtonGroup.BackgroundColor = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.BorderType(obj, value)
            try
                obj.ButtonGroup.BorderType = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.BorderWidth(obj, value)
            try
                obj.ButtonGroup.BorderWidth = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.BusyAction(obj, value)
            try
                obj.ButtonGroup.BusyAction = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.ButtonDownFcn(obj, value)
            try
                obj.ButtonGroup.ButtonDownFcn = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.Buttons(obj, value)
            try
                obj.ButtonGroup.Buttons = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.Children(obj, value)
            try
                obj.ButtonGroup.Children = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.Clipping(obj, value)
            try
                obj.ButtonGroup.Clipping = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.ContextMenu(obj, value)
            try
                obj.ButtonGroup.ContextMenu = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.CreateFcn(obj, value)
            try
                obj.ButtonGroup.CreateFcn = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.DeleteFcn(obj, value)
            try
                obj.ButtonGroup.DeleteFcn = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.FontAngle(obj, value)
            try
                obj.ButtonGroup.FontAngle = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.FontName(obj, value)
            try
                obj.ButtonGroup.FontName = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.FontSize(obj, value)
            try
                obj.ButtonGroup.FontSize = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.FontUnits(obj, value)
            try
                obj.ButtonGroup.FontUnits = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.FontWeight(obj, value)
            try
                obj.ButtonGroup.FontWeight = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.ForegroundColor(obj, value)
            try
                obj.ButtonGroup.ForegroundColor = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.HandleVisibility(obj, value)
            try
                obj.ButtonGroup.HandleVisibility = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.HighlightColor(obj, value)
            try
                obj.ButtonGroup.HighlightColor = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.InnerPosition(obj, value)
            try
                obj.ButtonGroup.InnerPosition = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.Interruptible(obj, value)
            try
                obj.ButtonGroup.Interruptible = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.Layout(obj, value)
            try
                obj.ButtonGroup.Layout = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.OuterPosition(obj, value)
            try
                obj.ButtonGroup.OuterPosition = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.Parent(obj, value)
            try
                obj.ButtonGroup.Parent = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.Position(obj, value)
            try
                obj.ButtonGroup.Position = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.Scrollable(obj, value)
            try
                obj.ButtonGroup.Scrollable = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.SelectionChangedFcn(obj, value)
            try
                obj.ButtonGroup.SelectionChangedFcn = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.ShadowColor(obj, value)
            try
                obj.ButtonGroup.ShadowColor = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.SizeChangedFcn(obj, value)
            try
                obj.ButtonGroup.SizeChangedFcn = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.Tag(obj, value)
            try
                obj.ButtonGroup.Tag = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.Title(obj, value)
            try
                obj.ButtonGroup.Title = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.TitlePosition(obj, value)
            try
                obj.ButtonGroup.TitlePosition = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.Tooltip(obj, value)
            try
                obj.ButtonGroup.Tooltip = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.UIContextMenu(obj, value)
            try
                obj.ButtonGroup.ContextMenu = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.Units(obj, value)
            try
                obj.ButtonGroup.Units = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.UserData(obj, value)
            try
                obj.ButtonGroup.UserData = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function set.Visible(obj, value)
            try
                obj.ButtonGroup.Visible = value;
            catch ME
                throwAsCaller(ME);
            end
        end

        function value = get.BackgroundColor(obj)
            value = obj.ButtonGroup.BackgroundColor;
        end

        function value = get.BeingDeleted(obj)
            value = obj.ButtonGroup.BeingDeleted;
        end

        function value = get.BorderType(obj)
            value = obj.ButtonGroup.BorderType;
        end

        function value = get.BorderWidth(obj)
            value = obj.ButtonGroup.BorderWidth;
        end

        function value = get.BusyAction(obj)
            value = obj.ButtonGroup.BusyAction;
        end

        function value = get.ButtonDownFcn(obj)
            value = obj.ButtonGroup.ButtonDownFcn;
        end

        function value = get.Buttons(obj)
            value = obj.ButtonGroup.Buttons;
        end

        function value = get.Children(obj)
            value = obj.ButtonGroup.Children;
        end

        function value = get.Clipping(obj)
            value = obj.ButtonGroup.Clipping;
        end

        function value = get.ContextMenu(obj)
            value = obj.ButtonGroup.ContextMenu;
        end

        function value = get.CreateFcn(obj)
            value = obj.ButtonGroup.CreateFcn;
        end

        function value = get.DeleteFcn(obj)
            value = obj.ButtonGroup.DeleteFcn;
        end

        function value = get.FontAngle(obj)
            value = obj.ButtonGroup.FontAngle;
        end

        function value = get.FontName(obj)
            value = obj.ButtonGroup.FontName;
        end

        function value = get.FontSize(obj)
            value = obj.ButtonGroup.FontSize;
        end

        function value = get.FontUnits(obj)
            value = obj.ButtonGroup.FontUnits;
        end

        function value = get.FontWeight(obj)
            value = obj.ButtonGroup.FontWeight;
        end

        function value = get.ForegroundColor(obj)
            value = obj.ButtonGroup.ForegroundColor;
        end

        function value = get.HandleVisibility(obj)
            value = obj.ButtonGroup.HandleVisibility;
        end

        function value = get.HighlightColor(obj)
            value = obj.ButtonGroup.HighlightColor;
        end

        function value = get.InnerPosition(obj)
            value = obj.ButtonGroup.InnerPosition;
        end

        function value = get.Interruptible(obj)
            value = obj.ButtonGroup.Interruptible;
        end

        function value = get.Layout(obj)
            value = obj.ButtonGroup.Layout;
        end

        function value = get.OuterPosition(obj)
            value = obj.ButtonGroup.OuterPosition;
        end

        function value = get.Parent(obj)
            value = obj.ButtonGroup.Parent;
        end

        function value = get.Position(obj)
            value = obj.ButtonGroup.Position;
        end

        function value = get.Scrollable(obj)
            value = obj.ButtonGroup.Scrollable;
        end

        function value = get.SelectionChangedFcn(obj)
            value = obj.ButtonGroup.SelectionChangedFcn;
        end

        function value = get.ShadowColor(obj)
            value = obj.ButtonGroup.ShadowColor;
        end

        function value = get.SizeChangedFcn(obj)
            value = obj.ButtonGroup.SizeChangedFcn;
        end

        function value = get.Tag(obj)
            value = obj.ButtonGroup.Tag;
        end

        function value = get.Title(obj)
            value = obj.ButtonGroup.Title;
        end

        function value = get.TitlePosition(obj)
            value = obj.ButtonGroup.TitlePosition;
        end

        function value = get.Tooltip(obj)
            value = obj.ButtonGroup.Tooltip;
        end

        function value = get.Type(obj)
            value = obj.ButtonGroup.Type;
        end

        function value = get.UIContextMenu(obj)
            value = obj.ButtonGroup.ContextMenu;
        end

        function value = get.Units(obj)
            value = obj.ButtonGroup.Units;
        end

        function value = get.UserData(obj)
            value = obj.ButtonGroup.UserData;
        end

        function value = get.Visible(obj)
            value = obj.ButtonGroup.Visible;
        end
    end
end