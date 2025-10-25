classdef PolygonPropertyView  ...
        < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews ...
        & matlab.graphics.internal.propertyinspector.views.IconDataMixin
    % This class has the metadata information on the map.graphics.chart.primitive.Polygon
    % property groupings as reflected in the property inspector

    % Copyright 2022-2023 The MathWorks, Inc.

    properties
        FaceColor
        FaceAlpha
        EdgeColor
        EdgeAlpha
        ShapeData
        ColorData
        ShapeDataMode
        ColorDataMode
        ShapeVariable
        ColorVariable
        Children
        Parent
        Visible
        HandleVisibility
        SourceTable
        DisplayName
        Annotation
        Selected
        SelectionHighlight
        HitTest
        PickableParts
        SeriesIndex
        DataTipTemplate
        ButtonDownFcn
        ContextMenu
        BusyAction
        BeingDeleted
        Interruptible
        CreateFcn
        DeleteFcn
        Type
        Tag
        UserData
    end

    methods(Static)
        function  iconProps = getIconProperties(hObj)
            % Set the three icon properties
            iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.rect);
            iconProps.edgeColor = hObj.EdgeColor;
            iconProps.faceColor = hObj.FaceColor;

            % If the color is 'flat', use the colormap to decide the color
            % of the icon instead. This is the same approach used by patch.
            if strcmp(hObj.FaceColor,'flat')
                ax = ancestor(hObj,'matlab.graphics.axis.AbstractAxes');
                if strcmpi(ax.ColormapMode,'manual')
                    c = ax.Colormap;
                else
                    f = ancestor(hObj,'figure');
                    c = f.Colormap;
                end
                iconProps.faceColor = c(length(c)/2,:);
            end
        end
    end

    methods
        function obj = PolygonPropertyView(hObj)
            obj@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(hObj);

            %...............................................................

            g1 = obj.createGroup(getString(message('maputils:propertyinspector:Polygon')),'','');
            g1.addProperties('FaceColor','EdgeColor','FaceAlpha','EdgeAlpha');
            g1.addSubGroup('LineStyle','LineWidth');
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
