classdef RulerPropertyViews < internal.matlab.inspector.InspectorProxyMixin & matlab.graphics.internal.propertyinspector.views.FontSizeMixin
    % RulerPropertyViews - a helper class that creates common
    % property groups for rulers
    
    % Copyright 2018-2023 The MathWorks, Inc.
    
    properties
        Children
        Color
        Direction
        FontName
        FontAngle internal.matlab.editorconverters.datatype.FontAngle
        FontWeight internal.matlab.editorconverters.datatype.FontWeight
        HandleVisibility
        Label
        LabelHorizontalAlignment
        Limits
        LimitsChangedFcn
        LimitsMode
        LineWidth
        MinorTick
        MinorTickValues
        MinorTickValuesMode
        Parent
        Scale
        TickDirection
        TickDirectionMode
        TickLabelColor
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
    
    methods
        
        function this = RulerPropertyViews(obj)
            this = this@internal.matlab.inspector.InspectorProxyMixin(obj);
        end
        
        function createCommonRulerGroup(this)
            %...............................................................
            g1 = this.createGroup(getString(message('MATLAB:propertyinspector:ColorandStyling')),'','');
            g1.addProperties('Color',...
                'LineWidth',...
                'Visible');
            
            g1.Expanded = true;
            %...............................................................
            
            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:LimitsAndScale')),'','');
            g2.addProperties('Limits',...
                'LimitsMode',...
                'Scale',...
                'Direction',...
                'LimitsChangedFcn');
            
            % Categories is not always available, add it conditionally
            if isprop(this,'Categories')
                g2.addProperties('Categories');
            end
            
            % ReferenceDate is not always available, add it conditionally
            if isprop(this,'ReferenceDate')
                g2.addProperties('ReferenceDate');
            end
            
            g2.Expanded = true;
            
            %...............................................................
            g3 = this.createGroup(getString(message('MATLAB:propertyinspector:Ticks')),'','');
            g3.addProperties('TickValues',...
                'TickValuesMode',...
                'TickLabels',...
                'TickLabelsMode',...
                'TickLabelColor',...
                'TickLabelInterpreter',...
                'TickLabelRotation',...
                'TickLabelRotationMode',...
                'TickDirection',...
                'TickDirectionMode',...
                'TickLength');
            
            % Exponent is not always available, add it conditionally
            if isprop(this,'Exponent')
                g3.addProperties('Exponent');
            end
            
            % ExponentMode is not always available, add it conditionally
            if isprop(this,'ExponentMode')
                g3.addProperties('ExponentMode');
            end
            
            
            % TickLabelFormat is not always available, add it conditionally
            if isprop(this,'TickLabelFormat')
                g3.addProperties('TickLabelFormat');
            end
            
            % TickLabelFormatMode is not always available, add it conditionally
            if isprop(this,'TickLabelFormatMode')
                g3.addProperties('TickLabelFormatMode');
            end

            % SecondaryLabelFormat is not always available, add it conditionally
            if isprop(this,'SecondaryLabelFormat')
                g3.addProperties('SecondaryLabelFormat');
            end

            % SecondaryLabelFormatMode is not always available, add it conditionally
            if isprop(this,'SecondaryLabelFormatMode')
                g3.addProperties('SecondaryLabelFormatMode');
            end
            
            %...............................................................
            g4 = this.createGroup(getString(message('MATLAB:propertyinspector:MinorTicks')),'','');
            g4.addProperties('MinorTick',...
                'MinorTickValues',...
                'MinorTickValuesMode');
            
            
            %...............................................................
            g6 = this.createGroup(getString(message('MATLAB:propertyinspector:Font')),'','');
            g6.addProperties('FontName',...
                'FontSize',...
                'FontWeight',...
                'FontAngle');
            
            %...............................................................
            g2 = this.createGroup(getString(message('MATLAB:propertyinspector:Label')),'','');
            g2.addProperties('Label');
            g2.addProperties('LabelHorizontalAlignment');         
            
            %...............................................................
            g7 = this.createGroup(getString(message('MATLAB:propertyinspector:ParentChild')),'','');
            g7.addProperties('Parent',...
                'Children','HandleVisibility');
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
