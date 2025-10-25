classdef PrimitiveBoxChartPropertyView <  matlab.graphics.internal.propertyinspector.views.DataspaceMixin ...
        & matlab.graphics.internal.propertyinspector.views.CommonPropertyViews ...
        & matlab.graphics.internal.propertyinspector.views.IconDataMixin
    % This class has the metadata information on the
    % matlab.graphics.chart.primitive.BoxChart property
    % groupings as reflected in the property inspector

    % Copyright 2024 The MathWorks, Inc.

    properties
        % Legend:
        Annotation
        DisplayName
        % Data Display
        BoxWidth
        CapWidth
        CapWidthMode
        JitterOutliers matlab.internal.datatype.matlab.graphics.datatype.on_off
        Notch matlab.internal.datatype.matlab.graphics.datatype.on_off
        Orientation matlab.internal.datatype.matlab.graphics.datatype.HorizontalVertical
        ColorGroupWidth matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne
        ColorGroupWidthMode
        ColorGroupLayout matlab.internal.datatype.matlab.graphics.datatype.ColorGroupLayout
        % Color and styling
        BoxFaceColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor
        BoxFaceColorMode
        BoxEdgeColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor
        BoxEdgeColorMode
        BoxMedianLineColor  matlab.internal.datatype.matlab.graphics.datatype.RGBAColor
        BoxMedianLineColorMode
        WhiskerLineColor  matlab.internal.datatype.matlab.graphics.datatype.RGBAColor
        BoxFaceAlpha matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne
        WhiskerLineStyle matlab.internal.datatype.matlab.graphics.datatype.LineStyle
        LineWidth matlab.internal.datatype.matlab.graphics.datatype.Positive
        SeriesIndex
        % Markers:
        MarkerStyle matlab.internal.datatype.matlab.graphics.datatype.LineStyle
        MarkerSize
        MarkerColor  matlab.internal.datatype.matlab.graphics.datatype.RGBAColor
        MarkerColorMode
        % Data:
        XData
        XDataMode
        YData
        YDataMode
        % Table data
        SourceTable
        XVariable
        YVariable
        % Interactivity:
        Visible
        DataTipTemplate
        ContextMenu
        Selected
        SelectionHighlight
        Clipping
        % Callbacks:
        ButtonDownFcn
        CreateFcn
        DeleteFcn
        % Callback Execution Control:
        Interruptible
        BusyAction
        PickableParts
        HitTest
        BeingDeleted
        % Parent/Child
        Parent
        Children
        HandleVisibility
        % Identifiers:
        Tag
        Type
        UserData
    end
    methods(Static)
        function iconProps = getIconProperties(hBoxChart)
            iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.rect);
            iconProps.edgeColor = hBoxChart.BoxEdgeColor;
            iconProps.faceColor = hBoxChart.BoxFaceColor;
        end
    end

    methods
        function this = PrimitiveBoxChartPropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);

            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:DataDisplay')),'','');
            g1.addProperties('BoxWidth','CapWidth','CapWidthMode',...
                'JitterOutliers','Notch','Orientation');                
            g1.addSubGroup('ColorGroupWidth','ColorGroupWidthMode','ColorGroupLayout');
            g1.Expanded = true;

            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g2.addProperties('BoxFaceColor','BoxEdgeColor',...
                'BoxMedianLineColor','WhiskerLineColor','BoxFaceAlpha','LineWidth','SeriesIndex');
            g2.addSubGroup('BoxFaceColorMode','BoxEdgeColorMode','BoxMedianLineColorMode',...
                'WhiskerLineStyle');
            g2.Expanded = true;

            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Markers')),'','');
            g3.addProperties('MarkerStyle','MarkerSize','MarkerColor','MarkerColorMode');

            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:Data')),'','');
            g4.addProperties('XData', 'XDataMode', 'YData', 'YDataMode');

            g5 = this.createGroup(getString(message('MATLAB:propertyinspector:TableData')),'','');
            g5.addProperties('SourceTable', 'XVariable', 'YVariable');

            this.createLegendGroup();
            this.createCommonInspectorGroup();

        end
    end
end
