classdef TreePropertyView < ...
        inspector.internal.AppDesignerPropertyView & ...
        inspector.internal.mixin.FontMixin
    % This class provides the property definition and groupings for Tree
    
    % Copyright 2017-2019 The MathWorks, Inc.
    
    properties(SetObservable = true)
        
        Multiselect matlab.lang.OnOffSwitchState
        
        FontColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        BackgroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        
        Visible matlab.lang.OnOffSwitchState
        Editable matlab.lang.OnOffSwitchState
        Enable matlab.lang.OnOffSwitchState        

        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString                
        
        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end
    
    methods
        function obj = TreePropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);
            
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
        end
    end
end
