function paste(es,ed) %#ok<INUSD>
%

% Copyright 2007-2020 The MathWorks, Inc.

% Paste the current selection to the command line

fig = ancestor(es,'figure');
gContainer = fig;
if ~isempty(es) && ~isempty(ancestor(es,'uicontextmenu'))
    gContainer = get(fig,'CurrentAxes');
    if isempty(gContainer)
        gContainer = fig;
    end  
end

if datamanager.isFigureLinked(fig)
    % If the figure is HandleInvisible, temporarily turn on ShowHiddenHandles
    isHandleInvisibleFigure = (fig.HandleVisibility=="off");
    if isHandleInvisibleFigure
        cachedShowHiddenHandles = get(groot,'ShowHiddenHandles');
        set(groot,'ShowHiddenHandles','on')
    end
    internal.matlab.datatoolsservices.executeCmd('datamanager.pasteContextMenuCallback');
    if isHandleInvisibleFigure && cachedShowHiddenHandles=="off"
        internal.matlab.datatoolsservices.executeCmd("set(groot,'ShowHiddenHandles','off')");
    end
else
     datamanager.pasteUnlinked(gContainer);
end
