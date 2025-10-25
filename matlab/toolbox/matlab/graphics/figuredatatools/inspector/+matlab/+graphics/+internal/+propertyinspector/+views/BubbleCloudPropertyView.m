classdef BubbleCloudPropertyView < internal.matlab.inspector.InspectorProxyMixin & matlab.graphics.internal.propertyinspector.views.FontSizeMixin
    % This class has the metadata information on the matlab.graphics.chart.BubbleCloud
    % property groupings as reflected in the property inspector

    % Copyright 2020-2021 The MathWorks, Inc.

    properties
        ColorOrder
        EdgeColor
        FaceAlpha
        FaceColor
        FontColor
        FontName
        GroupData
        GroupVariable
        HandleVisibility
        InnerPosition
        LabelData
        LabelVariable
        LegendVisible
        OuterPosition
        Parent
        Position
        PositionConstraint
        SizeData
        SizeVariable
        SourceTable
        Title
        Units
        Visible
    end

    methods
        function this = BubbleCloudPropertyView(obj)
            this@internal.matlab.inspector.InspectorProxyMixin(obj);

            %...............................................................

            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:Labels')),'','');
            g1.addProperties('Title','LegendVisible');
            g1.Expanded = true;

            %...............................................................

            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g2.addProperties('ColorOrder','FaceColor','EdgeColor','FaceAlpha');
            g2.Expanded = true;

            %...............................................................

            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Font')),'','');
            g3.addProperties('FontName','FontSize','FontColor');

            %...............................................................

            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:TableData')),'','');
            g4.addProperties('SourceTable','SizeVariable','LabelVariable','GroupVariable');

            %...............................................................

            g5 = this.createGroup(getString(message('MATLAB:propertyinspector:VectorData')),'','');
            g5.addProperties('SizeData','LabelData','GroupData');

            %...............................................................
            
            g6 = this.createGroup(getString(message('MATLAB:propertyinspector:Position')),'','');
            g6.addEditorGroup('OuterPosition');
            g6.addEditorGroup('InnerPosition');
            g6.addEditorGroup('Position');
            g6.addProperties('PositionConstraint','Units','Visible');
            
            %...............................................................

            g7 = this.createGroup(getString(message('MATLAB:propertyinspector:ParentChild')),'','');
            g7.addProperties('Parent','HandleVisibility');

            %...............................................................
        end
    end
end
