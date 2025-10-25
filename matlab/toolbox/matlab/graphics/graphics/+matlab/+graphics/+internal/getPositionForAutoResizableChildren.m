function pos = getPositionForAutoResizableChildren(obj, prop)
% This is an undocumented function and may be removed in a future release.

% Return the OuterPosition or InnerPosition from the specified axes in
% pixels. Take into account the AxesLayoutManager.

% Copyright 2018 The MathWorks, Inc.

units = obj.Units;
if strcmpi(prop, 'InnerPosition')
    % Read the InnerPosition so that an update is performed if necessary,
    % which could cause the AxesLayoutManager to update the position.
    pos = obj.InnerPosition;
elseif isprop(obj, 'LayoutManager') && isscalar(obj.LayoutManager) && isvalid(obj.LayoutManager)
    % Axes has a layout manager, which means that the reported outer
    % position may have been altered by the layout manager to accomodate
    % decorations.
    layoutManager = obj.LayoutManager;

    % Then the axes layout manager may be tracking the starting outer
    % position (before making room for the decorations), so ask the layout
    % manager for the outer position.
    [pos, units] = layoutManager.getOuterPositionForAutoResize();
else
    % No layout manager. Access the outer position directly from the axes.
    pos = obj.OuterPosition;
end

% Convert the units to pixels.
if ~strcmp(units, 'pixels')
    viewport = obj.Camera.Viewport;
    pos = matlab.graphics.internal.convertUnits(viewport, 'pixels', units, pos);
end
