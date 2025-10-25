function [out] = uigettool(fig,id)
% This function is undocumented and will change in a future release

% C = UIGETTOOL(H,'GroupName.ComponentName')
%     H is a vector of toolbar handles or a figure handle
%     'GroupName' is the name of the toolbar group
%     'ComponentName' is the name of the toolbar component
%     C is a toolbar component
%
% See also UITOOLFACTORY

%   Copyright 1984-2016 The MathWorks, Inc.

% Note: All code here must have fast performance
% since this function will be used in callbacks.
import matlab.internal.editor.figure.*;
if ~all(ishghandle(fig))
  error(message('MATLAB:uigettool:InvalidHandle'));
end
if length(fig) == 1 && ishghandle(fig,'figure')

  % check for live editor defaults and switch to standard defaults
  if ~matlab.internal.editor.figure.FigureUtils.isEditorSnapshotFigure(fig) && strcmp(get(fig,'ToolBar'),'none') && ...
          strcmp(get(fig,'MenuBar'),'none') && ...
          strcmp(get(fig,'MenuBarMode'),'auto') && ...
          strcmp(get(fig,'ToolBarMode'),'auto') && ...
          ~strcmp(get(fig,'DefaultTools'), 'toolstrip') && ...
          FigureUtils.isEditorEmbeddedFigure(fig)
      set(fig,'MenuBar','figure');
      set(fig,'ToolBar','auto');
  end
  
  fig = findobj(allchild(fig),'flat','Type','uitoolbar');
end


children = findall(fig);

out = matlab.ui.internal.findToolbarModeButtonsById(children,id);
