function activatewebwindow(modelhash)
    % Copyright 2024 The MathWorks, Inc.
    manager = connector.internal.webwindowmanager.instance;
    % find webwindow in windowList by url parsing...
    for win = manager.windowList
        if contains(win.URL, modelhash, 'IgnoreCase',true)
            win.bringToFront;
        end
    end
end