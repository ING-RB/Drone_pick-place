function updatedPosition = ensurePositionOnScreen(position, screenBounds, margin)
    %ENSUREPOSITIONONSCREEN Make sure the position to put the window fully 
    % visible in the screen bounds:
    % - Change window size as necessary
    % - Move window towards the screen as necessary
    % position      [x y width height] - left-upper based screen location
    % screenBounds  [x y width height] - left-upper based screen bounds
    % margin        margin around the screen outside of which to keep
    %               the window. Default is 10
    %
    % Return updated position which is left-upper corner based screen
    % location

    %    Copyright 2017 - 2023 The MathWorks, Inc.
    
    if nargin == 2
        margin = 10;
    end
    
    % CEF Position doesn't account for title bar height as part of 
    % CEF window height itself
    % see g1518860 for more info about CEF
    % Use a maximum 95% of the screen height for the window height, and 5%
    % of screen height as the window top Y position at least to avoid
    % Window Title Bar to be clipped by the screen
    MAX_WINDOW_HEIGHT = int32(0.95 * screenBounds(4) - 2*margin);
    MIN_Y_VALUE = int32(screenBounds(2) + 0.05 *  screenBounds(4));    
    
    updatedPosition = position;
    % Resize the windows size if necessary
    if screenBounds(3) < position(3)
        % Adjust width to fit into the screen            
        updatedPosition(3) = screenBounds(3) - 2*margin;            
    end

    if MAX_WINDOW_HEIGHT < position(4)
        % Adjust height to fit into the screen
        updatedPosition(4) = MAX_WINDOW_HEIGHT;
    end

    % Ensure the entire window position in the dispaly area
    right = updatedPosition(1) + updatedPosition(3);
    screenRight = screenBounds(1) + screenBounds(3) - margin;
    if right > screenRight
        updatedPosition(1) = screenRight - updatedPosition(3);
    end
    if updatedPosition(1) < screenBounds(1) + margin
        updatedPosition(1) = screenBounds(1) + margin;
    end

    bottom = updatedPosition(2) + updatedPosition(4);
    screenBottom = screenBounds(2) + screenBounds(4) - margin;
    if bottom > screenBottom
        updatedPosition(2) = screenBottom - updatedPosition(4);
    end
    if updatedPosition(2) < screenBounds(2) + margin
        updatedPosition(2) = screenBounds(2) + margin;
    end            
      
    % Because the height from the passed in position doesn't include
    % Window's Title Bar height, need to check here if the y value is
    % large enough to show the title bar
    if updatedPosition(2) < MIN_Y_VALUE
        updatedPosition(2) = MIN_Y_VALUE;
    end
end

