classdef CheckBoxPropertyView < inspector.internal.AppDesignerPropertyView & ...
        inspector.internal.mixin.FontMixin
    % This class provides the property definition and groupings for
    % Checkbox
    
    % Copyright 2015-2020 The MathWorks, Inc.
    
    properties(SetObservable = true)
        Text matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        WordWrap matlab.lang.OnOffSwitchState
        FontColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        Value
        
        Visible matlab.lang.OnOffSwitchState
        Enable matlab.lang.OnOffSwitchState
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString

        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end
    
    methods
        function obj = CheckBoxPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);
            
            inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:CheckBoxGroup',...
                'Value', ...
                'Text',...
                'WordWrap');
            
            %Common properties across all components
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
            
        end
    end
end
