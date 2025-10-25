classdef GaugePropertyView < ...
        inspector.internal.AppDesignerPropertyView & ...
        inspector.internal.mixin.ScaleDirectionMixin & ...
        inspector.internal.mixin.FontMixin
    % This class provides the property definition and groupings for Gauge
    
    % Copyright 2015-2020 The MathWorks, Inc.
    
    properties(SetObservable = true)
        Value (1,1) double {mustBeReal}
        Limits matlab.internal.datatype.matlab.graphics.datatype.LimitsWithInfs
        
        ScaleColorLimits internal.matlab.editorconverters.datatype.ScaleColorLimits
        ScaleColors internal.matlab.editorconverters.datatype.ScaleColors
        
        MajorTicks matlab.internal.datatype.matlab.graphics.datatype.Tick
        MajorTicksMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual
        MajorTickLabels matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        MajorTickLabelsMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual
        MinorTicks double {mustBeReal}
        MinorTicksMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual
        
        FontColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        BackgroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        
        Visible matlab.lang.OnOffSwitchState
        Enable matlab.lang.OnOffSwitchState
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        
        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end
    
    methods
        function obj = GaugePropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);
            
            group = obj.createGroup( ...
                'MATLAB:ui:propertygroups:GaugeGroup', ...
                'MATLAB:ui:propertygroups:GaugeGroup', ...
                '');
            
            group.addProperties('Value')
            group.addEditorGroup('Limits')
            group.addProperties('ScaleDirection')
            group.addEditorGroup('ScaleColors','ScaleColorLimits')
            group.Expanded = true;
            
            inspector.internal.CommonPropertyView.createTicksGroup(obj);
            
            %Common properties across all components
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
        end
        
        function val = get.ScaleColorLimits(obj)
            val = obj.OriginalObjects.ScaleColorLimits;
        end
        
        function set.ScaleColorLimits(obj, val)
            for idx = 1:length(obj.OriginalObjects)
                if ~isequal(obj.OriginalObjects(idx).ScaleColorLimits, val.getLimits)
                    obj.OriginalObjects.ScaleColorLimits = val.getLimits;
                end
            end
        end
        
        function val = get.ScaleColors(obj)
            val = obj.OriginalObjects.ScaleColors;
        end
        
        function set.ScaleColors(obj, val)
            for idx = 1:length(obj.OriginalObjects)
                if ~isequal(obj.OriginalObjects(idx).ScaleColors, val.getColors)
                    obj.OriginalObjects.ScaleColors = val.getColors;
                end
            end
        end
    end
end
