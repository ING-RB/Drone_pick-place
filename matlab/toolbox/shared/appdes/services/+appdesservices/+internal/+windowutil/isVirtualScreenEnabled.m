function enableVirtualScreen = isVirtualScreenEnabled()
    %ISVIRTUALSCREENENABLED Check if virtual screen is enabled or not

    %    Copyright 2018 The MathWorks, Inc.

    enableVirtualScreen = true;
    
    graphicsEnvironment = com.mathworks.mwswing.SystemGraphicsEnvironment.getInstance();
    
    screenDevices = graphicsEnvironment.getScreenDevices();
    disableVirtualScreen = java.lang.System.getProperty("matlab.desktop.disableVirtualScreenBounds");
    
    if (~isempty(disableVirtualScreen) && strcmpi('true', disableVirtualScreen)) || ...
            numel(screenDevices) == 1
        enableVirtualScreen = false;
    else
        lastScreenHeight = Inf;
        
        for ix = 1:numel(screenDevices)
            configurations = screenDevices(ix).getConfigurations();
            
            for j = 1:numel(configurations)
                screenBound = configurations(j).getBounds();
                if isinf(lastScreenHeight)
                    lastScreenHeight = screenBound.height;
                else
                    if lastScreenHeight ~= screenBound.height
                        % Not all screens have the same height, and do not
                        % use virtual screen, otherwise application window
                        % would be shown off-screen
                        enableVirtualScreen = false;
                        return;
                    end
                end
                
            end
        end
    end
end

