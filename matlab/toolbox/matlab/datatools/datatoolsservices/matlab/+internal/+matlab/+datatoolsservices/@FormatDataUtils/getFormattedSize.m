% If length of size is > 4, this is an n-D array, return the formatted size
% accordingly. For other sizes, construct the dimension string using the size
% and times symbol.

% Copyright 2015-2023 The MathWorks, Inc.

function formattedSize = getFormattedSize(s, truncateDimensions)
    arguments
        s double
        truncateDimensions (1,1) logical = true
    end
    import internal.matlab.datatoolsservices.FormatDataUtils;
    if truncateDimensions && length(s) > FormatDataUtils.NUM_DIMENSIONS_TO_SHOW
        formattedSize = sprintf('%d-D',length(s));
    else
        sStr = string(s);
        sStr(ismissing(sStr)) = "NaN";
        formattedSize = char(join(sStr, FormatDataUtils.TIMES_SYMBOL));
    end
end
