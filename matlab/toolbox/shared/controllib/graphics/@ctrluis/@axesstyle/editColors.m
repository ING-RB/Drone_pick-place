function colorContainer = editColors(this,parent,rowIdx,columnIdx)
% editColors - Build container for changing axes color and add to tab

%   Copyright 1986-2020 The MathWorks, Inc. 

if isempty(this.ColorContainer)
    colorContainer = controllib.widget.internal.cstprefs.ColorContainer;
    this.ColorContainer = colorContainer;
else
    colorContainer = this.ColorContainer;
end
widget = getWidget(colorContainer);
widget.Parent = parent;
widget.Layout.Row = rowIdx;
widget.Layout.Column = columnIdx;
widget.Tag = 'Color';

% Listeners to update data
L = addlistener(colorContainer,'Value','PostSet',...
    @(es,ed) localUpdateData(this,ed));
registerDataListeners(colorContainer,L,'UpdateData');

% Listener to update UI
props = findprop(this,'XColor');
L = handle.listener(this,props,'PropertyPostSet',{@localUpdateUI colorContainer});
registerUIListeners(colorContainer,L,'UpdateUI');

end

function localUpdateData(this,ed)
disableUIListeners(ed.AffectedObject);
this.XColor = ed.AffectedObject.Value;
this.YColor = ed.AffectedObject.Value;
enableUIListeners(ed.AffectedObject);
end

function localUpdateUI(~,ed,colorContainer)
colorContainer.Value = ed.AffectedObject.XColor;
end