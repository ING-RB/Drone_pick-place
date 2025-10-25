function fitInAnyScreen = isPositionWithinAnyScreen(position)
    % Check if a giving position is within any screen, including virtual screen

    %    Copyright 2023 The MathWorks, Inc.
    
    fitInAnyScreen = false;
            
    screenNumbers = pf.display.getNumScreens();
    for ix = 0 : (screenNumbers - 1)
        screenConfig = pf.display.getConfig(ix);
        % As g3042555 mentioned, pf.display.getConfig().availableScreenSize
        % would not take 'display scale' setting into account, as a result,
        % the returned value would not be accurate because last saved
        % position from CEF's API is scaling based.
        screenBounds = screenConfig.availableScreenSize;
        screenPosition = appdesservices.internal.windowutil.convertToScreenPosition(position, screenBounds.height);


        if appdesservices.internal.windowutil.isPositionWithinBounds(screenPosition, [screenBounds.x screenBounds.y screenBounds.width screenBounds.height])
            fitInAnyScreen = true;
            return;
        end
    end

    % Now check if it could fit into virtual screen bounds
    virtualscreenBounds = pf.display.getAvailableVirtualGeometry();
    screenPosition = appdesservices.internal.windowutil.convertToScreenPosition(position, virtualscreenBounds.height);
    if appdesservices.internal.windowutil.isPositionWithinBounds(screenPosition, [virtualscreenBounds.x virtualscreenBounds.y virtualscreenBounds.width virtualscreenBounds.height])
        fitInAnyScreen = true;
    end
end

