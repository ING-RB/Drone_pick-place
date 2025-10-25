classdef PrimitiveScatterPropertyView <  matlab.graphics.internal.propertyinspector.views.DataspaceMixin & matlab.graphics.internal.propertyinspector.views.CommonPropertyViews & matlab.graphics.internal.propertyinspector.views.IconDataMixin
    % This class has the metadata information on the matlab.graphics.chart.primitive.Scatter property
    % groupings as reflected in the property inspector

    % Copyright 2017-2024 The MathWorks, Inc.
    
    properties
        Marker
        LineWidth
        MarkerEdgeColor
        MarkerFaceColor
        MarkerEdgeAlpha
        MarkerFaceAlpha 
        AlphaData
        AlphaDataMode
        AlphaDataMapping
        AlphaVariable
        CData
        CDataMode
        CDataSource
        ColorVariable
        SizeData
        SizeDataMode
        SizeDataSource
        SizeVariable
        Annotation
        DisplayName
        Selected
        SelectionHighlight
        SourceTable
        DataTipTemplate
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
        XJitter
        YJitter
        ZJitter
        XJitterDirection
        YJitterDirection
        ZJitterDirection
        XJitterWidth
        YJitterWidth
        ZJitterWidth
        SeriesIndex
    end

    methods(Static)
        function  iconProps = getIconProperties(hScatter)
            % set the three properties
            iconProps.shape = hScatter.Marker;
             iconProps.edgeColor = hScatter.MarkerEdgeColor;
             iconProps.faceColor = hScatter.MarkerFaceColor;
            % defining the default color
            defaultBlue = [0 0.4470 0.7410];
            % if the color is flat, use CData or the default color
            if strcmpi( iconProps.edgeColor,'flat')
                if length(hScatter.CData) == 3
                     iconProps.edgeColor = hScatter.CData(1,:);
                else
                     iconProps.edgeColor = defaultBlue;
                end
            end
            if strcmpi( iconProps.faceColor,'flat')
                if length(hScatter.CData) == 3
                    iconProps.faceColor = hScatter.CData(1,:);
                else
                     iconProps.faceColor = defaultBlue;
                end
            end
            % if the color is auto, make it white
            if strcmpi( iconProps.faceColor,'auto')
                 iconProps.faceColor = [1 1 1];               
            end            
        end
    end

    methods
        function this = PrimitiveScatterPropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);
            
            %...............................................................
            
            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Markers')),'','');
            g3.addProperties('Marker','LineWidth','MarkerEdgeColor','MarkerFaceColor');
            g3.Expanded = true;
            
            
            %...............................................................
            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:Transparency')),'','');
            g4.addProperties('MarkerFaceAlpha','MarkerEdgeAlpha','AlphaData','AlphaDataMode','AlphaVariable','AlphaDataMapping');
            g4.Expanded = true;
            
            g7 = this.createGroup(getString(message('MATLAB:propertyinspector:ColornadSizeData')),'','');
            g7.addProperties('CData','CDataSource','CDataMode','ColorVariable',...
                'SeriesIndex','SizeData','SizeDataSource','SizeDataMode','SizeVariable');
            g7.Expanded = true;
            
            g8 = this.createGroup(getString(message('MATLAB:propertyinspector:CoordinateData')),'','');
            g9 = this.createGroup(getString(message('MATLAB:propertyinspector:TableData')),'','');

            allPolar = numel(findobj(obj,'-property','RData')) == numel(obj);
            allCartesian = numel(findobj(obj,'-property','XData','-and','-not','-property','RData','-and','-not', '-property','LatitudeData')) == numel(obj);
            allGeo = numel(findobj(obj,'-property','LatitudeData')) == numel(obj);

            if allPolar
                this.addPolarProperties(obj, true);
                g8.addProperties('RData','RDataMode','RDataSource', ...
                    'ThetaData','ThetaDataMode','ThetaDataSource', ...
                    'RJitter', 'RJitterWidth', 'RJitterDirection', ...
                    'ThetaJitter', 'ThetaJitterWidth', 'ThetaJitterDirection');
            elseif allGeo
                this.addGeoProperties(obj, true);
                g8.addProperties('LatitudeData','LatitudeDataMode','LatitudeDataSource', ...
                    'LongitudeData','LongitudeDataMode','LongitudeDataSource', ...
                        'LatitudeJitter', 'LatitudeJitterWidth', 'LatitudeJitterDirection', ...
                        'LongitudeJitter', 'LongitudeJitterWidth', 'LongitudeJitterDirection');
                g9.addProperties('SourceTable', 'LatitudeVariable', 'LongitudeVariable');
            elseif allCartesian
                this.addCartesianProperties(obj, true);
                g8.addProperties('XData', 'XDataMode', 'XDataSource', ...
                    'YData', 'YDataMode', 'YDataSource', ...
                    'ZData', 'ZDataMode', 'ZDataSource', ...
                    'XJitter', 'XJitterWidth', 'XJitterDirection', ...
                    'YJitter', 'YJitterWidth', 'YJitterDirection', ...
                    'ZJitter', 'ZJitterWidth', 'ZJitterDirection');
                g9.addProperties('SourceTable', 'XVariable', 'YVariable', 'ZVariable');
            end

            
            %...............................................................
            
            this.createLegendGroup();
            
            %...............................................................
            this.createCommonInspectorGroup();
            
        end
    end
end
