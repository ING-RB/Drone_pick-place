function cef_window = findCshWindow(winIdName, winIdValue)
%


%   Copyright 2020-2021 The MathWorks, Inc.

    cef_window = [];
    windowId = [winIdName '=' winIdValue];
    windows = matlab.internal.webwindowmanager.instance();
    result = windows.findAllWebwindows;
    for i = 1:numel(result)
        if contains(result(i).CurrentURL, windowId)
            cef_window  = result(i);
            break;
        end
    end
end