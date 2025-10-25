function [x,y,width,height] = getInitialToolPosition(minSize, screenPercent, lockRatio)
%getInitialToolPosition return reasonable estimate of location
%
% borrowed from - imageslib.internal.apputil.ScreenUtilities.getInitialToolPosition();

%   Copyright 2020 The MathWorks, Inc.

% set units to pixels
origUnits = get(0,'Units');
set(0, 'Units', 'Pixels');
restoreGrootUnitsOnCleanUp = onCleanup(@()set(0, 'Units', origUnits));

monitorPositions = get(0,'MonitorPositions');
isDualMonitor = size(monitorPositions,1) > 1;

if isDualMonitor
    % pick the primary monitor.
    % MATLAB sets origin for the primary monitor at (1,1). use
    % this to find which index corresponds to the primary
    % monitor.
    origins = monitorPositions(:,1:2);
    primaryMonitorIndex = find(origins(:,1)==1 & origins(:,2)==1,1);
    
    if isempty(primaryMonitorIndex)
        % pick the first monitor if this doesn't work.
        primaryMonitorIndex = 1;
    else
        primaryMonitorIndex = max(primaryMonitorIndex,1);
    end
    
    sz = monitorPositions(primaryMonitorIndex, :);
else
    sz = get(0, 'ScreenSize');
end

% actual monitor size
szWidth  = sz(3);
szHeight = sz(4);

if nargin > 2 && lockRatio
    ratio = minSize(2) / minSize(1);
    if szHeight / szWidth > ratio
        szHeight = szWidth * ratio;
    elseif szHeight / szWidth < ratio
        szWidth = szHeight / ratio;
    end
end

% occupy 70% of the screen real estate or whatever is the
% min size defined above
width  = max(minSize(1), round(szWidth  * screenPercent));
height = max(minSize(2), round(szHeight * screenPercent));

% origin for the JAVA co-ordinate system are located at top
% left of the primary monitor
x = sz(1) + round(sz(3)/2) - round(width/2);
y = sz(2) + round(sz(4)/2) - round(height/2);

if nargout == 1
    x = [x y width height];
end

% [EOF]
