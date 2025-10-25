classdef LegendPropertyView < matlab.graphics.internal.propertyinspector.views.CommonPropertyViews & matlab.graphics.internal.propertyinspector.views.FontSizeMixin
    % This class has the metadata information on the matlab.graphics.illustration.Legend property
    % groupings as reflected in the property inspector

    % Copyright 2017-2024 The MathWorks, Inc.
    
    properties
        String matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        Title,
        AutoUpdate,
        Location,
        Orientation,
        Position,
        Units,
        Color,
        EdgeColor,
        TextColor,
        Box,
        LineWidth,
        FontName,
        FontAngle internal.matlab.editorconverters.datatype.FontAngle
        FontWeight internal.matlab.editorconverters.datatype.FontWeight
        Interpreter,
        Selected,
        SelectionHighlight,
        ContextMenu,
        Visible,
        CreateFcn,
        DeleteFcn,
        ButtonDownFcn,
        BeingDeleted,
        BusyAction,
        HitTest,
        PickableParts,
        Interruptible,
        Children,
        HandleVisibility,
        Parent,
        Tag,
        Type,
        UserData,
        NumColumns,
        NumColumnsMode,
        IconColumnWidth,
        IconColumnWidthMode,
        Direction matlab.internal.datatype.matlab.graphics.datatype.AxisDirection
        DirectionMode,
        ItemHitFcn, 
        BackgroundAlpha
    end
    
    methods
        function this = LegendPropertyView(obj)
            this@matlab.graphics.internal.propertyinspector.views.CommonPropertyViews(obj);
            
            %...............................................................
            
            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:PositionandLayout')),'','');
            g1.addProperties('Location','Orientation','NumColumns', 'Direction','IconColumnWidth');
            g21 = g1.addSubGroup('');
            g21.addProperties('NumColumnsMode','DirectionMode','IconColumnWidthMode');
            % Position property has a rich editor
            g21.addEditorGroup('Position');
            g21.addProperties('Units');
            g1.Expanded = 'true';
            
            %...............................................................
            
            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:Labels')),'','');
            g2.addProperties('AutoUpdate','String','Title','Interpreter');
            g2.Expanded = 'true';
            
            %...............................................................
            
            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Font')),'','');
            g3.addProperties('FontName','FontSize','FontWeight','FontAngle');
            
            %...............................................................                        
            
            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g4.addProperties('TextColor','Color','EdgeColor','BackgroundAlpha');
            g4.addSubGroup('Box','LineWidth');
                       
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
