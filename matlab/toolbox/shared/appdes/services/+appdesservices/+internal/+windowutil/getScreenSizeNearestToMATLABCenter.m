function screenSize = getScreenSizeNearestToMATLABCenter()
    %GETSCREENSIZENEARESTTOMATLABCENTER Get screen size which the point of 
    % the MATLAB center is contained by or nearest to.
    % Return   [x y width height] - left-upper based screen size

    %    Copyright 2017 - 2025 The MathWorks, Inc.
    matlabWindowCenterPoint = appdesservices.internal.windowutil.getMATLABWindowCenterPoint();
    matlabWindowScreenId = pf.display.getScreenIndexAt(matlabWindowCenterPoint);
    if matlabWindowScreenId < 0
        % getScreenIndexAt may return -1 if users have mutliple mornitors which 
        % have been configured to use different resolutions.
        % The root cause is JSD RootApp.WindowBounds returns a CEF-based
        % value, which is different from PF library's QT-based coordinate.
        % A geck -g3557398 has been created for pf team to consdier if it's possible
        % to provide an API to convert between screen coordinates.
        % so in such a case, use primary screen. See g3546745
        matlabWindowScreenId = pf.display.getPrimaryScreen();
    end
    screenConfig = pf.display.getConfig(matlabWindowScreenId);
    screenBounds = screenConfig.availableScreenSize;    

    % Return MATLAB style screen bounds
    screenSize = [screenBounds.x screenBounds.y screenBounds.width screenBounds.height];
end

