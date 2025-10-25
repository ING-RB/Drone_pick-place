function figPos = fixFigurePosition(figPos)
%fixFigurePosition Fix the figure position to fit inside at least 1 monitor

%   Copyright 2010-2023 The MathWorks, Inc.

persistent monitors
if isempty(monitors)
    origUnits = get(0, 'Units');
    set(0, 'Units', 'Pixels');
    monitors = get(0, 'MonitorPositions'); % [left bottom width height] in pixels
    set(0, 'Units', origUnits);   % restore the resolution settings
end

% Check that the scope fits into one of the monitors.
% 1) The right edge of the figure is beyond the left edge of the screen
% 2) The left edge of the figure is before the right edge of the screen
% 3) The top of the figure is above the bottom of the screen & not above
% the top so that it is still clickable.
% 4) The bottom of the figure is below the top of the screen
menuToolbarBuffer = 55;
fits = [
    figPos(1) + figPos(3) > monitors(:, 1) ...
    figPos(1) < monitors(:, 3)+monitors(:, 1) ...
    figPos(2) + figPos(4)+menuToolbarBuffer > monitors(:, 2) & figPos(2) + figPos(4)+menuToolbarBuffer < monitors(:, 2)+monitors(:,4) ...
    figPos(2) < monitors(:, 4)+monitors(:, 2)];

% Check to make sure that all dimensions (all) are true for at least 1
% monitor (any).
fits = any(all(fits, 2));

% If the window doesn't on any monitor, place it in the middle of the
% "main" monitor.
if ~fits
    figPos(1) = monitors(1,1) + floor((monitors(1,3)-monitors(1,1)-figPos(3))/2);
    figPos(2) = monitors(1,2) + floor((monitors(1,4)-monitors(1,2)-figPos(4))/2);
end

% [EOF]
