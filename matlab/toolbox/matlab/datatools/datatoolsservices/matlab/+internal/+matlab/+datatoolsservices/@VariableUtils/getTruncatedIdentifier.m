% Returns a truncated identifier (variable name or field name), which is at most
% MAX_STR_LENGTH_FOR_MESSAGE characters.

% Copyright 2024 The MathWorks, Inc.

function truncID = getTruncatedIdentifier(id, maxCharsToShow)
    arguments
        id char % so we can easily do character indexing
        maxCharsToShow = internal.matlab.datatoolsservices.VariableUtils.MAX_STR_LENGTH_FOR_MESSAGE;
    end

    len = strlength(id);
    if len > (maxCharsToShow + 3)
        truncID = id(1:floor(maxCharsToShow/2)) + "..." + id(len-floor(maxCharsToShow/2)+1:end);
    else
        truncID = string(id);
    end
end
