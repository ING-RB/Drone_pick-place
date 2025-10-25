function windowRect = convertArrayToDisplayRect(position)
    % conver 1 * 4 position array to pf.display.DisplayRect object

    %    Copyright 2023 The MathWorks, Inc.
    
    windowRect = pf.display.DisplayRect;
    windowRect.x = position(1);
    windowRect.y = position(2);
    windowRect.width = position(3);
    windowRect.height = position(4);
end

