classdef DecorationPolarRegionPropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews ...
        & matlab.graphics.internal.propertyinspector.views.IconDataMixin
    % This class has the metadata information on the
    % matlab.graphics.chart.decoration.PolarRegion property groupings
    % as reflected in the property inspector

    % Copyright 2023-2024 The MathWorks, Inc.

    properties
        Annotation
        BeingDeleted
        BusyAction
        ButtonDownFcn
        Children
        Clipping
        ContextMenu
        CreateFcn
        DeleteFcn
        DisplayName
        EdgeColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor
        FaceAlpha matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne
        FaceColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor
        FaceColorMode
        HandleVisibility
        HitTest
        Interruptible
        Layer
        LineStyle matlab.internal.datatype.matlab.graphics.datatype.LineStyle
        LineWidth matlab.internal.datatype.matlab.graphics.datatype.Positive
        Parent
        PickableParts
        RadiusSpan
        Selected
        SelectionHighlight
        SeriesIndex
        Tag
        ThetaSpan
        Type
        UserData
        Visible
    end

    methods(Static)
        function iconProps = getIconProperties(hPolarRegion)
            iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.rect);
            iconProps.edgeColor = hPolarRegion.EdgeColor;
            iconProps.faceColor = hPolarRegion.FaceColor;
        end
    end

    methods
        function this = DecorationPolarRegionPropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);

            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g1.addProperties('FaceColor', 'FaceColorMode', 'EdgeColor', 'FaceAlpha', 'LineStyle', 'LineWidth', 'SeriesIndex');
            g1.Expanded = true;

            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:Location')),'','');
            g2.addProperties('ThetaSpan', 'RadiusSpan', 'Layer', 'Clipping');
            g2.Expanded = true;

            this.createLegendGroup();
            this.createCommonInspectorGroup();
        end
    end
end