% Calls isstring, but handles custom implementations

% Copyright 2015-2023 The MathWorks, Inc.

function s = checkIsString(var)
    % Guard against objects which have their own isstring methods
    try
        s = isstring(var);
        if ~islogical(s) || isempty(s)
            s = false;
        end
    catch
        s = false;
    end
end
