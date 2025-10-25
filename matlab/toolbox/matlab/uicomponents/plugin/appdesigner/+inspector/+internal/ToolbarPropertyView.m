classdef ToolbarPropertyView < inspector.internal.AppDesignerNoPositionPropertyView
    % This class provides the property definition and groupings for Toolbar
    
    % Copyright 2022 The MathWorks, Inc.
    
    properties(SetObservable = true)
        Visible matlab.lang.OnOffSwitchState
        Tag char {matlab.internal.validation.mustBeVector(Tag)}
        BackgroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor
    end
    
    methods
        function obj = ToolbarPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerNoPositionPropertyView(componentObject);
            
            %Common properties across all components
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
        end
    end
end