classdef GeographicRulerPropertyView ...
        <  matlab.graphics.internal.propertyinspector.views.GeographicTickLabelFormatMixin & matlab.graphics.internal.propertyinspector.views.FontSizeMixin
    % This class has the metadata information on the
    % matlab.graphics.axis.decorator.GeographicRuler property groupings as
    % reflected in the property inspector.  It was adapted from
    % NumericRulerPropertyView.
    
    % Copyright 2018-2021 The MathWorks, Inc.
    
    properties
        Children
        Color
        FontName
        FontAngle internal.matlab.editorconverters.datatype.FontAngle
        FontWeight internal.matlab.editorconverters.datatype.FontWeight
        Label
        LabelHorizontalAlignment
        LimitsChangedFcn
        LineWidth
        % GeographicRuler has minor tick properties, for consistency, but
        % they are not operational and can be commented out here:
        %   MinorTick
        %   MinorTickValues
        %   MinorTickValuesMode
        Parent
        TickDirection
        TickDirectionMode
        TickLabelColor
        % TickLabelFormat <== Inherited from GeographicTickLabelFormatMixin 
        TickLabelInterpreter
        TickLabelRotation
        TickLabelRotationMode
        TickLabels
        TickLabelsMode
        TickLength
        TickValues
        TickValuesMode
        Visible
    end
    
    
    properties (SetAccess = ?internal.matlab.inspector.InspectorProxyMixin)
        Limits
    end
    
    
    methods
        function this = GeographicRulerPropertyView(obj)
            this = this@matlab.graphics.internal.propertyinspector.views.GeographicTickLabelFormatMixin(obj);
            
            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:Appearance')),'','');
            g1.addProperties( ...
                'Limits',...
                'Color',...
                'LineWidth',...
                'Label',...
                'LabelHorizontalAlignment',...
                'Visible', ...
                'LimitsChangedFcn');
            g1.Expanded = true;
            
            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:Ticks')),'','');
            g2.addProperties(...
                'TickValues',...
                'TickValuesMode',...
                'TickLabels',...
                'TickLabelsMode',...
                'TickLabelColor',...
                'TickLabelInterpreter',...
                'TickLabelFormat',...
                'TickLabelRotation',...
                'TickLabelRotationMode',...
                'TickDirection',...
                'TickDirectionMode',...
                'TickLength');
            
            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Font')),'','');
            g3.addProperties(...
                'FontName',...
                'FontSize',...
                'FontWeight',...
                'FontAngle');
            
            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:ParentChild')),'','');
            g4.addProperties(...
                'Parent',...
                'Children');
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
