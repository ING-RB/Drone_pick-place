function freezeLayout(hObj, lockRotation)
% Freeze the layout so that hiding tick labels does not cause the layout to
% be recalculated. This is used during drag operations.

% Copyright 2018 The MathWorks, Inc.

% Cache layout related property values so they can be restored
% later.

% Freeze the responsive resize layout so font size and the colorbar gap are 
% not updated during doLayout()
hObj.ResponsiveResizeCache.Frozen = true;

hObj.CausesLayoutUpdate = false;

hAx = hObj.Axes;
layoutCache.PositionConstraint = hObj.PositionConstraint;
layoutCache.Position = get(hObj, layoutCache.PositionConstraint);
hObj.LayoutCache = layoutCache;

% Update the layout to prevent the axes from resizing or
% changing the layout during a drag operation.
hObj.XLabelHandle.PositionMode = 'manual';
hObj.YLabelHandle.PositionMode = 'manual';

if nargin < 2 || lockRotation
    hAx.XTickLabelRotationMode = 'manual';
    hAx.YTickLabelRotationMode = 'manual';
end

hObj.PositionConstraint = 'innerposition';

hObj.XLabelHandle.Units = 'points';
hObj.YLabelHandle.Units = 'points';

end
