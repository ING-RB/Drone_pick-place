classdef NumericEditFieldPropertyView < ...
        inspector.internal.AppDesignerPropertyView & ...
        inspector.internal.mixin.HorizontalAlignmentMixin & ...
        inspector.internal.mixin.ValueDisplayFormatMixin & ...
        inspector.internal.mixin.FontMixin
    
    % This class provides the property definition and groupings for Number
    % edit field
    
    % Copyright 2015-2023 The MathWorks, Inc.
    
    properties(SetObservable = true)
        Value (1,1) double {mustBeReal}
        Limits matlab.internal.datatype.matlab.graphics.datatype.LimitsWithInfs
        
        LowerLimitInclusive matlab.lang.OnOffSwitchState
        UpperLimitInclusive matlab.lang.OnOffSwitchState
        RoundFractionalValues matlab.lang.OnOffSwitchState
        AllowEmpty matlab.lang.OnOffSwitchState
        
        FontColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        BackgroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        
        Visible matlab.lang.OnOffSwitchState
        Editable matlab.lang.OnOffSwitchState
        Enable matlab.lang.OnOffSwitchState
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        Placeholder char {matlab.internal.validation.mustBeVector(Placeholder)}

        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end
    
    methods
        function obj = NumericEditFieldPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);
            
            group = obj.createGroup( ...
                'MATLAB:ui:propertygroups:ValueGroup', ...
                'MATLAB:ui:propertygroups:ValueGroup', ...
                '');
            
            group.addProperties('Value');
            group.addEditorGroup('Limits');
            group.addProperties('RoundFractionalValues');
            group.addEditorGroup('ValueDisplayFormat');
            group.addProperties('AllowEmpty');
            group.addProperties('Placeholder');
            group.addProperties('HorizontalAlignment');
            group.addSubGroup('LowerLimitInclusive', 'UpperLimitInclusive');
            
            group.Expanded = true;
            
            %Common properties across all components
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
        end
    end
end
