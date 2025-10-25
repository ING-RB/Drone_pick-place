classdef PointPropertyView  ...
        < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews ...
        & matlab.graphics.internal.propertyinspector.views.IconDataMixin
    % This class has the metadata information on the map.graphics.chart.primitive.Point
    % property groupings as reflected in the property inspector

    % Copyright 2022 The MathWorks, Inc.

    properties
        Marker
        MarkerFaceColor
        MarkerFaceAlpha
        MarkerEdgeColor
        MarkerEdgeAlpha
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
            % Set the three marker icon properties
            iconProps.shape = hObj.Marker;
            iconProps.edgeColor = hObj.MarkerEdgeColor;
            iconProps.faceColor = hObj.MarkerFaceColor;

            % Define the default color
            corder = get(groot, 'FactoryGeoaxesColorOrder');
            defaultBlue = corder(1,:);

            % If the color is flat, use the default color
            if strcmpi(iconProps.edgeColor,'flat')
                iconProps.edgeColor = defaultBlue;
            end
            if strcmp(iconProps.faceColor,'flat')
                iconProps.faceColor = defaultBlue;
            end
        end
    end

    methods
        function obj = PointPropertyView(hObj)
            obj@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(hObj);

            %...............................................................

            g1 = obj.createGroup(getString(message('MATLAB:propertyinspector:Markers')),'','');
            g1.addProperties('Marker','MarkerSize','MarkerEdgeColor','MarkerFaceColor');
            g1.addSubGroup('MarkerEdgeAlpha','MarkerFaceAlpha');
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
