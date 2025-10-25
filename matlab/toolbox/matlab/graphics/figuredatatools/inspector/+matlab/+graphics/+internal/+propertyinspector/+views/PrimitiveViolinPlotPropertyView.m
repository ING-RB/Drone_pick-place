classdef PrimitiveViolinPlotPropertyView <  matlab.graphics.internal.propertyinspector.views.DataspaceMixin ...
        & matlab.graphics.internal.propertyinspector.views.CommonPropertyViews ...
        & matlab.graphics.internal.propertyinspector.views.IconDataMixin
    % This class has the metadata information on the
    % matlab.graphics.chart.primitive.ViolinPlot property
    % groupings as reflected in the property inspector

    % Copyright 2024 The MathWorks, Inc.

    properties
        % Legend:
        Annotation
        DisplayName
        % Data Display
        DensityWidth
        DensityDirection matlab.internal.datatype.matlab.graphics.datatype.DensityDirection
        DensityScale
        Orientation matlab.internal.datatype.matlab.graphics.datatype.HorizontalVertical
        ColorGroupWidth matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne
        ColorGroupWidthMode
        ColorGroupLayout matlab.internal.datatype.matlab.graphics.datatype.ColorGroupLayout
        % Color and styling
        EdgeColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor
        FaceAlpha matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne
        FaceColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor
        FaceColorMode
        EdgeColorMode
        LineStyle matlab.internal.datatype.matlab.graphics.datatype.LineStyle
        LineWidth matlab.internal.datatype.matlab.graphics.datatype.Positive
        SeriesIndex
        % Data:
        XData
        XDataMode
        YData
        YDataMode
        EvaluationPoints
        EvaluationPointsMode
        DensityValues
        DensityValuesMode
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
        function iconProps = getIconProperties(hViolinPlot)
            iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.rect);
            iconProps.edgeColor = hViolinPlot.EdgeColor;
            iconProps.faceColor = hViolinPlot.FaceColor;
        end
    end

    methods
        function this = PrimitiveViolinPlotPropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);

            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:DataDisplay')),'','');
            g1.addProperties('DensityWidth','DensityDirection','DensityScale','Orientation');
            g1.addSubGroup('ColorGroupWidth','ColorGroupWidthMode','ColorGroupLayout');
            g1.Expanded = true;

            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g2.addProperties('FaceColor', 'FaceColorMode', 'EdgeColor','EdgeColorMode', 'FaceAlpha', ...
                'LineStyle', 'LineWidth', 'SeriesIndex');
            g2.Expanded = true;

            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Data')),'','');
            g3.addProperties('XData', 'XDataMode', 'YData', 'YDataMode',...
                'EvaluationPoints','EvaluationPointsMode',...
                'DensityValues','DensityValuesMode');

            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:TableData')),'','');
            g4.addProperties('SourceTable', 'XVariable', 'YVariable');


            this.createLegendGroup();
            this.createCommonInspectorGroup();

        end
    end
end
