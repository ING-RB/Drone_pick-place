classdef PrimitiveRectanglePropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews
    % This class has the metadata information on the matlab.graphics.primitive.Rectangle property
    % groupings as reflected in the property inspector

    % Copyright 2017-2023 The MathWorks, Inc.

    properties
        AlignVertexCenters
        BeingDeleted
        BusyAction
        ButtonDownFcn
        Children
        Clipping
        CreateFcn
        Curvature
        DeleteFcn
        EdgeColor
        EdgeColorMode
        FaceColor
        FaceAlpha
        HandleVisibility
        HitTest
        Interruptible
        LineStyle
        LineWidth
        Parent
        PickableParts
        Position
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
        function this = PrimitiveRectanglePropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);

            %...............................................................

            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g1.addProperties('FaceColor','EdgeColor','FaceAlpha','LineStyle','LineWidth',...
                'SeriesIndex','Curvature','AlignVertexCenters');
            g1.addSubGroup('EdgeColorMode');
            g1.Expanded = 'true';

            %...............................................................

            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:Position')),'','');
            g2.addEditorGroup('Position');
            g2.Expanded = 'true';

            %...............................................................

            this.createCommonInspectorGroup();
        end
    end
end
