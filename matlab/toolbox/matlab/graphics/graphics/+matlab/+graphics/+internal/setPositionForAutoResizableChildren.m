function setPositionForAutoResizableChildren(obj, prop, pos, frameDimensions)
% This is an undocumented function and may be removed in a future release.

% Set the OuterPosition or InnerPosition on the specified axes in pixels.

% Copyright 2018 The MathWorks, Inc.

if strcmpi(obj.Units, 'pixels')
    set(obj, prop, pos);
else
    % Convert the reference frame to devicepixels. This conversion only
    % depends on the DPI, it does not depend on the existing reference
    % frame.
    import matlab.graphics.internal.convertUnits
    viewport = obj.Camera.Viewport;
    frameDimensions = convertUnits(viewport, 'devicepixels', 'pixels', [1 1 frameDimensions(:)']);
    viewport.RefFrame = frameDimensions;
    
    % Convert the position from pixels into the axes units.
    pos = convertUnits(viewport, obj.Units, 'pixels', pos);
    
    % Set the position.
    set(obj, prop, pos);
end

end
