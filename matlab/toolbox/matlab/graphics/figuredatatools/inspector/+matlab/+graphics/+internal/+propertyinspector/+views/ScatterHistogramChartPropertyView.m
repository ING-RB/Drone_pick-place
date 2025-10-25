classdef ScatterHistogramChartPropertyView < internal.matlab.inspector.InspectorProxyMixin & matlab.graphics.internal.propertyinspector.views.FontSizeMixin
    % This class has the metadata information on the  matlab.graphics.chart.ScatterHistogramChart property
    % groupings as reflected in the property inspector

    % Copyright 2018-2021 The MathWorks, Inc.
    
    properties
        PositionConstraint
        BinWidths
        Color internal.matlab.editorconverters.datatype.ExtendedColor
        FontName
        GroupData
        GroupVariable
        HandleVisibility
        HistogramDisplayStyle
        InnerPosition
        LegendTitle
        LegendVisible
        LineStyle matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        LineWidth
        MarkerAlpha
        MarkerFilled
        MarkerSize
        MarkerStyle matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        NumBins
        OuterPosition
        Parent
        Position
        ScatterPlotLocation
        ScatterPlotProportion
        SourceTable
        Title
        Units
        Visible
        XData
        XHistogramDirection
        XLabel
        XLimits
        XVariable
        YData
        YHistogramDirection
        YLabel
        YLimits
        YVariable        
    end
    
    methods
        function this = ScatterHistogramChartPropertyView(obj)
            this@internal.matlab.inspector.InspectorProxyMixin(obj);
            
            %...............................................................
            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:Labels')),'','');
            g4.addProperties('Title',...
                'XLabel',...
                'YLabel',...
                'LegendTitle');           
            g4.Expanded =true;
            
            %...............................................................
            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Histograms')),'','');
            g3.addProperties('NumBins',...
                'BinWidths',...
                'XHistogramDirection', ...
                'YHistogramDirection',...
                'HistogramDisplayStyle',...
                'LineStyle',...
                'LineWidth');
            g3.Expanded =true;
            
            %...............................................................
            
            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandFont')),'','');
            g2.addProperties('Color','FontName','FontSize');
                       
            %...............................................................
                                                 
            g7 = this.createGroup(getString(message('MATLAB:propertyinspector:Markers')),'','');
            g7.addProperties('MarkerStyle','MarkerSize','MarkerFilled','MarkerAlpha');
                            
            %...............................................................            
                                                 
            g8 = this.createGroup(getString(message('MATLAB:propertyinspector:Layout')),'','');
            g8.addProperties('ScatterPlotLocation','ScatterPlotProportion','LegendVisible');
                            
            %...............................................................
            
            g10 = this.createGroup(getString(message('MATLAB:propertyinspector:Position')),'','');
            g10.addEditorGroup('OuterPosition');
            g10.addEditorGroup('InnerPosition');
            g10.addEditorGroup('Position');
            g10.addProperties('PositionConstraint','Units',...
                'Visible');
            
            %...............................................................
            
            g11 = this.createGroup(getString(message('MATLAB:propertyinspector:DataandLimits')),'','');
            g11.addEditorGroup('SourceTable');
            g11.addEditorGroup('XVariable');
            g11.addEditorGroup('YVariable');
            g11.addEditorGroup('GroupVariable');
            g11.addEditorGroup('XData');
            
            g11.addEditorGroup('YData');
            g11.addEditorGroup('GroupData');
            g11.addEditorGroup('XLimits');
            g11.addEditorGroup('YLimits');

            %...............................................................            
            
            g9 = this.createGroup(getString(message('MATLAB:propertyinspector:ParentChild')),'','');
            g9.addProperties('Parent','HandleVisibility');            

        end
        
        function value = get.Color(this)
            value = this.OriginalObjects.Color;
        end
        
        function set.Color(this, value)
            if ~this.InternalPropertySet
                for idx = 1:length(this.OriginalObjects)
                    if ~isequal(this.OriginalObjects(idx).Color,value.getColor)
                        this.OriginalObjects(idx).Color = value.getColor;
                    end
                end
            end
        end
    end
end
