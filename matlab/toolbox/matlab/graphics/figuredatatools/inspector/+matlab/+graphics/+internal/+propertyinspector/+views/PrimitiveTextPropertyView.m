classdef PrimitiveTextPropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews & matlab.graphics.internal.propertyinspector.views.FontSizeMixin

    % This class has the metadata information on the matlab.graphics.primitive.Text property
    % groupings as reflected in the property inspector

    % Copyright 2017-2023 The MathWorks, Inc.

    properties
        CreateFcn
        DeleteFcn
        ButtonDownFcn
        Tag
        Type
        UserData
        Children
        HandleVisibility
        Parent
        Visible
        BusyAction
        HitTest
        Interruptible
        PickableParts
        BeingDeleted
        Editing
        Selected
        SelectionHighlight
        ContextMenu
        Clipping
        Extent
        Position
        Units
        FontAngle internal.matlab.editorconverters.datatype.FontAngle
        FontWeight internal.matlab.editorconverters.datatype.FontWeight
        FontUnits
        Interpreter
        Color
        ColorMode
        FontName
        VerticalAlignment
        LineStyle
        LineWidth
        Margin
        HorizontalAlignment
        Rotation
        BackgroundColor
        EdgeColor
        String
        SeriesIndex
        AffectAutoLimits
    end

    methods
        function this = PrimitiveTextPropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);

            %...............................................................

            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:Text')),'','');
            g1.addProperties('String','Color','Interpreter','SeriesIndex');
            g1.addSubGroup('ColorMode');
            g1.Expanded = 'true';

            %...............................................................

            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:Font')),'','');
            g2.addProperties('FontName','FontSize','FontWeight');
            g2.addSubGroup('FontAngle','FontUnits');
            g2.Expanded = true;

            %...............................................................

            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:TextBox')),'','');
            g3.addProperties('Rotation','EdgeColor','BackgroundColor');
            g3.addSubGroup('LineStyle','LineWidth','Margin');
            g3.Expanded = 'true';

            %...............................................................

            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:Position')),'','');
            g4.addEditorGroup('Position');
            g4.addProperties('Units','HorizontalAlignment','VerticalAlignment','Extent','AffectAutoLimits');

            %...............................................................

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
