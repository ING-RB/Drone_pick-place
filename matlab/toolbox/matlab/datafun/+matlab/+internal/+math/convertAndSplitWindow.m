function [window, inclusiveUpperBound] = convertAndSplitWindow(window,sp)
%convertAndSplitWindow Convert window sizes to correct type and split
%singleton scalar window sizes window sizes into 2-element vectors
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

%   Copyright 2023 The MathWorks, Inc.

if isnumeric(window)
    window = cast(window,'like',sp);
else % window must be a duration
    window = milliseconds(window);
end
if isscalar(window)
    if isinteger(window)
        if mod(window,2) == 0
            window = [window/2 window/2];
            inclusiveUpperBound = false;
        else
            window = [(window - 1)/2, (window - 1)/2];
            inclusiveUpperBound = true;
        end
    else
        window = [window/2, window/2];
        inclusiveUpperBound = false;
    end
else
    inclusiveUpperBound = true;
end
end