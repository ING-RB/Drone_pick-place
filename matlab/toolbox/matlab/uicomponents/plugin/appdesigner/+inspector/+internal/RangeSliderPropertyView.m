classdef RangeSliderPropertyView < ...
        inspector.internal.AppDesignerPropertyView & ...
        inspector.internal.mixin.LinearOrientationMixin & ...
        inspector.internal.mixin.FontMixin
    
    % This class provides the property definition and groupings for Range Slider
    
    % Copyright 2023 The MathWorks, Inc.
    
    properties(SetObservable = true)
        Value (1,2) double {mustBeReal}
        Limits matlab.internal.datatype.matlab.graphics.datatype.LimitsWithInfs
        
        MajorTicks matlab.internal.datatype.matlab.graphics.datatype.Tick
        MajorTicksMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual
        MajorTickLabels matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        MajorTickLabelsMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual
        MinorTicks double {mustBeReal}
        MinorTicksMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual
        
        Step (1,1) double {mustBeReal}
        StepMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual

        FontColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        
        Visible matlab.lang.OnOffSwitchState
        Enable matlab.lang.OnOffSwitchState
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString

        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end
    
    methods
        function obj = RangeSliderPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);
            
            group = obj.createGroup( ...
                'MATLAB:ui:propertygroups:SliderGroup', ...
                'MATLAB:ui:propertygroups:SliderGroup', ...
                '');
            
            group.addProperties('Value')
            group.addEditorGroup('Limits')
            group.addProperties('Orientation')
            group.addProperties('Step');
            group.addProperties('StepMode');

            group.Expanded = true;
            
            inspector.internal.CommonPropertyView.createTicksGroup(obj);
            
            %Common properties across all components
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
            
            
            
        end
    end
end
