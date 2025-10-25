classdef DecorationConstantRegionPropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews ...
        & matlab.graphics.internal.propertyinspector.views.IconDataMixin

    % This class has the metadata information on the
    % matlab.graphics.chart.decoration.ConstantRegion  property groupings
    % as reflected in the property inspector

    % Copyright 2023-2024 The MathWorks, Inc.

    properties
        Annotation
        BeingDeleted
        BusyAction
        ButtonDownFcn
        Children
        ContextMenu
        CreateFcn
        DeleteFcn
        DisplayName
        EdgeAlpha matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne
        EdgeColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor
        FaceAlpha matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne
        FaceColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor
        FaceColorMode
        HandleVisibility
        HitTest
        InterceptAxis matlab.internal.datatype.matlab.graphics.chart.datatype.InterceptAxisType
        Interruptible
        Layer
        LineStyle matlab.internal.datatype.matlab.graphics.datatype.LineStyle
        LineWidth matlab.internal.datatype.matlab.graphics.datatype.Positive
        Parent
        PickableParts
        Selected
        SelectionHighlight
        SeriesIndex
        Tag
        Type
        UserData
        Value
        Visible
    end

    methods(Static)
        function iconProps = getIconProperties(hConstantRegion)
            iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.rect);
            iconProps.edgeColor = hConstantRegion.EdgeColor;
            iconProps.faceColor = hConstantRegion.FaceColor;
        end
    end

    methods
        function this = DecorationConstantRegionPropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);

            %...............................................................
            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g1.addProperties('FaceColor','EdgeColor', 'FaceAlpha', 'EdgeAlpha', 'LineStyle', 'LineWidth','SeriesIndex');
            g1.addSubGroup('FaceColorMode');
            g1.Expanded = true;

            %...............................................................

            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:Location')),'','');
            g2.addProperties('Value','InterceptAxis','Layer');
            g2.Expanded = true;

            %...............................................................
            this.createLegendGroup();
            %..............................................................
            this.createCommonInspectorGroup();
        end
    end
end