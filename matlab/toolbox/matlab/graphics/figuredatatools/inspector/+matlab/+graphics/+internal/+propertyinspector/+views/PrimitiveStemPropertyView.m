classdef PrimitiveStemPropertyView <  matlab.graphics.internal.propertyinspector.views.CommonPropertyViews & matlab.graphics.internal.propertyinspector.views.IconDataMixin
    % This class has the metadata information on the matlab.graphics.chart.primitive.Stem property
    % groupings as reflected in the property inspector

    % Copyright 2017-2023 The MathWorks, Inc.

    properties
        Color
        ColorMode
        LineStyle
        LineStyleMode
        LineWidth
        Marker
        MarkerMode
        MarkerSize
        MarkerEdgeColor
        MarkerFaceColor
        BaseLine
        DataTipTemplate
        BaseValue
        ShowBaseLine
        XData
        YData
        ZData
        XDataMode
        YDataMode
        ZDataMode
        XVariable
        YVariable
        ZVariable
        XDataSource
        YDataSource
        ZDataSource
        Annotation
        DisplayName
        Selected
        SelectionHighlight
        ContextMenu
        Clipping
        Visible
        ButtonDownFcn
        CreateFcn
        DeleteFcn
        BeingDeleted
        BusyAction
        HitTest
        PickableParts
        Interruptible
        Children
        HandleVisibility
        Parent
        Tag
        Type
        UserData
        SeriesIndex
        SourceTable
    end

    methods(Static)
        function iconProps = getIconProperties(hStem)
            iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.stem);
            iconProps.faceColor = 'none';
            iconProps.edgeColor = hStem.Color;
        end
    end

    methods
        function this = PrimitiveStemPropertyView(obj)
              this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);

            %...............................................................

            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g1.addProperties('Color','LineStyle','LineWidth','SeriesIndex');
            g1.addSubGroup('ColorMode','LineStyleMode');
            g1.Expanded = 'true';

            %...............................................................

            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Markers')),'','');
            g3.addProperties('Marker','MarkerSize');
            g3.addSubGroup('MarkerEdgeColor','MarkerFaceColor','MarkerMode');
            g3.Expanded = true;

            %...............................................................

            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:Baseline')),'','');
            g4.addProperties('BaseLine');
            g4.addSubGroup('ShowBaseLine','BaseValue');
            g4.Expanded = true;

            %...............................................................

            g7 = this.createGroup(getString(message('MATLAB:propertyinspector:CoordinateData')),'','');
            g7.addProperties('XData','XDataMode','XDataSource','YData','YDataMode','YDataSource','ZData','ZDataMode','ZDataSource');

            %...............................................................

            g8 = this.createGroup(getString(message('MATLAB:propertyinspector:TableData')),'','');
            g8.addProperties('SourceTable','XVariable','YVariable','ZVariable');

            %...............................................................

            this.createLegendGroup();

            %...............................................................

            this.createCommonInspectorGroup();
        end
    end
end
