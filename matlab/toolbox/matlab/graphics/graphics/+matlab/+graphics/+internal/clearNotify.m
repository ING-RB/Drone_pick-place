function clearNotify(h, ax, flag)
%clearNotify Perform actions when a figure has some content cleared

%   Copyright 2014-2020 The MathWorks, Inc.

% Sometimes clearNotify is called with just an axes handle as the first 
% (and only) input argument. In that case, check if the axes is in a chart before proceeding.
if nargin == 1
    ax = h;
end
axHandle = handle(ax);
if ~isempty(axHandle) && ~isempty(ancestor(axHandle.NodeParent,'matlab.graphics.chart.Chart','node'))
    return;
end

fig = [];
for k=1:length(h)
    obj = h(k);
    if isgraphics(obj) 
        f = ancestor(obj,'figure');
        if ~isempty(f)
            fig = f;
            break;
        end
    end
end

 
if matlab.internal.editor.figure.FigureUtils.isEditorSnapshotFigure(fig)
    return
end

% If this is a live script figure then capture any info before 
% the figure is cleared.
if ~isempty(fig) && isprop(fig, 'EDITOR_APPDATA')
    if nargin < 3
        flag = '';
    end
    v = get(fig,'EDITOR_APPDATA');
    if ischar(v) && strcmp(v,'unittest') % unit testing API for when clearNotify is called.
        set(fig,'EDITOR_APPDATA',flag);
    else
        matlab.internal.editor.FigureManager.figureBeingCleared(fig, flag);
    end
end
