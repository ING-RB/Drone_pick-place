classdef PrimitiveStairPropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews & matlab.graphics.internal.propertyinspector.views.IconDataMixin
    % This class has the metadata information on the matlab.graphics.chart.primitive.Stair property
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
        XData
        YData
        XDataMode
        YDataMode
        XVariable
        YVariable
        DataTipTemplate
        XDataSource
        YDataSource
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
        function iconProps= getIconProperties(hStair)
            % not going to use face color for lines
            iconProps.faceColor = 'none';
            % defaulting the edge color to the line property
            iconProps.edgeColor = hStair.Color;
            if strcmpi(hStair.LineStyle,'none')
                iconProps.shape = hStair.Marker;
                if strcmpi(hStair.MarkerEdgeColorMode,'manual')
                    iconProps.edgeColor = hStair.MarkerEdgeColor;
                end

                if strcmpi(hStair.MarkerFaceColorMode,'manual')
                    iconProps.faceColor = hStair.MarkerFaceColorMode;
                end
            else
                iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.line);
            end
        end
    end

    methods
        function this = PrimitiveStairPropertyView(obj)
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

            g7 = this.createGroup(getString(message('MATLAB:propertyinspector:CoordinateData')),'','');
            g7.addProperties('XData','XDataMode','XDataSource','YData','YDataMode','YDataSource');

            %...............................................................

            g8 = this.createGroup(getString(message('MATLAB:propertyinspector:TableData')),'','');
            g8.addProperties('SourceTable','XVariable','YVariable');

            %...............................................................

            this.createLegendGroup();

             %...............................................................
            this.createCommonInspectorGroup();


        end
    end
end
