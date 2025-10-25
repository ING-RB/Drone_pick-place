function linkbtnoncallback(varargin)
%

%   Copyright 2007-2024 The MathWorks, Inc.

% When plots are linked from HG toolbar button or menus the callback
% strings execute in the base workspace. Consequently, these calls must be
% routed through the java LinkPlotPanel which will re-execute them from the
% current (possibly debug) workspace.

linkPMgr = datamanager.LinkplotManager.getInstance();

hFig = handle(gcbf);
if isempty(hFig) && nargin > 1 && ~isempty(varargin{2})
    hFig = varargin{2};
end
linkstate = linkdata(hFig);
if nargin>=1
    if strcmp(varargin{1},linkstate.Enable)
        return % Quick return for no-op changes
    else
        newstate = varargin{1};
    end
else % Toggle the linked state
    if strcmp(linkstate.Enable,'off')
        newstate = 'on';
    else
        newstate = 'off';
    end
end

% Disable toolbar button to prevent double clicks causing the state
% to get out of sync with the toolbar button
linkbtn = uigettool(hFig,'DataManager.Linking');

if strcmp(newstate,'on') || strcmp(newstate,'showdialog')
    if ~isempty(linkbtn)
        if ~isappdata(linkbtn,'cursorCacheData')
            setappdata(linkbtn,'cursorCacheData',get(hFig,'Pointer'));
            set(hFig,'Pointer','watch');
            drawnow expose
        end
        
        set(linkbtn,'Enable','off');
    end

    % Turn on linkdata without triggering the Linked Plot dialgo to open
    % (which would cause recursion)
    linkdata(hFig,'on', false);
   
    if isprop(hFig,'LinkedPlotApp')
        linkedDialog = get(hFig,'LinkedPlotApp');
        linkedDialog.bringToFront();
    else
        datamanager.LinkedPlotDialog(hFig);
    end
else
    % Make sure any pending link activations actions have processed
    % or the button could get out of sync with the figure state.
    drawnow
    linkdata(hFig,'off');
end