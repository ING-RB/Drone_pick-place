classdef DecorationConstantLinePropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews ...
        & matlab.graphics.internal.propertyinspector.views.FontSizeMixin ...
        & matlab.graphics.internal.propertyinspector.views.IconDataMixin
    % This class has the metadata information on the matlab.graphics.chart.decoration.ConstantLine  property
    % groupings as reflected in the property inspector

    % Copyright 2017-2024 The MathWorks, Inc.

    properties
        Alpha
        Annotation
        BeingDeleted
        BusyAction
        ButtonDownFcn
        Children
        Color
        ColorMode
        CreateFcn
        DeleteFcn
        DisplayName
        FontAngle internal.matlab.editorconverters.datatype.FontAngle
        FontName
        FontWeight internal.matlab.editorconverters.datatype.FontWeight
        HandleVisibility
        HitTest
        InterceptAxis
        Interpreter
        Interruptible
        Label
        LabelColor
        LabelColorMode
        LabelHorizontalAlignment
        LabelOrientation
        LabelVerticalAlignment
        Layer
        LineStyle
        LineStyleMode
        LineWidth
        Parent
        PickableParts
        Selected
        SelectionHighlight
        SeriesIndex
        Tag
        Type
        ContextMenu
        UserData
        Value
        Visible

    end

    methods(Static)
        function iconProps = getIconProperties(hPLine)
            iconProps.shape = string(matlab.graphics.internal.propertyinspector.views.Shapes.line);
            iconProps.edgeColor = hPLine.Color;
            iconProps.faceColor = 'none';
        end
    end

    methods
        function this = DecorationConstantLinePropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);

            %...............................................................
            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g1.addProperties('Color','LineStyle','LineWidth','Alpha','SeriesIndex');
            g1.addSubGroup('ColorMode','LineStyleMode');
            g1.Expanded = true;

            %...............................................................

            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Location')),'','');
            g3.addProperties('Value','InterceptAxis','Layer');
            g3.Expanded = true;

            %...............................................................

            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:LabelandFont')),'','');

            g4.addProperties('Label',...
                'FontName',...
                'FontSize',...
                'FontWeight',...
                'FontAngle',...
                'Interpreter',...
                'LabelColor',...
                'LabelColorMode')

            %...............................................................

            g5 = this.createGroup(getString(message('MATLAB:propertyinspector:Position')),'','');
            g5.addProperties('LabelHorizontalAlignment',...
                'LabelVerticalAlignment',...
                'LabelOrientation');

            %...............................................................
            this.createLegendGroup();
            %..............................................................
            this.createCommonInspectorGroup();
        end

        function value = get.FontWeight(this)
            value = this.OriginalObjects.FontWeight;
        end

        function set.FontWeight(this, value)
            if ~this.InternalPropertySet
                for idx = 1:length(this.OriginalObjects)
                    if ~isequal(this.OriginalObjects(idx).FontWeight,value.getValue)
                        this.OriginalObjects(idx).FontWeight = value.getValue;
                    end
                end
            end
        end

        function value = get.FontAngle(this)
            value = this.OriginalObjects.FontAngle;
        end

        function set.FontAngle(this, value)
            if ~this.InternalPropertySet
                for idx = 1:length(this.OriginalObjects)
                    if ~isequal(this.OriginalObjects(idx).FontAngle,value.getValue)
                        this.OriginalObjects(idx).FontAngle = value.getValue;
                    end
                end
            end
        end
    end
end
