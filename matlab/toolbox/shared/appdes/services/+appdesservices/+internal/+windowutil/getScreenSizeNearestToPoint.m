function screenSize = getScreenSizeNearestToPoint(point)
    %GETSCREENSIZENEARESTTOPOINT Get the screen size which is 
    % nearest to point
    % point     [x y] - left-upper based location
    % Return    [x y width height] - left-upper based screen size

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
    maxDistance = java.lang.Integer.MAX_VALUE;
     
    for ix = 1:deviceNum
        device = screenDevices(ix);
        
        if device.getType() == java.awt.GraphicsDevice.TYPE_RASTER_SCREEN
            config = device.getDefaultConfiguration();
            distance = 0;
            x = point.x;
            y = point.y;
            bounds = config.getBounds();
            
            if (x < bounds.x)
                distance = bounds.x - x;
            elseif (x > bounds.x + bounds.width)
                distance = x - (bounds.x + bounds.width);
            end
            
            if (y < bounds.y)
                distance = distance + bounds.y - y;
            elseif (y > bounds.y + bounds.height)
                distance = distance + y - (bounds.y + bounds.height);
            end
            
            if (distance < maxDistance)
                graphicsConfiguration = config;
                maxDistance = distance;
            end
        end
    end
    
    if ~isempty(graphicsConfiguration)
        screenBounds = graphicsConfiguration.getBounds();
        screenSize = [screenBounds.x screenBounds.y screenBounds.width screenBounds.height];
    end
end

