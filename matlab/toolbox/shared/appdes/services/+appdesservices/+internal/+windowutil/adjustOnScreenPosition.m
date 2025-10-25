function adjustedPos = adjustOnScreenPosition(screenPos, screenBounds, margin)
    %ADJUSTONSCREENPOSITION Use a maximum of 95% of the screen height for
    % the window height, and 5% of screen height as the window top Y
    % position at least to avoid Window Title Bar to be clipped by the
    % screen. CEF Position doesn't account for title bar height as part of 
    % CEF window height itself.
    % see g1518860 for more info about CEF.
    % 
    % screenPos         [x y width height] top-right based screen position
    %                   (must be top-right due to g3227502)
    % screenBounds      pf.display.DisplayRect object
    % margin            margin around the screen outside of which to keep
    %                   the window. Default is 10
    % 
    % Return adjusted display position.

    %    Copyright 2024 The MathWorks, Inc.

    MAX_WINDOW_HEIGHT = int32(0.95 * screenBounds.height - 2*margin);
    MIN_Y_VALUE = int32(screenBounds.y + 0.05 * screenBounds.height);
    if MAX_WINDOW_HEIGHT < screenPos(4)
        % Adjust height to fit into the screen
        screenPos(4) = MAX_WINDOW_HEIGHT;
    end
    % Because the height from the passed in position doesn't include
    % Window's Title Bar height, need to check here if the y value is
    % large enough to show the title bar
    if screenPos(2) < MIN_Y_VALUE
        screenPos(2) = MIN_Y_VALUE;
    end

    adjustedPos = screenPos;
end

