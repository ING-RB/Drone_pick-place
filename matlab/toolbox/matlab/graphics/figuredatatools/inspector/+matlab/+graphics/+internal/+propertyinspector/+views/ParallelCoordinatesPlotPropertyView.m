classdef ParallelCoordinatesPlotPropertyView < internal.matlab.inspector.InspectorProxyMixin & matlab.graphics.internal.propertyinspector.views.FontSizeMixin
    % This class has the metadata information on the
    % matlab.graphics.chart.ParallelCoordinatesPlot property groupings as
    % reflected in the property inspector

    % Copyright 2018-2021 The MathWorks, Inc.
    
    properties
        PositionConstraint
        Color internal.matlab.editorconverters.datatype.ExtendedColor
        CoordinateData
        CoordinateLabel
        CoordinateTickLabels matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        CoordinateVariables
        Data
        DataLabel
        DataNormalization
        FontName
        GroupData
        GroupVariable
        HandleVisibility
        InnerPosition
        Jitter
        LegendTitle
        LegendVisible matlab.internal.datatype.matlab.graphics.datatype.on_off
        LineAlpha
        LineStyle matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        LineWidth
        MarkerSize
        MarkerStyle matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        OuterPosition
        Parent
        Position
        SourceTable
        Title
        Units
        Visible 
    end
    
    methods
        function this = ParallelCoordinatesPlotPropertyView(obj)
            this@internal.matlab.inspector.InspectorProxyMixin(obj);
            
            %...............................................................
            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:Labels')),'','');
            g1.addProperties('Title',...
                'CoordinateLabel',...
                'CoordinateTickLabels',...
                'DataLabel',...
                'LegendTitle',...
                'LegendVisible');           
            g1.Expanded =true;
            
            %...............................................................
            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:DataDisplay')),'','');
            g2.addProperties('DataNormalization','Jitter');
            g2.Expanded =true;
            
            %...............................................................
            
            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g3.addProperties('Color',...
                'LineAlpha',...
                'LineStyle',...
                'LineWidth',...
                'MarkerSize',...
                'MarkerStyle');
            g3.Expanded =true;
                       
            %...............................................................
                                                 
            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:Font')),'','');
            g4.addProperties('FontName','FontSize');
                            
            %...............................................................
            
            g5 = this.createGroup(getString(message('MATLAB:propertyinspector:Position')),'','');
            g5.addEditorGroup('OuterPosition');
            g5.addEditorGroup('InnerPosition');
            g5.addEditorGroup('Position');
            g5.addProperties('PositionConstraint','Units',...
                'Visible');
            
            %...............................................................
            
            g6 = this.createGroup(getString(message('MATLAB:propertyinspector:TableData')),'','');
            g6.addProperties('SourceTable', ...
                'CoordinateVariables', ...
                'GroupVariable');
            
            %...............................................................
            
            g7 = this.createGroup(getString(message('MATLAB:propertyinspector:MatrixData')),'','');
            g7.addProperties('Data', ...
                'CoordinateData', ...
                'GroupData');

            %...............................................................            
            
            g8 = this.createGroup(getString(message('MATLAB:propertyinspector:ParentChild')),'','');
            g8.addProperties('Parent','HandleVisibility');            

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
