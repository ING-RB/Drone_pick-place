classdef PrimitiveHistogram2PropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews & matlab.graphics.internal.propertyinspector.views.IconDataMixin
    % This class has the metadata information on the matlab.graphics.chart.primitive.Histogram2 property
    % groupings as reflected in the property inspector

    % Copyright 2017 - 2021 The MathWorks, Inc.
    
    properties        
        Annotation
        BeingDeleted
        BinCounts
        BinCountsMode
        BinMethod
        BinWidth
        BusyAction
        ButtonDownFcn
        Children
        CreateFcn
        Data
        DeleteFcn
        DisplayName
        DisplayStyle
        EdgeAlpha
        EdgeColor
        FaceAlpha
        FaceColor
        FaceLighting
        HandleVisibility
        HitTest
        Interruptible
        LineStyle
        LineWidth
        Normalization
        NumBins
        Parent
        PickableParts
        Selected
        SelectionHighlight
        ShowEmptyBins
        Tag
        Type
        ContextMenu
        UserData
        Values
        Visible
        XBinEdges
        XBinLimits
        XBinLimitsMode
        YBinEdges
        YBinLimits
        YBinLimitsMode
        DataTipTemplate 
        SeriesIndex
    end

    methods(Static)
        function iconProps = getIconProperties(hHist2)
            iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.rect);
            iconProps.edgeColor = hHist2.EdgeColor;
            iconProps.faceColor = hHist2.FaceColor;
            % defining the default color
            defaultBlue = [0 0.4470 0.7410];
            % if the color is auto, then the default color is used
            if strcmpi(iconProps.faceColor,'auto')
                iconProps.faceColor = defaultBlue;
            end
            if strcmpi(iconProps.edgeColor,'auto')
                iconProps.edgeColor = defaultBlue;
            end
        end
    end
    
    methods
        function this = PrimitiveHistogram2PropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);
            
            %...............................................................
            
            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:Bins')),'','');
            g1.addProperties('NumBins',...
                'BinWidth',...
                'XBinEdges');
            
            g1.addSubGroup('YBinEdges',...
                'XBinLimits',...
                'XBinLimitsMode',...
                'YBinLimits',...
                'YBinLimitsMode',...
                'BinMethod',...
                'ShowEmptyBins');
            
            g1.Expanded = true;
            
            %...............................................................
            
            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:Data')),'','');
            g2.addProperties('Data','Values','Normalization');
            g2.addSubGroup('BinCounts',...
                'BinCountsMode');
            g2.Expanded = true;
            
            %...............................................................
            
            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g2.addProperties('DisplayStyle',...                
                'FaceColor',...
                'EdgeColor');
            
            g2.addSubGroup('FaceAlpha',...�
                'EdgeAlpha',...
                'FaceLighting',...
                'LineStyle',...
                'LineWidth',...
                'SeriesIndex');
            g2.Expanded = true;
            
            %...............................................................
            
            
            this.createLegendGroup();
            
            %...............................................................
            
            this.createCommonInspectorGroup();       
        end
    end
end