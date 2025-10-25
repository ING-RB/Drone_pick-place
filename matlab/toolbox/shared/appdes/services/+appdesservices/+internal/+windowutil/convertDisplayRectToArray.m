function position = convertDisplayRectToArray(displayRect)
    % convert pf.display.DisplayRect to 1 * 4 position array

    %    Copyright 2023 The MathWorks, Inc.
    
    position = [displayRect.x, displayRect.y, displayRect.width, displayRect.height];
end

