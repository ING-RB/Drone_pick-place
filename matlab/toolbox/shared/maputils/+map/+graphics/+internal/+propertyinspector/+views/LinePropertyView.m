classdef LinePropertyView  ...
        < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews ...
        & matlab.graphics.internal.propertyinspector.views.IconDataMixin
    % This class has the metadata information on the map.graphics.chart.primitive.Line
    % property groupings as reflected in the property inspector

    % Copyright 2022-2023 The MathWorks, Inc.

    properties
        Annotation
        BeingDeleted
        BusyAction
        ButtonDownFcn
        Children
        Color
        ColorData
        ColorDataMode
        ColorVariable
        ContextMenu
        CreateFcn
        DataTipTemplate
        DeleteFcn
        DisplayName
        HandleVisibility
        HitTest
        Interruptible
        LineStyle
        LineWidth
        Parent
        PickableParts
        Selected
        SelectionHighlight
        SeriesIndex
        ShapeData
        ShapeDataMode
        ShapeVariable
        SourceTable
        Tag
        Type
        UserData
        Visible
    end

    methods(Static)
        function  iconProps = getIconProperties(hObj)
            % Set the three icon properties
            iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.line);
            iconProps.edgeColor = hObj.Color;
            iconProps.faceColor = 'none';

            % If the color is 'flat', use the colormap to decide the color
            % of the icon instead. This is the same approach used by patch.
            if strcmp(hObj.Color,'flat')
                ax = ancestor(hObj,'matlab.graphics.axis.AbstractAxes');
                if strcmpi(ax.ColormapMode,'manual')
                    c = ax.Colormap;
                else
                    f = ancestor(hObj,'figure');
                    c = f.Colormap;
                end
                iconProps.edgeColor = c(length(c)/2,:);
            end
        end
    end

    methods
        function obj = LinePropertyView(hObj)
            obj@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(hObj);

            %...............................................................

            g1 = obj.createGroup(getString(message('maputils:propertyinspector:Line')),'','');
            g1.addProperties('Color','LineStyle','LineWidth');
            g1.Expanded = true;

            %...............................................................

            g2 = obj.createGroup(getString(message('maputils:propertyinspector:ColorData')),'','');
            g2.addProperties('ColorData','ColorDataMode','SeriesIndex');
            g2.Expanded = true;

            %...............................................................

            g3 = obj.createGroup(getString(message('maputils:propertyinspector:ShapeData')),'','');
            g3.addProperties('ShapeData','ShapeDataMode');

            %...............................................................

            g4 = obj.createGroup(getString(message('MATLAB:propertyinspector:TableData')),'','');
            g4.addProperties('SourceTable','ShapeVariable','ColorVariable');

            %...............................................................

            obj.createLegendGroup();

            %...............................................................

            obj.createCommonInspectorGroup();
        end
    end
end
