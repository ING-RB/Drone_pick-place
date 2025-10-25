classdef DecorationConstantPlanePropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews ...
        & matlab.graphics.internal.propertyinspector.views.IconDataMixin
    % This class has the metadata information on the
    % matlab.graphics.chart.decoration.ConstantPlane property groupings
    % as reflected in the property inspector

    % Copyright 2024 The MathWorks, Inc.

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
        FaceAlpha matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne
        FaceColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor
        FaceColorMode
        HandleVisibility
        HitTest
        Interruptible
        NormalVector
        Offset
        Parent
        PickableParts
        Selected
        SelectionHighlight
        SeriesIndex
        Tag
        Type
        UserData
        Visible
    end

    methods(Static)
        function iconProps = getIconProperties(hConstantPlane)
            iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.rect);
            iconProps.faceColor = hConstantPlane.FaceColor;
        end
    end

    methods
        function this = DecorationConstantPlanePropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);

            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:Position')),'','');
            g1.addProperties('NormalVector', 'Offset');
            g1.Expanded = true;

            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g2.addProperties('FaceColor', 'FaceColorMode', 'FaceAlpha', 'SeriesIndex');
            g2.Expanded = true;

            this.createLegendGroup();
            this.createCommonInspectorGroup();
        end
    end
end