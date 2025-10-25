classdef ContextMenuPropertyView < ...
        inspector.internal.AppDesignerNoPositionPropertyView
    % This class provides the property definition and groupings for Context
    % Menu component
    
    % Copyright 2020 The MathWorks, Inc.
    
    methods
        function obj = ContextMenuPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerNoPositionPropertyView(componentObject);
            
            %Common properties across all components
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj);
        end
    end
end

