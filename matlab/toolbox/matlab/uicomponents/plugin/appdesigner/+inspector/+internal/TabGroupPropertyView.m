classdef TabGroupPropertyView < inspector.internal.AppDesignerPropertyView & ...
        inspector.internal.mixin.TabLocationMixin
    % This class provides the property definition and groupings for Tab
    % Group
    
    % Copyright 2015-2019 The MathWorks, Inc.
    
    properties(SetObservable = true)
        AutoResizeChildren matlab.lang.OnOffSwitchState
        
        Visible matlab.lang.OnOffSwitchState
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString

        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end
    
    methods
        function obj = TabGroupPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerPropertyView(componentObject);
            
            inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:TabsGroup',...
                'TabLocation' ...
                );
            
            %Common properties across all components
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
        end
    end
end
