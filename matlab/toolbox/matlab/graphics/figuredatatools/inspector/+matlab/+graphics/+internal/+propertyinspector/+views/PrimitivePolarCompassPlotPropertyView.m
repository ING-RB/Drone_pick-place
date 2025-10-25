classdef PrimitivePolarCompassPlotPropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews & ...
        matlab.graphics.internal.propertyinspector.views.IconDataMixin

    % This class has the metadata information about the property groupings
    % for the matlab.graphics.chart.primitive.PolarCompassPlot class.

    % Copyright 2024 The MathWorks, Inc.

    properties
        Annotation
        BeingDeleted
        BusyAction
        ButtonDownFcn
        Children
        Clipping
        Color
        ColorMode
        ContextMenu
        CreateFcn
        DeleteFcn
        DisplayName
        HandleVisibility
        HitTest
        Interruptible
        LineStyle
        LineStyleMode
        LineWidth
        Parent
        PickableParts
        RData
        RDataMode
        RVariable
        Selected
        SelectionHighlight
        SeriesIndex
        SourceTable
        Tag
        ThetaData
        ThetaDataMode
        ThetaVariable
        Type
        UserData
        Visible
    end

    methods(Static)
        function iconProps = getIconProperties(hObj)
            iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.arrow);
            iconProps.edgeColor = hObj.Color;
            iconProps.faceColor = 'none';
        end
    end

    methods
        function this = PrimitivePolarCompassPlotPropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);

            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g1.addProperties('Color','LineStyle','LineWidth','SeriesIndex');
            g1.addSubGroup('ColorMode','LineStyleMode');
            g1.Expanded = 'true';

            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:Data')),'','');
            g2.addProperties('ThetaData','ThetaVariable',...
                'RData','RVariable','SourceTable');
            g2.addSubGroup('ThetaDataMode','RDataMode');

            this.createLegendGroup();

            this.createCommonInspectorGroup();
        end
    end
end
