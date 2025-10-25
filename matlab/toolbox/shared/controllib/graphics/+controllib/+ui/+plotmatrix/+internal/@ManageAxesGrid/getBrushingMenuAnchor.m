function BrushingMenuAnchor = getBrushingMenuAnchor(this)
%

%   Copyright 2015-2020 The MathWorks, Inc.

Fig = ancestor(this.AxesGrid.Parent,'figure');
hB = findobj(Fig,'-property','BrushingContextMenu');
if isempty(hB)
    Fig.addprop('BrushingContextMenu');
end
BrushingMenuAnchor = uicontextmenu('Parent',Fig);
Fig.BrushingContextMenu = BrushingMenuAnchor;
end
