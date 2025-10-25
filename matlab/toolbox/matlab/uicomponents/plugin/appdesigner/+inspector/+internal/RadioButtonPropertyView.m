classdef RadioButtonPropertyView < inspector.internal.AppDesignerPropertyView & ...
        inspector.internal.mixin.InterpreterMixin & ...
        inspector.internal.mixin.FontMixin
    % This class provides the property definition and groupings for Radio
    % button
    
    % Copyright 2015-2023 The MathWorks, Inc.
    
    properties(SetObservable = true)
        Text matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        WordWrap matlab.lang.OnOffSwitchState
        Value
        
        FontColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        
        Visible matlab.lang.OnOffSwitchState
        Enable matlab.lang.OnOffSwitchState
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString

        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end
    
    methods
        function obj = RadioButtonPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);
            
            inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:ButtonGroup',...
                'Value', 'Text', 'Interpreter', 'WordWrap');
            
            %Common properties across all components
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
        end
    end
end
