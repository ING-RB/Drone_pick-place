classdef ToggleSwitchPropertyView < ...
        inspector.internal.AppDesignerPropertyView & ...
        inspector.internal.mixin.LinearOrientationMixin & ...
        inspector.internal.mixin.FontMixin
    % This class provides the property definition and groupings for
    % ToggleSwitch
    
    % Copyright 2015-2019 The MathWorks, Inc.
    
    properties(SetObservable = true)
        Value internal.matlab.editorconverters.datatype.ItemsValue
        Items internal.matlab.editorconverters.datatype.ExactlyTwoItems
        ItemsData internal.matlab.editorconverters.datatype.ItemsValue
        
        FontColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        
        Visible matlab.lang.OnOffSwitchState
        Enable matlab.lang.OnOffSwitchState
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString

        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end
    
    methods
        function obj = ToggleSwitchPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);
            
            
            titleCatalogId = 'MATLAB:ui:propertygroups:SwitchGroup';
            group = inspector.internal.CommonPropertyView.createOptionsGroup(obj, titleCatalogId);
            group.addProperties('Orientation');
            
            %Common properties across all components
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
        end
    end
end
