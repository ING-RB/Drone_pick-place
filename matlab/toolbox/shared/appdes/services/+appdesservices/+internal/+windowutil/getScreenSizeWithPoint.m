function screenSize = getScreenSizeWithPoint(point)
    %GETSCREENSIZEWITHPOINT Get the screen size which contains the point
    % point     [x y] - left-upper based location
    % Return    [x y width height]  - left-upper based screen size

    %    Copyright 2017 The MathWorks, Inc.
    
    screenSize = [];
    
    % The implementation is take from Java's implementation in
    % com.mathworks.mwswing.WindowUtils because it's private
    % Idealy, in the future CEF downstream teams could get some similar API
    % from CEF to ensure CEF window on screen easily 
    % without doing these annoying thing    
    graphicsEnvironment = com.mathworks.mwswing.SystemGraphicsEnvironment.getInstance();
    screenDevices = graphicsEnvironment.getScreenDevices();
    deviceNum = numel(screenDevices);
    
    javaPoint = java.awt.Point(point(1), point(2));
    
    for ix = 1:deviceNum
        device = screenDevices(ix);
        
        if device.getType() == java.awt.GraphicsDevice.TYPE_RASTER_SCREEN
            config = device.getDefaultConfiguration();
            if config.getBounds().contains(javaPoint)
                screenBounds = config.getBounds();
                
                screenSize = [screenBounds.x screenBounds.y screenBounds.width screenBounds.height];
                break;
            end
        end
    end
end

