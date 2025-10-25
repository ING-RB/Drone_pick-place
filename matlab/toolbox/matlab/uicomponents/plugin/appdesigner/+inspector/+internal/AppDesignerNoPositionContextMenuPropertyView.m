classdef AppDesignerNoPositionContextMenuPropertyView < ...
        inspector.internal.AppDesignerNoPositionPropertyView & ...
        inspector.internal.mixin.ContextMenuMixin
    %

    % Copyright 2020 The MathWorks, Inc.

    methods

        function obj = AppDesignerNoPositionContextMenuPropertyView(componentObject)
            obj = obj@inspector.internal.AppDesignerNoPositionPropertyView(componentObject);
        end

    end
end
