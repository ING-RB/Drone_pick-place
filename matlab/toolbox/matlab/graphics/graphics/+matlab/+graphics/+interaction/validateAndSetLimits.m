function validateAndSetLimits(ax, new_xlim, new_ylim, new_zlim)
%

%   Copyright 2015-2023 The MathWorks, Inc.

ThreeD = false;
if nargin == 4
    ThreeD = true;
end

% Make sure limits are valid (will throw out NaNs as well)
if any(ismissing(new_xlim)) || any(ismissing(new_ylim)) || (ThreeD && any(ismissing(new_zlim)))
    return
end

if isprop(ax,'ActiveXRuler')
    new_xlim = matlab.graphics.internal.lim2ruler(new_xlim, ax.ActiveXRuler);
    new_ylim = matlab.graphics.internal.lim2ruler(new_ylim, ax.ActiveYRuler);
    if ThreeD
        new_zlim = matlab.graphics.internal.lim2ruler(new_zlim, ax.ActiveZRuler);
    end
end

limitsChanged = ~isequal(new_xlim(:), ax.XLim(:)) || ~isequal(new_ylim(:), ax.YLim(:));

if ThreeD
    limitsChanged = limitsChanged || ~isequal(new_zlim(:), ax.ZLim(:));
end

if(limitsChanged)
    ax.XLim = sort(new_xlim);
    ax.YLim = sort(new_ylim);
    if ThreeD
        ax.ZLim = sort(new_zlim);
    end
    
    % Needed to stop motion events queuing
    matlab.graphics.internal.drawnow.limitrate(16); % 16 is time target in ms, corresponding to ~60FPS
end