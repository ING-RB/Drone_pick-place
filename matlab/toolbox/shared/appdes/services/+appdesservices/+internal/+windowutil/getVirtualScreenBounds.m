function screenBounds = getVirtualScreenBounds()
    %GETVIRTUALSCREENBOUNDS Get virtual screen bounds    
    % Return   [x y width height] - left-upper corner based screen size

    %    Copyright 2018 The MathWorks, Inc.

    if appdesservices.internal.windowutil.isVirtualScreenEnabled()
        screenBounds = com.mathworks.mwswing.WindowUtils.getVirtualScreenBounds();                
    else
        screenBounds = com.mathworks.mwswing.WindowUtils.getScreenBounds(); 
    end
    
    % Conver java.awt.Rectangel to MATLAB style
    screenBounds = [screenBounds.x screenBounds.y screenBounds.width screenBounds.height];
end

