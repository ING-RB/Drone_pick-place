function closeAllWebWindows()
webWindowManager = matlab.internal.webwindowmanager.instance;
webWindowList    = webWindowManager.windowList;

% Work through the list of these open app windows and close them
for i = 1:length(webWindowList)
    % Wrap in try catch so that we at least attempt to close all windows.
    try
        if isa(webWindowList(i), 'matlab.internal.webwindow')
            webWindowList(i).close;
        end
    catch
    end
end
end
