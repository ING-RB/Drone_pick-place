classdef AnimatedLinePropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews
    % This class has the metadata information on the matlab.graphics.animation.AnimatedLine property
    % groupings as reflected in the property inspector

    % Copyright 2017-2023 The MathWorks, Inc.

    properties
        AlignVertexCenters
        Annotation
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
        MaximumNumPoints
        Parent
        PickableParts
        Selected
        SelectionHighlight
        SeriesIndex
        Tag
        Type
        ContextMenu
        UserData
        Visible
    end

    methods
        function this = AnimatedLinePropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);
            %...............................................................

            g1 = this.createGroup('Color and Styling','','');
            g1.addProperties('Color','LineStyle','LineWidth','SeriesIndex');
            g1.addSubGroup('MaximumNumPoints','AlignVertexCenters','ColorMode','LineStyleMode');
            g1.Expanded = true;

            %...............................................................

            g2 = this.createGroup('Markers','','');
            g2.addProperties('Marker','MarkerSize');
            g2.addSubGroup('MarkerEdgeColor','MarkerFaceColor','MarkerMode');
            g2.Expanded = true;

            %...............................................................
            this.createLegendGroup();
            %...............................................................
            this.createCommonInspectorGroup();
        end
    end
end
