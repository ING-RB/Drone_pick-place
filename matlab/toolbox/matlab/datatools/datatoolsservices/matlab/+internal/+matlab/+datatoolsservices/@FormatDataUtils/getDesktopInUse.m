% Returns whether the desktop is in use, suitable for use in the background pool

% Copyright 2015-2023 The MathWorks, Inc.

function b = getDesktopInUse()
    persistent desktopInUse;

    if isempty(desktopInUse)
        try
            desktopInUse = matlab.internal.display.isDesktopInUse;
        catch
            % The isDesktopInUse call is not supported on the backgroundPool, so
            % assume false.
            desktopInUse = false;
        end
    end

    b = desktopInUse;
end
