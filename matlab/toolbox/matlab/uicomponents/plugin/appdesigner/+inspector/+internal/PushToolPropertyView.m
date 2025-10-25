classdef PushToolPropertyView < inspector.internal.AppDesignerNoPositionPropertyView
    % This class provides the property definition and groupings for
    % Push Tool
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties(SetObservable = true)
        Icon internal.matlab.editorconverters.datatype.FileName
        Separator matlab.lang.OnOffSwitchState
        
        Visible matlab.lang.OnOffSwitchState
        Enable matlab.lang.OnOffSwitchState
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        
        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end
    
    methods
        function obj = PushToolPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerNoPositionPropertyView(componentObject);
            
            % Sepecial Push Tool Group at the top of the inspector has
            % the 'Separator' property
            inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, ...
                'MATLAB:ui:propertygroups:PushToolGroup',...
                'Icon', 'Separator');
            
            %Common properties across all components
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
            
        end
    end
end