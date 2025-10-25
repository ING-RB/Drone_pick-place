classdef RogueContextMenuRemover < appdesigner.internal.serialization.save.interface.DecoratorComponentDataAdjuster
    %ROGUECONTEXTMENUREMOVER This class marks ContextMenus that have been
    % added by user-authored components with Serializable=off.
    % Any context menus without DesignTimeProperties will be so marked.
    %
    % Copyright 2021-2024 The MathWorks, Inc.

    methods
        function componentsStructure = adjustComponentDataPreSave(obj)
            componentsStructure = obj.DataAdjuster.adjustComponentDataPreSave();

            fig = componentsStructure.UIFigure;

            % Key off of DesignTimeProperties to remove the rogue context
            % menus.  If a context menu is not assigned to any components,
            % the only feature distinguishing a rogue context menu from an
            % interactively added context menu is the presence of
            % DesignTimeProperties.
            contextMenusToRemove = findall(fig, 'Type', 'uicontextmenu', '-and', '-not', '-property', 'DesignTimeProperties');

            % set will still work with an empty array
            set(contextMenusToRemove, Serializable='off');
        end

        function adjustComponentDataPostSave(obj, componentsStructure)
            % no-op - we do not want to mark any of these components as
            % serializable.
            obj.DataAdjuster.adjustComponentDataPostSave(componentsStructure);
        end
    end
end
