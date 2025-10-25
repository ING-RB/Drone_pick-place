% This function gets the correct format for duration filtering.

% Copyright 2017-2023 The MathWorks, Inc.

function fmt = getCorrectFormatForDurationFiltering(userfmt)
    fmt = userfmt;
    if (~contains(userfmt, ":"))
        fmt = "hh:mm:ss";
    end
end
