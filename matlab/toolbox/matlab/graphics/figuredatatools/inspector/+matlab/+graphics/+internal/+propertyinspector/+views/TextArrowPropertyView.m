classdef TextArrowPropertyView < internal.matlab.inspector.InspectorProxyMixin & matlab.graphics.internal.propertyinspector.views.FontSizeMixin
    % This class has the metadata information on the matlab.graphics.shape.TextArrow property
    % groupings as reflected in the property inspector

    % Copyright 2017-2021 The MathWorks, Inc.
    
    properties
        Color,
        Position,
        String,
        Interpreter,
        TextRotation,
        FontName,
        FontUnits,
        TextEdgeColor,
        FontAngle internal.matlab.editorconverters.datatype.FontAngle
        FontWeight internal.matlab.editorconverters.datatype.FontWeight
        TextColor,
        TextBackgroundColor,
        HorizontalAlignment,
        VerticalAlignment,
        LineStyle,
        LineWidth,
        Units,        
        TextLineWidth,
        TextMargin,
        HeadWidth,
        HeadStyle,
        X,
        Y,
        HeadLength
    end
    
    methods
        function this = TextArrowPropertyView(obj)
            this@internal.matlab.inspector.InspectorProxyMixin(obj);
            
            %...............................................................
            
            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:Text')),'','');
            g1.addProperties('String','TextRotation','TextColor');
            g1.addSubGroup('TextEdgeColor','TextBackgroundColor',...
                'TextLineWidth','TextMargin','Interpreter');
            g1.Expanded = 'true';
            
            %...............................................................
            
            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Font')),'','');
            g3.addProperties('FontName','FontSize','FontWeight');
            g3.addSubGroup('FontAngle','FontUnits');
            g3.Expanded = 'true';
            
            %...............................................................
            
            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:Arrow')),'','');
            g2.addProperties('Color','LineStyle','LineWidth');
            g2.addSubGroup('HeadStyle','HeadLength','HeadWidth');
            g2.Expanded = 'true';
                        
            %...............................................................
            
            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:Position')),'','');
            g4.addProperties('X');
            g4.addProperties('Y');
            g4.addEditorGroup('Position');
            g4.addProperties('Units','HorizontalAlignment','VerticalAlignment');
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
