classdef StackedLineChartPropertyView < internal.matlab.inspector.InspectorProxyMixin & matlab.graphics.internal.propertyinspector.views.FontSizeMixin
    % This class has the metadata information on the matlab.graphics.chart.StackedLineChart 
    % property groupings as reflected in the property inspector

    % Copyright 2018-2023 The MathWorks, Inc.
    
    properties
        PositionConstraint
        Color
        DisplayLabels
        DisplayVariables
        FontName
        GridVisible
        EventsVisible
        HandleVisibility
        InnerPosition
        LineStyle
        LineWidth
        Marker
        MarkerEdgeColor
        MarkerFaceColor
        MarkerSize
        OuterPosition
        Parent
        Position
        SourceTable
        Title
        Units
        Visible
        XData
        XLabel
        XLimits
        XVariable
        YData 
        CombineMatchingNames
        LegendLabels
        LegendOrientation
        LegendVisible
    end
    
    methods
        function this = StackedLineChartPropertyView(obj)
            this@internal.matlab.inspector.InspectorProxyMixin(obj);
            
            %...............................................................
            
            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g1.addProperties('Color', 'LineStyle', 'LineWidth', 'MarkerEdgeColor', ...
                'MarkerFaceColor', 'Marker', 'MarkerSize');
            g1.Expanded = true;
            
            %...............................................................
            
            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:Labels')),'','');
            g2.addProperties('Title', 'DisplayLabels', 'XLabel');
            g2.Expanded = false;
            
            %...............................................................
            
            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Font')),'','');
            g3.addProperties('FontName', 'FontSize');
            g3.Expanded = false;
            
            %...............................................................
            
            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:LimitsAndGrids')),'','');
            g4.addProperties('XLimits', 'GridVisible');
            g4.Expanded = false;
            
            %...............................................................
            
            g5 = this.createGroup(getString(message('MATLAB:propertyinspector:TableData')),'','');
            g5.addProperties('SourceTable', 'DisplayVariables', 'XVariable', 'CombineMatchingNames', 'EventsVisible');
            g5.Expanded = false;
            
             %...............................................................
            
            g6 = this.createGroup(getString(message('MATLAB:propertyinspector:ArrayData')),'','');
            g6.addProperties('XData', 'YData');
            g6.Expanded = false;
            
            %...............................................................
            
            g7 = this.createGroup(getString(message('MATLAB:propertyinspector:Position')),'','');           
            g7.addProperties('OuterPosition', 'InnerPosition', 'Position', ...
                'PositionConstraint', 'Units', 'Visible');
            g7.Expanded = false;
            
            %...............................................................
            
            g8 = this.createGroup(getString(message('MATLAB:propertyinspector:ParentChild')),'','');           
            g8.addProperties('Parent', 'HandleVisibility');
            g8.Expanded = false;

            %...............................................................
            
            g8 = this.createGroup(getString(message('MATLAB:propertyinspector:Legend')),'','');           
            g8.addProperties('LegendLabels', 'LegendOrientation', 'LegendVisible');
            g8.Expanded = false;
        end
    end
end
