classdef FigurePropertyView < inspector.internal.AppDesignerPropertyView  & ...
        inspector.internal.mixin.IconMixin & ...
        inspector.internal.mixin.WindowStyleMixin & ...
        inspector.internal.mixin.PointerMixin & ...
        inspector.internal.mixin.ThemeMixin
    % This class provides the property definition and groupings for
    % UIFigure

    % Copyright 2016-2024 The MathWorks, Inc.

    properties(SetObservable = true)
        Name char {matlab.internal.validation.mustBeVector(Name)}
        Color matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        WindowState
        Resize matlab.lang.OnOffSwitchState
        AutoResizeChildren matlab.lang.OnOffSwitchState
        IntegerHandle matlab.lang.OnOffSwitchState
        NumberTitle matlab.lang.OnOffSwitchState
        Scrollable matlab.lang.OnOffSwitchState

        Colormap matlab.internal.datatype.matlab.graphics.datatype.ColorMap
        AD_ColormapString matlab.internal.datatype.matlab.graphics.datatype.ColorMap
        Alphamap matlab.internal.datatype.matlab.graphics.datatype.AlphaMap

        NextPlot matlab.internal.datatype.matlab.graphics.datatype.NextPlot

        BeingDeleted

        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end

    methods
        function obj = FigurePropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);

            % Window Apperance Group
            inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:WindowAppearanceGroup',...
                'Theme',...
                'ThemeMode', ...
                'Color',...
                'WindowStyle',...
                'WindowState'...
                );

            % Position Group
            positionGroup =  inspector.internal.CommonPropertyView.createPositionGroup(obj);

            % Add Resize 2nd to last
            positionGroup.PropertyList = [positionGroup.PropertyList(1:end-1) {'Resize'} positionGroup.PropertyList(end)];

            % Expand Position Group
            positionGroup.Expanded = true;

            % Plotting Group
            plottingGroup = inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:PlottingGroup',...
                'AD_ColormapString',...
                'Alphamap'...
                );

            % Collapse Plotting Group
            plottingGroup.Expanded = false;

            % Mouse Pointer Group
            mousePointerGroup = inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:MousePointerGroup',...
                'Pointer'...
                );

            % Collapse the Mouse Pointer Group
            mousePointerGroup.Expanded = false;

            % Interactivity Group
            interactivityGroup = inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:InteractivityGroup');

            % We add Scrollable and ContextMenu to the inspector
            interactivityGroup.PropertyList = [
                interactivityGroup.PropertyList,...
                'Scrollable',...
                'ContextMenu'];

            % Callback Execution Control Group
            callbackExecutionControlGroup = inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:CallbackExecutionControlGroup',...
                'Interruptible', ...
                'BusyAction', ...
                'BeingDeleted'...
                );

            callbackExecutionControlGroup.Expanded = false;

            % Parent/Child Group
            parentChildGroup = inspector.internal.CommonPropertyView.createParentChildGroup(obj);

            % Collapse Parent/Child Group
            parentChildGroup.Expanded = false;

            % Identifiers Group
            identifiersGroup = inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:IdentifiersGroup',...
                'Name',...
                'Icon',...
                'NumberTitle',...
                'IntegerHandle',...
                'Tag'...
                );

            % Collapse Identifiers Group
            identifiersGroup.Expanded = false;
        end
    end
end
