classdef PieChartPropertyView < internal.matlab.inspector.InspectorProxyMixin & ...
        matlab.graphics.internal.propertyinspector.views.FontSizeMixin
    % This class has the metadata information on the matlab.graphics.chart.PieChart
    % property groupings as reflected in the property inspector

    % Copyright 2023 The MathWorks, Inc.

    properties
        CategoryCounts
        ColorOrder
        Data
        DataMode
        DataVariable
        Direction
        EdgeColor
        ExplodedWedges
        FaceAlpha
        FaceColor
        FontColor
        FontName
        HandleVisibility
        InnerPosition
        Interpreter
        Labels
        LabelsMode
        LabelStyleMode
        LegendTitle
        LegendVisible
        LineWidth
        Names
        NamesMode
        NamesVariable
        OuterPosition
        Parent
        Position
        PositionConstraint
        Proportions
        SourceTable
        StartAngle
        Title
        Units
        Visible
    end

    properties (Dependent,SetObservable)
        LabelStyle  internal.matlab.editorconverters.datatype.EditableStringEnumeration
    end

    methods
        function view = PieChartPropertyView(obj)
            view@internal.matlab.inspector.InspectorProxyMixin(obj);

            g1 = view.createGroup(getString(message('MATLAB:propertyinspector:Labels')),'','');
            g1.addProperties('Title','Labels','LabelStyle','LegendVisible','LegendTitle','Interpreter');
            g1.Expanded = true;
            g1.addSubGroup('LabelsMode','LabelStyleMode');

            g2 = view.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g2.addProperties('ColorOrder','FaceColor','EdgeColor','FaceAlpha','LineWidth','ExplodedWedges','Direction');
            g2.Expanded = true;

            g3 = view.createGroup(getString(message('MATLAB:propertyinspector:DataDisplay')),'','');
            g3.addProperties('CategoryCounts', 'Proportions', 'StartAngle');

            g4 = view.createGroup(getString(message('MATLAB:propertyinspector:Font')),'','');
            g4.addProperties('FontName','FontSize','FontColor');

            g5 = view.createGroup(getString(message('MATLAB:propertyinspector:VectorData')),'','');
            g5.addProperties('Data','Names','DataMode','NamesMode');

            g6 = view.createGroup(getString(message('MATLAB:propertyinspector:TableData')),'','');
            g6.addProperties('SourceTable','DataVariable','NamesVariable');

            g7 = view.createGroup(getString(message('MATLAB:propertyinspector:Position')),'','');
            g7.addEditorGroup('OuterPosition');
            g7.addEditorGroup('InnerPosition');
            g7.addEditorGroup('Position');
            g7.addProperties('PositionConstraint','Units','Visible');

            g8 = view.createGroup(getString(message('MATLAB:propertyinspector:ParentChild')),'','');
            g8.addProperties('Parent','HandleVisibility');
        end

         function set.LabelStyle(obj, inspectorValue)
            if obj.InternalPropertySet
                return
            end

            if isa(inspectorValue, "internal.matlab.editorconverters.datatype.EditableStringEnumeration")
                val = inspectorValue.Value;
            else
                val = inspectorValue;
            end
            obj.OriginalObjects.LabelStyle = val;
        end

        function val = get.LabelStyle(obj)
            val = internal.matlab.editorconverters.datatype.EditableStringEnumeration(...
                string(obj.OriginalObjects.LabelStyle), ["data","name","namedata","namepercent","none","percent"]);
        end
    end
end
