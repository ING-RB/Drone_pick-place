classdef PrimitiveGraphPlotPropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews    
    % This class has the metadata information on the matlab.graphics.chart.primitive.GraphPlot property
    % groupings as reflected in the property inspector

    % Copyright 2017-2022 The MathWorks, Inc.
    
    properties
        Annotation
        ArrowSize
        ArrowPosition
        BeingDeleted
        BusyAction
        ButtonDownFcn
        Children
        CreateFcn
        DeleteFcn
        DisplayName
        EdgeAlpha
        EdgeCData
        EdgeColor
        EdgeColorMode
        EdgeLabel
        EdgeLabelColor
        EdgeFontName
        EdgeFontSize
        EdgeFontWeight
        EdgeFontAngle
        EdgeLabelMode
        HandleVisibility
        HitTest
        Interpreter
        Interruptible
        LineStyle
        LineWidth
        Marker
        MarkerSize
        NodeCData
        NodeColor
        NodeColorMode
        NodeLabel
        NodeLabelColor
        NodeLabelMode
        NodeFontName
        NodeFontSize
        NodeFontWeight
        NodeFontAngle
        Parent
        PickableParts
        Selected
        SelectionHighlight
        ShowArrows
        Tag
        Type
        ContextMenu
        UserData
        Visible
        XData
        YData
        ZData      
        DataTipTemplate
        SeriesIndex
    end
    
    methods
        function this = PrimitiveGraphPlotPropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);
            
            %...............................................................
            
            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:Color')),'','');
            g1.addProperties('NodeColor','NodeColorMode','EdgeColor','EdgeColorMode');
            g1.addSubGroup('NodeCData','EdgeCData','SeriesIndex');
            g1.Expanded = true;
            
            %...............................................................
            
            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:NodeAndEdgeStyling')),'','');
            g2.addProperties('Marker', 'MarkerSize','LineStyle','LineWidth');
            g2.addSubGroup('EdgeAlpha','ArrowSize','ArrowPosition','ShowArrows');
            g2.Expanded = true;
            
            %...............................................................
            
            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Position')),'','');
            g3.addProperties('XData','YData','ZData');            
           
            %...............................................................
            
            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:NodeAndEdgeLabels')),'','');
            g4.addProperties('NodeLabel',...
                'NodeLabelMode',...
                'NodeLabelColor',...
                'EdgeLabel',...
                'EdgeLabelMode',...
                'EdgeLabelColor',...
                'Interpreter');
            
            %...............................................................
            
            g5 = this.createGroup(getString(message('MATLAB:propertyinspector:Font')),'','');
            g5.addProperties('NodeFontName',...
                'NodeFontSize',...
                'NodeFontWeight',...
                'NodeFontAngle',...
                'EdgeFontName',...
                'EdgeFontSize',...
                'EdgeFontWeight',...
                'EdgeFontAngle');
            
            %...............................................................
            this.createLegendGroup();
            
            %...............................................................
            
            this.createCommonInspectorGroup();
        end
    end
end