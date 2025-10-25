function updatedPosition = convertToScreenPosition(position, screenHeight)
    %CONVERTTOSCREENPOSITION Convert the MATLAB position, which is left-bottom
    % corner based, to a screen location, that is left-upper based.
    % position          [x y width height] - left-bottom based MATLAB position
    % screenHeight      
    % 
    % Return converted left-upper based position

    %    Copyright 2017 - 2024 The MathWorks, Inc.

    if nargin < 2
        % get the height of the primary screen
        mainScreen = pf.display.getConfig(0);
        screenHeight = mainScreen.screenSize.height;
    end

    % MATLAB position is [1 1] based
    updatedPosition = [position(1) - 1, screenHeight - position(2) - position(4) + 1, ...
        position(3), position(4)];
end

