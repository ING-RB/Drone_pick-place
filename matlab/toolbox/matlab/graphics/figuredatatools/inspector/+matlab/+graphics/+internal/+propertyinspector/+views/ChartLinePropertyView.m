classdef ChartLinePropertyView <  matlab.graphics.internal.propertyinspector.views.CommonPropertyViews &  matlab.graphics.internal.propertyinspector.views.DataspaceMixin & matlab.graphics.internal.propertyinspector.views.IconDataMixin
    % This class has the metadata information on the matlab.graphics.chart.primitive.Line property
    % groupings as reflected in the property inspector

    % Copyright 2017-2023 The MathWorks, Inc.


    properties
        AffectAutoLimits
        Color
        ColorMode
        LineStyle
        LineStyleMode
        LineWidth
        AlignVertexCenters
        LineJoin
        Clipping
        Marker
        MarkerMode
        MarkerSize
        MarkerEdgeColor
        MarkerFaceColor
        MarkerIndices
        Annotation
        DisplayName
        Selected
        SelectionHighlight
        ContextMenu
        Visible
        CreateFcn
        DeleteFcn
        ButtonDownFcn
        BeingDeleted
        BusyAction
        HitTest
        PickableParts
        DataTipTemplate
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
        function iconProps = getIconProperties(hLine)
            % not going to use face color for lines
            iconProps.faceColor = 'none';
            % defaulting the edge color to the line property
            iconProps.edgeColor = hLine.Color;
            if strcmpi(hLine.LineStyle,'none')
                iconProps.shape = hLine.Marker;
                % if the color was set manually, use that property to
                % define color
                if strcmpi(hLine.MarkerEdgeColorMode,'manual')
                    iconProps.edgeColor = hLine.MarkerEdgeColor;
                end
                if strcmpi(hLine.MarkerFaceColorMode,'manual')
                    iconProps.faceColor = hLine.MarkerFaceColor;
                end
            else
                iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.line);
            end
        end
    end


    methods
        function this = ChartLinePropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);

            %...............................................................

            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g2.addProperties('Color','LineStyle','LineWidth','SeriesIndex');
            g2.addSubGroup('LineJoin','AlignVertexCenters','ColorMode','LineStyleMode');
            g2.Expanded = true;

            %...............................................................

            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:Markers')),'','');
            g1.addProperties('Marker','MarkerIndices','MarkerSize');
            g1.addSubGroup('MarkerEdgeColor','MarkerFaceColor','MarkerMode');
            g1.Expanded = true;

            %...............................................................

            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:CoordinateData')),'','');
            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:TableData')),'','');

            % there could be multiple objects parented to different types of
            % axes: Cartesian/Polar.
            % Check if the objects share the same dataspace type, if yes, populate the Data/DataSource
            % groups, otherwise leave them empty
            allPolar = numel(findobj(obj,'-property','RData')) == numel(obj);
            allCartesian = numel(findobj(obj,'-property','XData','-and','-not','-property','RData','-and','-not', '-property','LatitudeData')) == numel(obj);
            allGeo = numel(findobj(obj,'-property','LatitudeData')) == numel(obj);

            if allPolar
                %Polar
                this.addPolarProperties(obj, true);
                g3.addProperties('RData','RDataMode','RDataSource',...
                    'ThetaData','ThetaDataMode','ThetaDataSource','AffectAutoLimits');
                g4.addProperties('SourceTable', 'RVariable', 'ThetaVariable');
            elseif allGeo
                %Geographic
                this.addGeoProperties(obj, true);
                g3.addProperties('LatitudeData','LatitudeDataMode','LongitudeData','LongitudeDataMode','LatitudeDataSource','LongitudeDataSource','AffectAutoLimits');
                g4.addProperties('SourceTable', 'LatitudeVariable', 'LongitudeVariable');
            elseif allCartesian
                % Cartesian or empty
                this.addCartesianProperties(obj, true);
                g3.addProperties('XData','XDataSource','XDataMode','YData','YDataMode','YDataSource','ZData','ZDataMode','ZDataSource','AffectAutoLimits');
                g4.addProperties('SourceTable', 'XVariable', 'YVariable', 'ZVariable');
            end
            %...............................................................

            this.createLegendGroup();

            %...............................................................
           this.createCommonInspectorGroup();

        end
    end
end
