classdef TreeNodePropertyView < inspector.internal.AppDesignerNoPositionContextMenuPropertyView & ...
        inspector.internal.mixin.IconMixin
    % This class provides the property definition and groupings for
    % TreeNode

    % Copyright 2017-2020 The MathWorks, Inc.

    properties(SetObservable = true)
        Text char {matlab.internal.validation.mustBeVector(Text)}
        NodeData

        Tag char {matlab.internal.validation.mustBeVector(Tag)}
    end

    methods
        function obj = TreeNodePropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerNoPositionContextMenuPropertyView(componentObject);
            %Common properties across all components
            inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:TreeNodeGroup',...
                'Text', ...
                'NodeData', ...
                'Icon'...
            );
            inspector.internal.CommonPropertyView.createCommonPropertyInspectorGroup(obj, false);
        end
    end
end
