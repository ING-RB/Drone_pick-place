classdef FunctionLinePropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews & matlab.graphics.internal.propertyinspector.views.IconDataMixin
    % This class has the metadata information on the matlab.graphics.function.FunctionLine property
    % groupings as reflected in the property inspector

    % Copyright 2017-2023 The MathWorks, Inc.

    properties
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
        Function
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
        MeshDensity
        Parent
        PickableParts
        Selected
        SelectionHighlight
        ShowPoles
        Tag
        Type
        ContextMenu
        UserData
        Visible
        XData
        XRange
        XRangeMode
        YData
        ZData
        DataTipTemplate
        SeriesIndex
    end

    methods(Static)
        function iconProps = getIconProperties(hFLine)
            iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.line);
            iconProps.edgeColor = hFLine.Color;
            iconProps.faceColor = 'none';
        end
    end


    methods
        function this = FunctionLinePropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);

            %...............................................................

            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g1.addProperties('Color','LineStyle','LineWidth','SeriesIndex');
            g1.addSubGroup('ColorMode','LineStyleMode');
            g1.Expanded = true;

            %...............................................................

            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:Markers')),'','');
            g2.addProperties('Marker','MarkerSize');
            g2.addSubGroup('MarkerEdgeColor','MarkerFaceColor','MarkerMode');
            g2.Expanded = true;

            %...............................................................

            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Function')),'','');
            g3.addProperties('Function','MeshDensity');
            g3.addSubGroup('ShowPoles',...
                'XRange',...
                'XRangeMode');
            g3.Expanded = true;

            %...............................................................

            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:Data')),'','');
            g4.addProperties('XData','YData','ZData');

            %...............................................................

            this.createLegendGroup();

            %...............................................................

            this.createCommonInspectorGroup();
        end
    end
end
