classdef ParameterizedFunctionLinePropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews & matlab.graphics.internal.propertyinspector.views.IconDataMixin
    % This class has the metadata information on the ParameterizedFunctionLine property
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
        TRange
        TRangeMode
        Tag
        Type
        ContextMenu
        UserData
        Visible
        XData
        XFunction
        YData
        YFunction
        ZData
        ZFunction
        DataTipTemplate
        SeriesIndex
    end

    methods(Static)
        function iconProps = getIconProperties(hPFLine)
            iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.line);
            iconProps.edgeColor = hPFLine.Color;
            iconProps.faceColor = 'none';
        end
    end


    methods
        function this = ParameterizedFunctionLinePropertyView(obj)
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
            g3.addProperties('XFunction','YFunction','ZFunction');
            g3.addSubGroup('MeshDensity','TRange','TRangeMode');
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
