classdef PrimitiveDensityPlotPropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews
    % This class has the metadata information on the matlab.graphics.chart.primitive.DensityPlot.  property
    % groupings as reflected in the property inspector

    % Copyright 2018-2023 The MathWorks, Inc.

    properties
        Annotation
        BeingDeleted
        BusyAction
        ButtonDownFcn
        Children
        CreateFcn
        DeleteFcn
        DisplayName
        FaceAlpha
        FaceColor
        FaceColorMode
        HandleVisibility
        HitTest
        Interruptible
        LatitudeData
        LatitudeDataSource
        LongitudeData
        LongitudeDataSource
        Parent
        PickableParts
        Radius
        RadiusMode
        Selected
        SelectionHighlight
        Tag
        Type
        ContextMenu
        UserData
        Visible
        WeightData
        WeightDataSource
        SeriesIndex

    end

    methods
        function this = PrimitiveDensityPlotPropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);

            %...............................................................

            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:Density')),'','');
            g2.addProperties('Radius',...
                'RadiusMode');
            g2.addSubGroup('WeightData',...
                'WeightDataSource');
            g2.Expanded = 'true';

            %...............................................................

            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandTransparency')),'','');
            g3.addProperties('FaceColor','FaceAlpha','SeriesIndex');
            g3.addSubGroup('FaceColorMode');

            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:GeographicCoordinateData')),'','');
            g4.addProperties('LongitudeData',...
                'LatitudeData',...
                'LongitudeDataSource',...
                'LatitudeDataSource' );
            %...............................................................

            this.createLegendGroup();

            %...............................................................
            this.createCommonInspectorGroup();
        end
    end
end
