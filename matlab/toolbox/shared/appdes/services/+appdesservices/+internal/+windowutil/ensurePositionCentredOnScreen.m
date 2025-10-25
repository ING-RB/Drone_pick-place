function updatedPosition = ensurePositionCentredOnScreen(position, screenBounds, margin)
    %ENSUREPOSITIONCENTREDONSCREEN % Make sure the position is in the middle of
    % the screen bounds if the screen bounds is large enough
    % Input arguments:
    % position      [x y width height] - left-upper based screen location
    % screenBounds  [x y width height] - left-upper based screen bounds
    % margin        margin around the screen outside of which to keep
    %               the window.Default is 10
    %
    % Return updated position which is left-upper corner based screen
    % location

    %    Copyright 2017 The MathWorks, Inc.

    if nargin == 2
        margin = 10;
    end    
    
    updatedPosition = position;

    % If screen width or height is big enough, try to put the
    % window to the middle
    if (screenBounds(3) - 2*margin) >= position(3)
        updatedPosition(1) = screenBounds(1) + (screenBounds(3) - position(3))/2;
    end

    if (screenBounds(4) - 2*margin) >= position(4)
        % Make the y a little bit higher 55%, recommended from
        % Windows Management GUIDELINE from MS
        updatedPosition(2) = screenBounds(2) + (screenBounds(4) - position(4))* 0.45;
    end
end