classdef PrimitiveQuiverPropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews & matlab.graphics.internal.propertyinspector.views.IconDataMixin
    % This class has the metadata information on the matlab.graphics.chart.primitive.Quiver property
    % groupings as reflected in the property inspector

    % Copyright 2018-2023 The MathWorks, Inc.

    properties
        Alignment
        AlignVertexCenters
        Annotation
        AutoScale
        AutoScaleFactor
        BeingDeleted
        BusyAction
        ButtonDownFcn
        Children
        Clipping
        Color
        ColorMode
        CreateFcn
        DeleteFcn
        DisplayName
        HandleVisibility
        HitTest
        Interruptible
        LineStyle
        LineStyleMode
        LineWidth
        Marker
        MarkerMode
        MarkerEdgeColor
        MarkerFaceColor
        MarkerSize
        MaxHeadSize
        Parent
        PickableParts
        ScaleFactor
        Selected
        SelectionHighlight
        ShowArrowHead
        Tag
        Type
        UData
        UDataSource
        ContextMenu
        UserData
        VData
        VDataSource
        Visible
        WData
        WDataSource
        XData
        XDataMode
        XDataSource
        YData
        YDataMode
        YDataSource
        ZData
        ZDataSource
        DataTipTemplate
        SeriesIndex
    end

    methods(Static)
        function iconProps = getIconProperties(hQuiver)
            iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.arrow);
            iconProps.edgeColor = hQuiver.Color;
            iconProps.faceColor = 'none';
        end
    end

    methods
        function this = PrimitiveQuiverPropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);

            %...............................................................

            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g2.addProperties('Color','LineStyle','LineWidth','SeriesIndex');
            g2.addSubGroup('ColorMode','LineStyleMode');
            g2.Expanded = 'true';

            %...............................................................

            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Arrow')),'','');
            g3.addProperties('Alignment','ShowArrowHead','ScaleFactor');
            g3.addSubGroup('AutoScaleFactor','AutoScale','MaxHeadSize','AlignVertexCenters');
            g3.Expanded = 'true';

            %...............................................................

            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:Markers')),'','');
            g4.addProperties('Marker','MarkerSize','MarkerEdgeColor','MarkerFaceColor');
            g4.addSubGroup('MarkerMode');

            g5 = this.createGroup(getString(message('MATLAB:propertyinspector:Data')),'','');
            g5.addProperties('UData',...
                'UDataSource',...
                'VData',...
                'VDataSource',...
                'WData',...
                'WDataSource',...
                'XData',...
                'XDataMode',...
                'XDataSource',...
                'YData',...
                'YDataMode',...
                'YDataSource',...
                'ZData',...
                'ZDataSource');
            %...............................................................

            this.createLegendGroup();

            %...............................................................
            this.createCommonInspectorGroup();
        end
    end
end
