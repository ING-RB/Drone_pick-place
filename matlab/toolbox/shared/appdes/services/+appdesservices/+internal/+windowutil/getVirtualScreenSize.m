function screenSize = getVirtualScreenSize()
    %GETVIRTUALSCREENSIZE Get virtual screen size    
    % Return   [x y width height] - left-upper corner based screen size

    %    Copyright 2017 - 2018 The MathWorks, Inc.

    
    % The implementation is take from Java's implementation in
    % com.mathworks.mwswing.WindowUtils because it's private
    % Idealy, in the future CEF downstream teams could get some similar API
    % from CEF to ensure CEF window on screen easily 
    % without doing these annoying thing
    graphicsEnvironment = com.mathworks.mwswing.SystemGraphicsEnvironment.getInstance();
    screenDevices = graphicsEnvironment.getScreenDevices();
        
    if ~appdesservices.internal.windowutil.isVirtualScreenEnabled()
        % Return the screen size of the primary monitor
        screenDevice = graphicsEnvironment.getDefaultScreenDevice();
        config = screenDevice.getDefaultConfiguration();
        if ~isempty(config)
            screenSize = config.getBounds();
        else
            size = graphicsEnvironment.getScreenSize();
            screenSize = java.awt.Rectangle(0, 0, size.width, size.height);
        end
    else
        screenSize = java.awt.Rectangle(0, 0, 0, 0);
        
        for ix = 1:numel(screenDevices)
            configurations = screenDevices(ix).getConfigurations();
            
            for j = 1:numel(configurations)
                screenSize = screenSize.union(configurations(j).getBounds());
            end
        end
    end
    
    % Return MATLAB style screen bounds
    screenSize = [screenSize.x screenSize.y screenSize.width screenSize.height];
end

