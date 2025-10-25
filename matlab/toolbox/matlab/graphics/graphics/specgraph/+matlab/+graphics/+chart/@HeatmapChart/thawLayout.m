function thawLayout(hObj)
% Reverse the changes made by freezeLayout. This is used during drag
% operations.

% Copyright 2018 The MathWorks, Inc.

layoutCache = hObj.LayoutCache;
if isempty(layoutCache)
    return
end

% Restore the layout of the heatmap.
hAx = hObj.Axes;
hObj.XLabelHandle.Units = 'data';
hObj.YLabelHandle.Units = 'data';

hObj.CausesLayoutUpdate = true;

% Set OuterPosition or InnerPosition on the inner axes to avoid triggering
% a new auto-resize layout.
set(hObj.Axes, layoutCache.PositionConstraint, layoutCache.Position);

% Toggle the PositionConstraint back to the correct value. This will
% also mark the object as dirty, triggering an update.
hObj.PositionConstraint = layoutCache.PositionConstraint;

% Restore the label positions.
hAx.XTickLabelRotationMode = 'auto';
hAx.YTickLabelRotationMode = 'auto';
hObj.XLabelHandle.PositionMode = 'auto';
hObj.YLabelHandle.PositionMode = 'auto';

% Clear the layout cache.
hObj.LayoutCache = struct.empty();

% Unfreeze responsive resize layout so font size and colorbar gap can be 
% updated during doLayout()
hObj.ResponsiveResizeCache.Frozen = false;

end
