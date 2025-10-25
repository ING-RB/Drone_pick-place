classdef (Abstract) ContextMenuMixin < handle
    % matlab.hwmgr.internal.ContextMenuMixin - mixin class providing client
    % apps an API which will enable them to have Context Menus to UI elements.

    % Copyright 2022 Mathworks Inc.

    properties (Abstract)
        RootWindow
    end

    methods
        function cm = createContextMenu(obj)
            % RootWindow is a UI Panel which is inside a GridLayout, which
            % itself is inside of a Figure. This Figure (RootWindow.Parent.Parent) 
            % is passed as an input to the uicontextmenu() function, which 
            % expects a UI figure as an argurment.
            fig = obj.RootWindow.Parent.Parent;
            cm = uicontextmenu(fig);
        end
    end
end

