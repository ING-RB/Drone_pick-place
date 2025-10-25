function [hObjs, hMode] = getMenuTargetObjects(hFig, obj)

% Helper function used by scribe menus to find which graphics objects are
% affected by a menu action

hMode = [];
% In the callbacks for the individual UIMenu entries, obtain the object handle
% rather than calling hittest. If the state data is non-existent, default to hittest as a safeguard.
hMenu = ancestor(obj,'UIContextMenu');
definedMenuCallback = ~isempty(hMenu) && ishandle(hMenu) && isappdata(hMenu,'CallbackObject');
if ~isempty(hMenu) && ishandle(hMenu) && isappdata(hMenu,'CallbackObject')
    hObjs = getappdata(hMenu,'CallbackObject');
    hDefinedMenuCallbackTargetClass = class(hObjs);
else
    hObjs = hittest(hFig);
end

% Use plot edit mode to get the selected objects if it is active to support
% multi-select and test situations. 
% If hObjs is contained in a uicontainer, then the selected objects in plot
% edit mode will not match hObjs and should not be used since they may not
% match match the intended target of the menu (g2986037)
if isactiveuimode(hFig,'Standard.EditPlot') || isappdata(hFig,'scribeActive')
    isWebGraphics = matlab.ui.internal.isUIFigure(hFig);
    if ~isWebGraphics || isempty(ancestor(hObjs,{'uipanel','uitab','uicontainer'}))
        % Get a handle to the mode. Though this creates an interdependency, it is
        % mitigated by the guarantee that this callback is only executed while the
        % mode is active, and thus already created.
        hPlotEdit = plotedit(hFig,'getmode');
        hMode = hPlotEdit.ModeStateData.PlotSelectMode;
        if definedMenuCallback
            % If the menu has a CallbackObject the target objects must have
            % a matching class or the callback may not work. For example,
            % if the menu is the Legend positioning menu item it will only
            % work for legends. In this case, hObjs should comprise all the
            % selected objects of the matching type. This allows the menu
            % to act on multiple selected objects of the the right types
            plotEditSelectionOfExpectedClass = findobj(hMode.ModeStateData.SelectedObjects,'flat','-isa',hDefinedMenuCallbackTargetClass);
            
            % hObj must include the menu CallbackObject even if it not
            % selected in plot edit mode. This ensures that the menu will
            % act on something if it it raised onan object like legend
            % where this menu is expected to work even if the legend is not
            % explicitly selected
            hObjs = union(plotEditSelectionOfExpectedClass,hObjs);
        else
            hObjs = hMode.ModeStateData.SelectedObjects;
        end
    end
end