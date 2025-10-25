function Anchor = getMenuAnchor(this)
%

%   Copyright 2015-2020 The MathWorks, Inc.

Anchor = this.AxesGrid.UIContextMenu;
if strcmpi(this.DiagonalAxesSharing,'XOnly')
    HistAx = getHistogramAxes(this);
    set(HistAx, 'UIContextMenu', Anchor);
end
end
