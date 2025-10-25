function gridContainer = editGrid(this,parent,rowIdx,columnIdx)
% editGrid - Build container for editing grid and add to tab.

% Copyright 1986-2021 The MathWorks, Inc.

if isempty(this.GridContainer)
    gridContainer = controllib.widget.internal.cstprefs.GridContainer;
    
    this.GridContainer = gridContainer;
else
    gridContainer = this.GridContainer;
end
widget = getWidget(gridContainer);
widget.Parent = parent;
widget.Layout.Row = rowIdx;
widget.Layout.Column = columnIdx;
widget.Tag = 'Grid';

% Listeners to update data
L = addlistener(gridContainer,'Value','PostSet',...
    @(es,ed) localUpdateData(this,ed));
registerDataListeners(gridContainer,L,'UpdateData');

% Listener to update UI
props = findprop(this,'Grid');
L = handle.listener(this,props,'PropertyPostSet',{@localUpdateUI gridContainer});
registerUIListeners(gridContainer,L,'UpdateUI');

end

function localUpdateData(this,ed)
this.Grid = ed.AffectedObject.Value;
end

function localUpdateUI(~,ed,gridContainer)
gridContainer.Value = ed.AffectedObject.Grid;
end

