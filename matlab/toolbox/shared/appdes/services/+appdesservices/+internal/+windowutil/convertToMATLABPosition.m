function updatedPosition = convertToMATLABPosition(position, screenHeight)
    %CONVERTTOSCREENPOSITION Convert the screen based position, which is 
    % left-upper corner based, to a MATLAB location, that is left-bottom based.
    % position          [x y width height] - left-upper based screen position    
    % screenHeight
    % 
    % Return converted left-bottom based MATLAB position

    %    Copyright 2017 - 2024 The MathWorks, Inc.

    if nargin < 2
        % get the height of the primary screen
        mainScreen = pf.display.getConfig(0);
        screenHeight = mainScreen.screenSize.height;
    end

    % MATLAB position is [1 1] based
    updatedPosition = [position(1) + 1, screenHeight - position(2)- position(4) + 1, ...
        position(3), position(4)];
end

