classdef LampPropertyView < ...
        inspector.internal.AppDesignerPropertyView & ...
        inspector.internal.mixin.PositionMixin
    % This class provides the property definition and groupings for Lamp
    
    % Copyright 2015-2019 The MathWorks, Inc.
    
    properties(SetObservable = true)
        Color matlab.internal.datatype.matlab.graphics.datatype.RGBColor
        
        Visible matlab.lang.OnOffSwitchState
        Enable matlab.lang.OnOffSwitchState
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString

        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end
    
    
    
    methods
        function obj = LampPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);
            
            inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:ColorGroup', ...
                'Color'...
                );
            
            %Common properties across all components
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
            
            
            
        end
    end
end
