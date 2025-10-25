function setBrushingInteractionHint(h, dataLinkState)
%   This function is undocumented and will change in a future release

% Copyright 2023 The MathWorks, Inc.

% Sets the DataBrushing hint and if there is a brushing behavior object
% also refreshes the Axes Toolbar enabling the state of the brusing button
% to be updated (g2934985)
hintState = getInteractionHint(h,'DataBrushing');
setInteractionHint(h, 'DataBrushing', dataLinkState);
if ~strcmp(hintState,'on')    
       brushBehavior = hggetbehavior(h,'brush');
       if ~isempty(brushBehavior) && brushBehavior.Enable
           ax = ancestor(h,'axes');
           % Reset the toolbar when adding a DataBrushing hint when there is a
           % brushing behavior object since the Brush button will not be updated by
           % ToolbarController on mouse hover
           if ~isempty(ax) && isprop(ax,'ToolbarMode') && strcmp(ax.ToolbarMode,'auto')
               ax.Toolbar_I = [];
           end
       end
end